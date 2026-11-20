# lang/rust of azsupport/ports: the official port (Mk/az-official.mk), Rust 1.99.1 for
# the servers (aZ, 20.11.2026: «наш порт»): the native extensions of gems written in
# Rust (rb_sys) are built with its cargo there, with the libclang of devel/llvm19 for
# bindgen. Options: LTO on (aZ, 20.11.2026: «да»: ThinLTO of rustc and of its LLVM,
# lto="thin" and thin-lto=true of its config.toml: a faster compiler; the code it
# builds does not change by it); SOURCES (rust-src) and WASM (wasm32-unknown-unknown)
# off; DOCS off (tools/make.conf.in); GDB and PORT_LLVM off as in the official
# default: the LLVM of Rust's own sources. The builds of this tree take the official
# package as their build tool (AZ_TOOLS_OFFICIAL of tools/build.sh: YJIT of
# lang/ruby34, graphics/librsvg2-rust and the others), so this port builds nothing
# else again.

AZ_OFFICIAL=	lang/rust
OPTIONS_SLAVE=	LTO
OPTIONS_EXCLUDE=	SOURCES WASM

.include "${.CURDIR:H:H}/Mk/az-official.mk"
