#!/bin/sh
# cpu-check.sh - whether the CPU of this machine runs code of an x86-64 level: the
# features the compiler turns on for -march=<level> against those it finds on this
# CPU with -march=native (CPUID, and for AVX and AVX-512 whether the system saves
# their registers), as tools/az-build.sh checks them before az. The packages of a
# level run in the build (configure tests, the tools a port builds and runs) and in
# the checks after it (tools/check-php.sh, the tests): on a CPU without the features
# of the level they die with SIGILL, hours into a run. build.yml runs it for
# x86-64-v4 (AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL) on the runner before
# anything else, and in the VM before tools/build.sh: a VM can have less than its
# runner (anyvm, the VM of vmactions, takes AVX-512 off on an AMD CPU under a
# hypervisor).
#
# Usage: sh tools/cpu-check.sh <x86-64 level> [<where> [<file>]]
#   (sh tools/cpu-check.sh x86-64-v4 runner cpu-check.txt)
#   <where>  the machine, for the line (runner, VM; default: this machine)
#   <file>   the line appended to it too (cpu-check.txt of build.yml, which
#            tools/report.sh shows)
# The line: "cpu (<where>): OK|FAIL (...)". Exit status: 0 the CPU has every feature
# of the level, 1 it lacks some or the compiler cannot tell them (no cc, or one
# without -march=<level>), 2 usage.

set -u
level="${1:-}"
where="${2:-this machine}"
out="${3:-}"
case "$level" in
    x86-64-v2|x86-64-v3|x86-64-v4) ;;
    *) echo "usage: sh tools/cpu-check.sh <x86-64-v2|x86-64-v3|x86-64-v4> [<where> [<file>]]" >&2; exit 2 ;;
esac

# the model of the CPU: hw.model of FreeBSD, the model name of Linux
model="$(sysctl -n hw.model 2> /dev/null || sed -n 's/^model name[[:space:]]*: *//p' /proc/cpuinfo 2> /dev/null | head -n 1)"
model="$(printf '%s' "${model:-an unknown CPU}" | tr -s ' ')"
# the features of the levels the compiler defines (__<feature>__ 1): those of
# x86-64-v2 to x86-64-v4 that a build turns on (the list of tools/az-build.sh)
feats() {
    cc "-march=$1" -dM -E - < /dev/null 2> /dev/null |
        sed -n -E 's/^#define __(SSE4_2|POPCNT|AVX|AVX2|BMI|BMI2|FMA|F16C|LZCNT|MOVBE|AVX512F|AVX512BW|AVX512CD|AVX512DQ|AVX512VL)__ 1$/\1/p' |
        LC_ALL=C sort -u
}
line() {
    echo "$1"
    [ -z "$out" ] || echo "$1" >> "$out"
}

if ! command -v cc > /dev/null 2>&1; then
    line "cpu ($where): FAIL ($model: no cc to ask the CPU, so $level is not checked)"
    exit 1
fi
need="$(feats "$level")"
have="$(feats native)"
if [ -z "$need" ] || [ -z "$have" ]; then
    line "cpu ($where): FAIL ($model: cc gives no features for -march=$level or -march=native, so $level is not checked)"
    exit 1
fi
lacks="$(printf '%s\n' "$need" | while read -r f; do printf '%s\n' "$have" | grep -qx "$f" || printf ' %s' "$f"; done)"
if [ -n "$lacks" ]; then
    line "cpu ($where): FAIL ($model lacks$lacks of $level: code built for $level dies there with SIGILL)"
    exit 1
fi
line "cpu ($where): OK ($model has every feature of $level: $(printf '%s' "$need" | tr '\n' ' '))"
exit 0
