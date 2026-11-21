#!/bin/sh
# az-renames.sh - move a server to the names of the packages of az of 21.11.2026: the
# version first, as php84 and php84-gd (phpXY-apache, phpXY-fpm, phpXY-cgi, node24-npm,
# ruby34 ...), and the FPM and the CGI of PHP packages of their own (phpXY-fpm with the
# rc.d script phpXY_fpm, phpXY-cgi), out of the core phpXY.
#
# Usage (as root, FreeBSD, the repository az configured):
#   sh az-renames.sh            what it would do; nothing is changed
#   sh az-renames.sh --apply    do it
#
# What it does, in this order:
#   1. pkg update -r az, in both modes (it changes no package);
#   2. the packages of the repository az installed under an old name: the new name
#      for each (a package of another repository under an old name is left alone:
#      the official ruby is not ours);
#   3. PHP XY of az with the FPM or the CGI in its core (sbin/php-fpmXY, bin/php-cgiXY,
#      etc/rc.d/php_fpmXY): phpXY-fpm when rc.conf enables php_fpmXY (or profiles of it),
#      it runs or a file names sbin/php-fpmXY; phpXY-cgi when php-cgiXY runs or a file
#      names it: a file of /etc or /usr/local/etc (spawn-fcgi, the FastCGI of Apache), a
#      crontab, or a wrapper of a site with it on its #! line (the php-bin/php of
#      suexec), a small file at most 4 levels under /var/www, /home or /usr/local/www;
#      the php-fpm of the old rc.d script php_fpmXY stopped when it runs (with its
#      profiles), started again as phpXY_fpm;
#   4. pkg upgrade -r az (the core of PHP without its FPM and CGI), then pkg install -r
#      az of the new names (pkg takes the packages of the old names away: the same
#      files); pkg asks before each;
#   5. in the files of 3, php-cgiXY becomes phpXY-cgi and sbin/php-fpmXY sbin/phpXY-fpm
#      (sed, each file said);
#   6. the variables php_fpmXY_* of rc.conf (sysrc) as phpXY_fpm_* (enable, profiles,
#      the profiles' enable and flags, umask ...); a file /etc/rc.conf.d/php_fpmXY or
#      /usr/local/etc/rc.conf.d/php_fpmXY is said, not changed;
#   7. phpXY_fpm started where php_fpmXY ran.
# The configuration files are kept as they are: php-fpm.conf of before keeps its pid,
# log and socket (/var/run/php-fpmXY.pid, /var/log/php-fpmXY.log,
# /var/run/php-fpmXY.sock), which the rc.d script phpXY_fpm takes from it; the web
# servers need no change. Apache with a module of PHP or an Apache module renamed, and
# nginx with Passenger: restart them yourself (said at the end).
#
# Exit status: 0 done (or nothing to do), 1 a step failed, 2 usage.

set -u
apply=0
case "${1:-}" in
"") ;;
--apply) apply=1 ;;
*) echo "usage: sh $0 [--apply]" >&2; exit 2 ;;
esac
[ "$(id -u)" = 0 ] || { echo "$0: run it as root" >&2; exit 2; }
command -v pkg > /dev/null 2>&1 || { echo "$0: no pkg" >&2; exit 2; }
P=/usr/local

say() { printf '%s\n' "$*"; }
run() {
    say "# $*"
    [ "$apply" = 1 ] || return 0
    "$@"
}
# the repository a package came from (its annotation repository)
repo_of() { pkg query '%At %Av' "$1" 2> /dev/null | awk '$1 == "repository" { print $2; exit }'; }
# the files that name $1 (php-cgiXY or sbin/php-fpmXY), a line each: those of /etc and
# /usr/local/etc (not the rc.d scripts, which go with their packages) and the crontabs;
# for php-cgiXY also the wrappers of sites, a small file with it on a #! line
refs_of() {
    grep -rlsF "$1" /etc "$P/etc" /var/cron/tabs 2> /dev/null | grep -v "^$P/etc/rc\.d/"
    case "$1" in
    php-cgi*)
        for d in /var/www /home "$P/www"; do
            [ -d "$d" ] || continue
            find "$d" -maxdepth 4 -type f -size -4k -exec grep -lsE "^#!.*$1([^0-9]|\$)" {} + 2> /dev/null
        done
        ;;
    esac
}
tab="$(printf '\t')"
edits="$(mktemp "${TMPDIR:-/tmp}/az-renames.XXXXXXXX")" || { echo "$0: mktemp failed" >&2; exit 1; }
trap 'rm -f "$edits"' EXIT

# the old name and the new one
map="mod_php56:php56-apache mod_php74:php74-apache mod_php81:php81-apache mod_php82:php82-apache
mod_php83:php83-apache mod_php84:php84-apache ap24-mod_fastcgi:apache24-mod_fastcgi
ap24-mod_maxminddb:apache24-mod_maxminddb npm-node18:node18-npm yarn-node18:node18-yarn
corepack-node18:node18-corepack npm-node24:node24-npm yarn-node24:node24-yarn
corepack-node24:node24-corepack phpMyAdmin-php56:php56-phpmyadmin
phpMyAdmin5-php74:php74-phpmyadmin phpMyAdmin5-php81:php81-phpmyadmin
phpMyAdmin5-php82:php82-phpmyadmin phpMyAdmin5-php83:php83-phpmyadmin
phpMyAdmin5-php84:php84-phpmyadmin mtr-nox11:mtr ruby:ruby34 rubygem-etc:ruby34-etc
rubygem-logger:ruby34-logger rubygem-rack:ruby34-rack rubygem-rackup:ruby34-rackup
rubygem-rake:ruby34-rake rubygem-bundler:ruby34-bundler
rubygem-passenger-nginx:ruby34-passenger-nginx virtualbox-ose-nox11-72:virtualbox72
virtualbox-ose-kmod-72:virtualbox72-kmod virtualbox-ose-additions-nox11-72:virtualbox72-additions"

say "== 1. the catalog of the repository az (pkg update changes no package)"
pkg update -q -r az || { say "pkg update -r az failed: is the repository az configured?"; exit 1; }

say "== 2. the packages of az under an old name"
want=""
apache=0; nginx=0
for m in $map; do
    o="${m%%:*}"; n="${m#*:}"
    pkg info -e "$o" || continue
    r="$(repo_of "$o")"
    if [ "$r" != az ]; then
        say "$o: from the repository ${r:-unknown (pkg add of a file)}, not az: left alone"
        continue
    fi
    say "$o -> $n"
    want="$want $n"
    case "$o" in mod_php*|ap24-*) apache=1 ;; rubygem-passenger-nginx) nginx=1 ;; esac
done

say "== 3. the FPM and the CGI of PHP"
fpm_was=""
fpm_new=""
for v in 56 74 81 82 83 84; do
    pkg info -e "php$v" || continue
    r="$(repo_of "php$v")"
    [ "$r" = az ] || { say "php$v: from the repository ${r:-unknown}, not az: left alone"; continue; }
    # the FPM: phpXY-fpm when rc.conf enables php_fpmXY (or a profile of it), it runs or
    # a file names sbin/php-fpmXY
    # (rc.conf alone: a run cut short after pkg upgrade, the core without its FPM)
    if [ -e "$P/sbin/php-fpm$v" ] || [ -e "$P/etc/rc.d/php_fpm$v" ] ||
        [ -n "$(sysrc -n "php_fpm${v}_enable" "php_fpm${v}_profiles" 2> /dev/null)" ]; then
        used=""
        sysrc -n "php_fpm${v}_enable" 2> /dev/null | grep -qiE '^(yes|true|on|1)$' && used="enabled in rc.conf"
        [ -n "$(sysrc -n "php_fpm${v}_profiles" 2> /dev/null)" ] && used="${used:-its profiles in rc.conf}"
        # it runs: a live pid in /var/run/php-fpmXY.pid or that of a profile
        for pf in "/var/run/php-fpm$v.pid" /var/run/php-fpm"$v"-*.pid; do
            [ -f "$pf" ] && kill -0 "$(cat "$pf")" 2> /dev/null && { fpm_was="$fpm_was $v"; used="${used:-it runs}"; break; }
        done
        refs="$(refs_of "sbin/php-fpm$v")"
        [ -n "$refs" ] && used="${used:-files name sbin/php-fpm$v}"
        if [ -n "$used" ]; then
            say "php$v: its FPM ($used) -> php$v-fpm (sbin/php$v-fpm, the rc.d script php${v}_fpm)"
            want="$want php$v-fpm"
            fpm_new="$fpm_new $v"
            [ -n "$refs" ] && printf '%s\n' "$refs" | while IFS= read -r f; do
                say "  $f names sbin/php-fpm$v: sbin/php$v-fpm in step 5"
                printf '%s\t%s\t%s\n' "sbin/php-fpm$v" "sbin/php$v-fpm" "$f" >> "$edits"
            done
        else
            say "php$v: its FPM is neither enabled nor running, no file names it: no php$v-fpm (pkg install -r az php$v-fpm when it is needed)"
        fi
    fi
    # the CGI: phpXY-cgi when php-cgiXY runs or a file names it (bin/phpXY-cgi then)
    if [ -e "$P/bin/php-cgi$v" ]; then
        refs="$(refs_of "php-cgi$v")"
        runs=""
        pgrep -f "php-cgi$v" > /dev/null 2>&1 && runs=" (php-cgi$v runs now)"
        if [ -n "$refs" ] || [ -n "$runs" ]; then
            say "php$v: its CGI$runs -> php$v-cgi ($P/bin/php$v-cgi)"
            want="$want php$v-cgi"
            [ -n "$refs" ] && printf '%s\n' "$refs" | while IFS= read -r f; do
                say "  $f names php-cgi$v: php$v-cgi in step 5"
                printf '%s\t%s\t%s\n' "php-cgi$v" "php$v-cgi" "$f" >> "$edits"
            done
            [ -n "$refs" ] || say "  no file found that names php-cgi$v: change by hand what runs it to $P/bin/php$v-cgi"
        else
            say "php$v: php-cgi$v does not run, no file names it (/etc, $P/etc, /var/cron/tabs, the #! lines of small files 4 levels under /var/www, /home, $P/www): no php$v-cgi (pkg install -r az php$v-cgi when it is needed: $P/bin/php$v-cgi)"
        fi
    fi
    for f in "/etc/rc.conf.d/php_fpm$v" "$P/etc/rc.conf.d/php_fpm$v"; do
        [ -e "$f" ] && say "$f: there, not changed: its variables php_fpm${v}_* to php${v}_fpm_* by hand, as /etc/rc.conf below"
    done
done
[ -n "$want" ] || { say "nothing to move: no package of az under an old name, no FPM or CGI in a core of PHP"; exit 0; }

# every new package in the catalog of az before anything is changed: a catalog of before
# the new names (one level of x86-64 published before the other) stops it here
miss=""
for p in $want; do
    [ -n "$(pkg rquery -r az '%n' "$p" 2> /dev/null)" ] || miss="$miss $p"
done
if [ -n "$miss" ]; then
    say "not in the catalog of the repository az:$miss (its new names are not published for this server yet): nothing changed"
    exit 1
fi

for v in $fpm_was; do
    say "php_fpm$v runs: stopped now, php${v}_fpm started at the end"
    run service "php_fpm$v" stop || { say "service php_fpm$v stop failed"; exit 1; }
done

say "== 4. pkg upgrade -r az, then the new names"
if [ "$apply" = 1 ]; then
    if ! pkg upgrade -r az; then
        say "pkg upgrade -r az failed or was refused: nothing more done"
        for v in $fpm_was; do
            [ -e "$P/etc/rc.d/php_fpm$v" ] && { service "php_fpm$v" start || say "service php_fpm$v start failed"; }
        done
        exit 1
    fi
    # shellcheck disable=SC2086
    if ! pkg install -r az $want; then
        say "pkg install -r az$want failed or was refused: nothing more done"
        [ -n "$fpm_was" ] && say "the FPM stopped:$fpm_was: sh $0 --apply again (it finds them in rc.conf)"
        exit 1
    fi
else
    say "# pkg upgrade -r az"
    say "# pkg install -r az$want"
fi
left=""
for m in $map; do
    o="${m%%:*}"
    [ "$apply" = 1 ] && pkg info -e "$o" && [ "$(repo_of "$o")" = az ] && left="$left $o"
done
[ -n "$left" ] && say "still installed under an old name:$left (pkg delete them once their new packages are there)"

say "== 5. the files that name the programs of before"
if [ -s "$edits" ]; then
    while IFS="$tab" read -r o n f; do
        say "$f: $o -> $n"
        [ "$apply" = 1 ] || continue
        sed -i '' "s|$o|$n|g" "$f" || say "$f: sed failed: change $o to $n there by hand"
    done < "$edits"
else
    say "none"
fi

say "== 6. the variables of rc.conf"
for v in 56 74 81 82 83 84; do
    sysrc -a 2> /dev/null | sed -n "s/^php_fpm${v}_\([A-Za-z0-9_]*\): \(.*\)\$/\1 \2/p" | while read -r k val; do
        say "php_fpm${v}_$k=\"$val\" -> php${v}_fpm_$k"
        if [ "$apply" = 1 ]; then
            if sysrc "php${v}_fpm_$k=$val" > /dev/null; then
                sysrc -x "php_fpm${v}_$k" || say "sysrc -x php_fpm${v}_$k failed: remove it by hand"
            else
                say "sysrc php${v}_fpm_$k failed: php_fpm${v}_$k left as it was"
            fi
        else
            say "# sysrc php${v}_fpm_$k=\"$val\" && sysrc -x php_fpm${v}_$k"
        fi
    done
done

say "== 7. the FPM again"
# where it ran, and where rc.conf enables it and it does not run (a run cut short)
for v in $fpm_new; do
    if [ "$apply" = 1 ]; then
        [ -e "$P/etc/rc.d/php${v}_fpm" ] || { say "no $P/etc/rc.d/php${v}_fpm: is php$v-fpm installed?"; continue; }
        case " $fpm_was " in
        *" $v "*) ;;
        *) sysrc -n "php${v}_fpm_enable" 2> /dev/null | grep -qiE '^(yes|true|on|1)$' ||
               [ -n "$(sysrc -n "php${v}_fpm_profiles" 2> /dev/null)" ] || continue ;;
        esac
        service "php${v}_fpm" status > /dev/null 2>&1 && { say "php${v}_fpm runs already"; continue; }
    fi
    run service "php${v}_fpm" start || say "service php${v}_fpm start failed"
done
[ "$apache" = 1 ] && say "Apache: a module of it was renamed (php-apache, mod_fastcgi, mod_maxminddb): restart its instances"
[ "$nginx" = 1 ] && say "nginx: its Passenger agent is ruby34-passenger-nginx now: restart nginx"
[ "$apply" = 1 ] || say "nothing changed: sh $0 --apply does it"
exit 0
