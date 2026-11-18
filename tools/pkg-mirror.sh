#!/bin/sh
# tools/pkg-mirror.sh: before pkg reaches the package mirror of FreeBSD, every address of
# each name of the mirror (A, then AAAA) is tried on port 443, and the first that answers
# goes into /etc/hosts for that name, so pkg does not wait on an address without a route
# (aZ, 18.11.2026 23:23: «зеркало пакетов же резолвиться должно в несколько айпи, вот со
# всех айпи и пытайся тянуть, а не с первого попавшегося? тем более который без роута
# можно потом не юзать, а юзать другие айпи»; the run 44395976783 of the 16-core runner of
# 13Z0 had "No route to host" to pkgmir.geo.freebsd.org in its VM for 72 minutes).
#
# The names: pkgmir.geo.freebsd.org and the targets of the SRV record of pkg.FreeBSD.org
# (_https._tcp, the mirror_type srv of /etc/pkg/FreeBSD.conf). A name none of whose
# addresses answers keeps no line in /etc/hosts (the resolver as before). Exit 0 when
# every name has an address that answers, 1 otherwise (the caller tries again); what it
# finds goes to the output. The chroots of tools/build.sh copy /etc, so their pkg takes
# the same addresses.

hosts="pkgmir.geo.freebsd.org"
for t in $(host -t SRV _https._tcp.pkg.FreeBSD.org 2> /dev/null |
        awk '/has SRV record/ { sub(/\.$/, "", $NF); print tolower($NF) }'); do
    case " $hosts " in *" $t "*) ;; *) hosts="$hosts $t" ;; esac
done

rc=0
for h in $hosts; do
    # the lines of an earlier run for this name away
    if grep -q "[[:space:]]$h\$" /etc/hosts 2> /dev/null; then
        sed -i '' "/[[:space:]]$h\$/d" /etc/hosts
    fi
    v4="$(host -t A "$h" 2> /dev/null | awk '/has address/ { print $NF }')"
    v6="$(host -t AAAA "$h" 2> /dev/null | awk '/has IPv6 address/ { print $NF }')"
    if [ -z "$v4$v6" ]; then
        echo "pkg-mirror: $h: no address (DNS)"
        rc=1
        continue
    fi
    ok=""
    for a in $v4 $v6; do
        if nc -z -w 5 "$a" 443 > /dev/null 2>&1; then
            ok="$a"
            break
        fi
        echo "pkg-mirror: $h: $a does not answer on port 443, passed over"
    done
    if [ -n "$ok" ]; then
        echo "$ok $h" >> /etc/hosts
        echo "pkg-mirror: $h: $ok (of $(echo $v4 $v6 | wc -w | tr -d ' ') addresses)"
    else
        echo "pkg-mirror: $h: none of its addresses answers on port 443: $(echo $v4 $v6)"
        rc=1
    fi
done
exit "$rc"
