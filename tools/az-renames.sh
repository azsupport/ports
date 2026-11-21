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
#   1. pkg update -r az;
#   2. the packages of the repository az installed under an old name: the new name
#      for each (a package of another repository under an old name is left alone:
#      the official ruby is not ours);
#   3. PHP XY of az with the FPM or the CGI in its core (sbin/php-fpmXY, bin/php-cgiXY,
#      etc/rc.d/php_fpmXY): phpXY-fpm when rc.conf enables php_fpmXY (or profiles of it)
#      or it runs, phpXY-cgi when a file of etc names php-cgiXY (it is bin/phpXY-cgi
#      then: the files said, to change); the php-fpm of the old rc.d script php_fpmXY
#      stopped when it runs (with its profiles), started again as phpXY_fpm;
#   4. pkg upgrade -r az (the core of PHP without its FPM and CGI), then pkg install -r
#      az of the new names (pkg takes the packages of the old names away: the same
#      files); pkg asks before each;
#   5. the variables php_fpmXY_* of rc.conf (sysrc) as phpXY_fpm_* (enable, profiles,
#      the profiles' enable and flags, umask ...); a file /etc/rc.conf.d/php_fpmXY or
#      /usr/local/etc/rc.conf.d/php_fpmXY is said, not changed;
#   6. phpXY_fpm started where php_fpmXY ran.
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

say "== 1. the catalog of the repository az"
if [ "$apply" = 1 ]; then
    pkg update -r az || { say "pkg update -r az failed: is the repository az configured?"; exit 1; }
else
    say "# pkg update -r az"
fi

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
for v in 56 74 81 82 83 84; do
    pkg info -e "php$v" || continue
    r="$(repo_of "php$v")"
    [ "$r" = az ] || { say "php$v: from the repository ${r:-unknown}, not az: left alone"; continue; }
    # the FPM: phpXY-fpm when rc.conf enables php_fpmXY (or a profile of it) or it runs
    if [ -e "$P/sbin/php-fpm$v" ] || [ -e "$P/etc/rc.d/php_fpm$v" ]; then
        used=""
        sysrc -n "php_fpm${v}_enable" 2> /dev/null | grep -qiE '^(yes|true|on|1)$' && used="enabled in rc.conf"
        [ -n "$(sysrc -n "php_fpm${v}_profiles" 2> /dev/null)" ] && used="${used:-its profiles in rc.conf}"
        # it runs: a live pid in /var/run/php-fpmXY.pid or that of a profile
        for pf in "/var/run/php-fpm$v.pid" /var/run/php-fpm"$v"-*.pid; do
            [ -f "$pf" ] && kill -0 "$(cat "$pf")" 2> /dev/null && { fpm_was="$fpm_was $v"; used="${used:-it runs}"; break; }
        done
        if [ -n "$used" ]; then
            say "php$v: its FPM ($used) -> php$v-fpm (the rc.d script php${v}_fpm)"
            want="$want php$v-fpm"
        else
            say "php$v: its FPM is neither enabled nor running: no php$v-fpm (pkg install -r az php$v-fpm when it is needed)"
        fi
    fi
    # the CGI: phpXY-cgi when a file of etc names bin/php-cgiXY (the wrappers of suexec,
    # the FastCGI of Apache), which is bin/phpXY-cgi then
    if [ -e "$P/bin/php-cgi$v" ]; then
        refs="$(grep -rlsF "php-cgi$v" "$P/etc" 2> /dev/null | head -n 20 | tr '\n' ' ')"
        if [ -n "$refs" ]; then
            say "php$v: its CGI -> php$v-cgi; these files name php-cgi$v, which is $P/bin/php$v-cgi then: change them: $refs"
            want="$want php$v-cgi"
        else
            say "php$v: no file of $P/etc names php-cgi$v: no php$v-cgi (pkg install -r az php$v-cgi when a wrapper elsewhere runs it; it is $P/bin/php$v-cgi then)"
        fi
    fi
    for f in "/etc/rc.conf.d/php_fpm$v" "$P/etc/rc.conf.d/php_fpm$v"; do
        [ -e "$f" ] && say "$f: there, not changed: its variables php_fpm${v}_* to php${v}_fpm_* by hand, as /etc/rc.conf below"
    done
done
[ -n "$want" ] || { say "nothing to move: no package of az under an old name, no FPM or CGI in a core of PHP"; exit 0; }

for v in $fpm_was; do
    say "php_fpm$v runs: stopped now, php${v}_fpm started at the end"
    run service "php_fpm$v" stop || { say "service php_fpm$v stop failed"; exit 1; }
done

say "== 4. pkg upgrade -r az, then the new names"
if [ "$apply" = 1 ]; then
    pkg upgrade -r az || { say "pkg upgrade -r az failed or was refused: nothing more done"; exit 1; }
    # shellcheck disable=SC2086
    pkg install -r az $want || { say "pkg install -r az$want failed or was refused: nothing more done"; exit 1; }
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

say "== 5. the variables of rc.conf"
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

say "== 6. the FPM again"
for v in $fpm_was; do
    run service "php${v}_fpm" start || say "service php${v}_fpm start failed"
done
[ "$apache" = 1 ] && say "Apache: a module of it was renamed (php-apache, mod_fastcgi, mod_maxminddb): restart its instances"
[ "$nginx" = 1 ] && say "nginx: its Passenger agent is ruby34-passenger-nginx now: restart nginx"
[ "$apply" = 1 ] || say "nothing changed: sh $0 --apply does it"
exit 0
