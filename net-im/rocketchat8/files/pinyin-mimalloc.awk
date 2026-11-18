# pinyin-mimalloc.awk: the Cargo.toml of @napi-rs/pinyin with mimalloc (its global
# allocator) on the TLS of a library loaded by dlopen, the feature local_dynamic_tls of the
# crate mimalloc (libmimalloc-sys: MI_LOCAL_DYNAMIC_TLS), not the initial-exec TLS it takes
# without it: node dlopens the module, and FreeBSD has no room left for its static TLS
# (net-im/rocketchat8, build run 44357987655 of 18.11.2026: "No space available for static
# Thread Local Storage"). Each line "mimalloc = ..." gets the feature:
#   mimalloc = "0.1"                       -> { version = "0.1", features = [...] }
#   mimalloc = { version = "0.1" }         -> { version = "0.1", features = [...] }
#   mimalloc = { ..., features = ["x"] }   -> features = ["local_dynamic_tls", "x"]
/^mimalloc[[:space:]]*=/ && !/local_dynamic_tls/ {
	if ($0 ~ /=[[:space:]]*"[^"]*"[[:space:]]*$/) {
		sub(/=[[:space:]]*/, "= { version = ")
		$0 = $0 ", features = [\"local_dynamic_tls\"] }"
	} else if ($0 ~ /features[[:space:]]*=[[:space:]]*\[/) {
		sub(/features[[:space:]]*=[[:space:]]*\[/, "features = [\"local_dynamic_tls\", ")
	} else {
		sub(/[[:space:]]*}[[:space:]]*$/, ", features = [\"local_dynamic_tls\"] }")
	}
}
{ print }
