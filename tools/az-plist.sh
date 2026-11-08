#!/bin/sh
# az-plist.sh - the plist of a port of az/az, ftp/curl, multimedia/ffmpeg,
# graphics/ImageMagick6, ImageMagick7 and GraphicsMagick: every file and link under
# <stagedir><prefix>, as a path relative to <prefix>, sorted, as tools/build-az.sh
# of https://github.com/azsupport/php-src listed the files of its packages; the
# policy of ImageMagick (etc/ImageMagick-6/policy.xml, etc/ImageMagick-7/policy.xml)
# and the delegates of GraphicsMagick (lib/GraphicsMagick/config/delegates.mgk, also
# that of az/lib) as @config, so that pkg keeps them when they were changed. The post-install of the
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
# the manual pages under share/man by the names compress-man of the framework gives
# them after the post-install that runs this (a .gz to every name without one, files
# and links alike)
(cd "$d" && find . ! -type d) | sed -e 's#^\./##' -e '/^share\/man\//{/\.gz$/!s/$/.gz/;}' | LC_ALL=C sort |
    awk '/(^|\/)etc\/ImageMagick-[67]\/policy\.xml$/ || /(^|\/)lib\/GraphicsMagick\/config\/delegates\.mgk$/ { print "@config " $0; next } { print }'
