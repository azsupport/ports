# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/erlang.sh: the group erlang of tools/prog-bench.sh (sourced by it).
# Erlang/OTP 28.5.0.9 (lang/erlang-runtime28: the official port, its distinfo) with its
# options here: kernel poll (kqueue), OpenSSL of the base system, sharing-preserving, no
# CHUNKS, CORBA, SCTP, DTrace, Java, ODBC, WX; --enable-deterministic-build, no PGO (the
# port: --disable-pgo); the JIT (BeamAsm: the code of the programs is its own, the
# runtime — schedulers, GC, ETS, the BIFs of binaries, PCRE of re, the distribution —
# is the C and C++ of the variant). RabbitMQ (net/rabbitmq) is Erlang code on it.
# The benchmarks: a module compiled by erlc of clang19 (BEAM is the same for the three), run
# by erl of each with one scheduler (+S 1:1) on the last CPU, each its own time: a ring of
# 1000 processes (a message 1000 times around), ETS (insert and lookup of 1000000 keys), maps,
# term_to_binary and binary_to_term of a big term, binaries (split and match), re:run over
# 200000 lines, the spawn of 200000 processes that build lists (the GC).

g_progs="erlang"

g_need() { :; }

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch erlang-otp-OTP-28.5.0.9_GH0.tar.gz ec31985aa8715be44d19329dbcc33e89a7d5a43bf63aca4556273701b317e9b4 \
        https://codeload.github.com/erlang/otp/tar.gz/OTP-28.5.0.9
    unpack erlang-otp-OTP-28.5.0.9_GH0.tar.gz "$W/src/erlang-$_v"
    _b="$W/b-erlang-$_v.log"
    _try=1
    while :; do
    if (cd "$W/src/erlang-$_v" && ./configure --prefix="$W/erlang-$_v" --enable-deterministic-build --disable-pgo \
        --disable-year2038 --enable-kernel-poll --with-ssl=/usr --enable-sharing-preserving --disable-sctp \
        --without-javac --without-odbc --without-wx --without-debugger --without-observer --without-et \
        --without-jinterface --without-megaco &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1 && [ -x "$W/erlang-$_v/bin/erl" ]; then
        bok erlang "$_v" "$(ls "$W/erlang-$_v"/lib/erlang/erts-*/bin/beam.smp | head -n 1)"
        break
    fi
    bno erlang "$_v" "$_b"
    # an abort of the emulator built (gcc16, 45904431576: "Abort trap" of the beam generating
    # asn1ct_rtt.erl) as the __chk_fail of _FORTIFY_SOURCE=2 with GCC (lang/python312): once more
    # with _FORTIFY_SOURCE=1, said in the report
    if [ "$_try" = 1 ] && grep -q -E 'Abort trap|core dumped' "$_b"; then
        _try=2
        export CFLAGS="$(echo "$CFLAGS" | sed 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=1/')" CXXFLAGS="$(echo "$CXXFLAGS" | sed 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=1/')"
        echo "erlang $_v: the build with _FORTIFY_SOURCE=2 aborted (above); measured the build with _FORTIFY_SOURCE=1" >> "$W/fails/$group-notes.md"
        say "erlang $_v: again with _FORTIFY_SOURCE=1"
        unpack erlang-otp-OTP-28.5.0.9_GH0.tar.gz "$W/src/erlang-$_v"
        continue
    fi
    break
    done
    rm -rf "$W/src/erlang-$_v"
}

g_keep() { echo "$W/erlang-$1"; }

g_bench() {
    mkdir -p "$W/erl"
    cat > "$W/erl/pb.erl" << 'EOF'
-module(pb).
-export([main/1]).
main([Name]) ->
    {T, _} = timer:tc(fun() -> run(list_to_atom(Name)) end),
    io:format("~.4f~n", [T / 1000000]),
    halt(0).
run(ring) ->
    N = 1000, M = 1000,
    Self = self(),
    First = lists:foldl(fun(_, Next) -> spawn(fun() -> relay(Next) end) end, Self, lists:seq(1, N - 1)),
    First ! M * N,
    wait_ring(First);
run(ets) ->
    T = ets:new(t, [set]),
    [ets:insert(T, {K, K * 2}) || K <- lists:seq(1, 1000000)],
    lists:foldl(fun(K, A) -> [{_, V}] = ets:lookup(T, K), A + V end, 0, lists:seq(1, 1000000));
run(maps) ->
    Mp = lists:foldl(fun(K, A) -> maps:put(integer_to_binary(K), K, A) end, #{}, lists:seq(1, 500000)),
    lists:foldl(fun(K, A) -> A + maps:get(integer_to_binary(K), Mp) end, 0, lists:seq(1, 500000));
run(term) ->
    Term = [{I, integer_to_binary(I), [I, I + 1.5, <<"payload">>], #{k => I}} || I <- lists:seq(1, 200000)],
    lists:foldl(fun(_, A) -> A + length(binary_to_term(term_to_binary(Term))) end, 0, lists:seq(1, 5));
run(binary) ->
    B = iolist_to_binary([[integer_to_binary(I), <<" word ">>, integer_to_binary(I * 7), <<"\n">>] || I <- lists:seq(1, 300000)]),
    lists:foldl(fun(_, A) -> A + length(binary:split(B, <<"\n">>, [global])) + length(binary:matches(B, <<"word">>)) end, 0, lists:seq(1, 5));
run(re) ->
    L = [iolist_to_binary(io_lib:format("10.~b.~b.1 - - [26/Nov/2026] \"GET /videos/~b/clip_~b.mp4 HTTP/1.1\" 200 ~b", [I rem 256, I div 256 rem 256, I, I rem 1000, I * 13 rem 100000])) || I <- lists:seq(1, 200000)],
    {ok, R} = re:compile(<<"^(\\d+\\.\\d+\\.\\d+\\.\\d+) - - \\[[^\\]]+\\] \"GET ([^ ?]+)[^\"]*\" (\\d+)">>),
    lists:foldl(fun(S, A) -> {match, [_, P, _]} = re:run(S, R, [{capture, all_but_first, binary}]), A + byte_size(P) end, 0, L);
run(gc) ->
    Self = self(),
    Ps = [spawn(fun() -> Self ! {done, length(lists:reverse(lists:seq(1, 200)))} end) || _ <- lists:seq(1, 200000)],
    collect(length(Ps), 0).
relay(Next) ->
    receive 0 -> Next ! 0; X -> Next ! X - 1, relay(Next) end.
wait_ring(First) ->
    receive 0 -> ok; X -> First ! X - 1, wait_ring(First) end.
collect(0, A) -> A;
collect(N, A) -> receive {done, X} -> collect(N - 1, A + X) end.
EOF
    "$W/erlang-clang19/bin/erlc" -o "$W/erl" "$W/erl/pb.erl" > "$W/erlc.log" 2>&1 || die "erlang: erlc: $(tail -n 3 "$W/erlc.log" | tr '\n' ' ')"
    for r in $(seq 1 "$rounds"); do
        say "erlang: round $r of $rounds"
        for v in $(order "$r"); do
            have erlang "$v" || continue
            for b in ring ets maps term binary re gc; do
                t="$(cpuset -l "$last" "$W/erlang-$v/bin/erl" +S 1:1 +A 1 -noshell -pa "$W/erl" -run pb main "$b" 2> "$W/cmd.err" | head -n 1)"
                [ -n "$t" ] || say "erlang $b $v: failed: $(tail -n 3 "$W/cmd.err" | tr '\n' ' ')"
                record erlang "$b" s lower "$v" "$t"
            done
        done
    done
}
