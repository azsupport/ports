#!/bin/sh
# az-plist.sh - the plist of a port of az/az, ftp/curl, multimedia/ffmpeg,
# graphics/ImageMagick6 and graphics/ImageMagick7: every file and link under
# <stagedir><prefix>, as a path relative to <prefix>, sorted, as tools/build-az.sh
# of https://github.com/azsupport/php-src listed the files of its packages; the
# policy of ImageMagick (etc/ImageMagick-6/policy.xml, etc/ImageMagick-7/policy.xml)
# as @config, so that pkg keeps it when it was changed. The post-install of the
# ports appends this to TMPPLIST (the framework adds its own lines after it, such
# as share/licenses/<package>/).
#
# Usage: sh tools/az-plist.sh <stagedir> <prefix>
# Exit status: 0 the list printed, 1 no files there, 2 usage.

set -u
[ $# -eq 2 ] || { echo "usage: sh tools/az-plist.sh <stagedir> <prefix>" >&2; exit 2; }
d="$1$2"
[ -d "$d" ] || { echo "az-plist: no directory $d" >&2; exit 1; }
n="$(cd "$d" && find . ! -type d | wc -l | tr -d ' ')"
[ "$n" -gt 0 ] || { echo "az-plist: no files in $d" >&2; exit 1; }
(cd "$d" && find . ! -type d) | sed 's#^\./##' | LC_ALL=C sort |
    awk '/(^|\/)etc\/ImageMagick-[67]\/policy\.xml$/ { print "@config " $0; next } { print }'
