# lang/ruby34 of azsupport/ports: Ruby 3.4, the RUBY_DEFAULT of the ports tree, in the
# place of the official one (aZ, 20.11.2026: «пока добавляй lang/ruby34 и
# devel/ruby-gems»), the package ruby34 (aZ, 21.11.2026: the name with the version
# first, as php84; the official package of the default Ruby is ruby, which the official
# gems depend on: they go with the official ruby, not with this one). The official
# port (its patches, pkg-plist, pkg-descr, pkg-message) with:
# - the options of aZ: GMP on (the Bignum of Ruby on GMP, as the make.conf of aZ's
#   servers had GMP in OPTIONS_SET), RDOC off (the ri indexes are documents: DOCS and the
#   manual pages are off everywhere, tools/make.conf.in), CAPIDOCS, DEBUG, DOCS and
#   EXAMPLES off, YJIT on (aZ, 20.11.2026: «включай. У нас же правило - скорость.»: the
#   JIT of Ruby, which Rails 7.2 and later turn on themselves: faster, more memory;
#   Rust only to build it, the rustc of the official lang/rust);
# - libffi (fiddle), GMP and libyaml (psych) of azsupport, with the run path /usr/local/azsupport/lib
#   (Mk/azsupport-libs.mk: each with its own headers and .pc files), instead of devel/libffi,
#   math/gmp and textproc/libyaml: the package takes no package but azsupport; OpenSSL, zlib
#   and libexecinfo of the base system;
# - no libunwind (devel/libunwind, which the official port takes on amd64 for the C
#   level backtrace of a crash report; the backtrace of the base libexecinfo stays):
#   the configure test of libunwind.h answered no, so no build machine decides it.
# The flags of the build go into rbconfig.rb as there: a native extension of a gem built
# with this Ruby (mkmf) links with the -L and the run path of azsupport too.
# The C compiled by GCC 16 of the ports (USES=azgcc, Mk/Uses/azgcc.mk; a build dependency
# only), aZ 27.11.2026 08:43 («окей, следуем инфе с тестов»): prog-bench (bignum, calls,
# hash, json, objects, regex, sort, string, each with and without YJIT) against the base
# clang 19, run 45926215732: GCC 16 -2.2%, clang 23 -1.1% by the median, GCC 16 faster
# than clang 23 by 1.2%, clear in 3 of 16 (calls -13.3%), clang 19 in 1 (objects +11.8%);
# faster than clang 23 on three other machines too (by 1.6%, 4.0%, 2.2%: 45905132701,
# 45913465743, 45918232254). No PIE of the framework (PIE_UNSAFE): GCC takes the -pie of
# LDFLAGS, which configure puts into DLDFLAGS after the -shared of LDSHARED, for a program
# and would link libruby34.so and the extensions as programs (Scrt1.o: undefined reference
# to main; clang leaves -pie out with -shared), as lang/python312 had it with GCC 16;
# ruby34 is a small program over libruby34.so (--enable-shared), which is position
# independent anyway. rbconfig.rb names cc, c++ and cpp (Mk/azsupport-cc-names.sh), so
# that mkmf builds an extension with the cc of a server. files/patch-ext_socket-union_sockaddr:
# getsockname(), getpeername(), recvfrom() and recvmsg() of ext/socket given the whole
# union_sockaddr, which _FORTIFY_SOURCE=2 of the base system checks, with GCC, by the 16 bytes
# of its member struct sockaddr: each of these calls would end in __chk_fail() (27.11.2026).

PORTNAME=	ruby
PORTVERSION=	${RUBY_DISTVERSION}
PORTREVISION=	${AZSUPPORT_STAMP:U0}
PORTEPOCH=	${RUBY_PORTEPOCH}
CATEGORIES=	lang ruby
MASTER_SITES=	RUBY/${MASTER_SITE_SUBDIR_RUBY}
DIST_SUBDIR=	ruby

MAINTAINER=	github@azsupport.com
COMMENT=	Object-oriented interpreted scripting language (of azsupport/ports)
WWW=		https://www.ruby-lang.org/en/ \
		https://github.com/ruby/ruby \
		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE RUBY
LICENSE_COMB=	dual
LICENSE_FILE_BSD2CLAUSE=${WRKSRC}/BSDL
LICENSE_FILE_RUBY=	${WRKSRC}/COPYING

# libffi, GMP and libyaml of azsupport (Mk/azsupport-libs.mk below), not the ports
AZSUPPORT_LIBS=	libffi:libffi.so gmp:libgmp.so libyaml:libyaml.so

USES=		autoreconf cpe ruby:none ssl tar:xz
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES+=		azgcc
PIE_UNSAFE=	GCC links libruby and the extensions as programs with -shared -pie

CPE_VENDOR=	ruby-lang
CPE_UPDATE=	p0

CONFIGURE_ARGS=	${RUBY_CONFIGURE_ARGS} \
		--disable-rpath \
		--enable-install-static-library \
		--enable-pthread \
		--enable-shared \
		--with-ruby-version=minor \
		--with-sitedir="${PREFIX}/lib/ruby/site_ruby" \
		--with-vendordir="${PREFIX}/lib/ruby/vendor_ruby"
CONFIGURE_ENV=	debugflags= \
		ac_cv_header_libunwind_h=no
EXTRACT_AFTER_ARGS=	\
		--exclude ${DISTNAME}/bin/gem \
		--exclude ${DISTNAME}/ext/win32* \
		--exclude ${DISTNAME}/lib/bundler* \
		--exclude ${DISTNAME}/lib/irb* \
		--exclude ${DISTNAME}/man/erb.1 \
		--exclude ${DISTNAME}/man/irb.1 \
		--exclude ${DISTNAME}/man/ri.1 \
		--exclude ${DISTNAME}/sample/win32ole \
		--no-same-owner --no-same-permissions
GNU_CONFIGURE=	yes
# Keep this, else ruby will fail to load libraries dependent of libpthread.
LIBS+=		-lpthread
USE_LDCONFIG=	yes

RUBY_VER=	3.4

EXTDOCS=	ripper/README stringio/README.md
INSTALLED_MANUALS=	ruby
INSTALLED_SCRIPTS=	ruby
# Macros to change variables in rbconfig.rb
# NOTE: The last argument RB_SET_CONF_VAR is a dummy argument. See bug 222872.
RB_SET_CONF_VAR=${SH} -c \
		'${REINPLACE_CMD} -E -e "s,(CONFIG\[\"$$0\"\][[:space:]]*=[[:space:]]*)(\(?)(.*)(\)?),\1\2$$1\4," ${WRKSRC}/rbconfig.rb' \
		RB_SET_CONF_VAR

OPTIONS_DEFINE=	CAPIDOCS DEBUG DOCS EXAMPLES GMP RDOC YJIT
OPTIONS_DEFAULT=GMP YJIT
OPTIONS_SUB=	yes
CAPIDOCS_DESC=	Build and install C API documents
GMP_DESC=	Use GMP to accelerate Bignum operations
RDOC_DESC=	Build and install Rdoc indexes
YJIT_DESC=	Enable YJIT (Yet Another Ruby JIT)

CAPIDOCS_BUILD_DEPENDS=	dot:graphics/graphviz \
			doxygen>=1.8.13,2:devel/doxygen
CAPIDOCS_CONFIGURE_ENABLE=	install-capi
GMP_CONFIGURE_WITH=	gmp
RDOC_CONFIGURE_ENABLE=	install-rdoc
YJIT_BUILD_DEPENDS=	${RUST_DEFAULT}>=1.58.0:lang/${RUST_DEFAULT}
YJIT_CONFIGURE_ENABLE=	yjit

.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

.include <bsd.port.pre.mk>

# Ruby 3.4.13 (18.11.2026) in the place of the 3.4.12 of the pinned tree: seven
# vulnerabilities of Regexp (compilation, case-insensitive matching, Regexp#to_s) and of
# the case conversion of String (heap buffer overflows, a double free; remote code
# execution with an attacker's string or pattern), GHSA-34m4-m9fh-gqp5,
# GHSA-7x2q-68qv-6p8x, GHSA-87fm-7w84-j2px, GHSA-wpqw-5qxg-m68r, GHSA-3p8q-wmhx-vm2w,
# GHSA-7whj-cfh7-xgm4, GHSA-pvgc-g7gj-pv6h; no default gem changed its version, so
# pkg-plist and the patches stay. Set here, after bsd.port.pre.mk, where USES=ruby sets
# RUBY_DISTVERSION: PORTVERSION, DISTNAME and RUBY_VERSION read it when they are
# expanded. Goes when the pinned tree has 3.4.13.
RUBY_DISTVERSION=	3.4.13

# PORTREVISION/PORTEPOCH hack

.if ${PORTREVISION} != 0
_SUF1=		_${PORTREVISION}
.endif

.if ${PORTEPOCH} != 0
_SUF2=		,${PORTEPOCH}
.endif

#.if ${OPSYS} == "FreeBSD"
#.if exists(/usr/sbin/dtrace) && (${ARCH} == amd64 || ${ARCH} == i386 || ${ARCH} == powerpc64le || ${ARCH} == powerpc64 || ${ARCH} == powerpc)
#CONFIGURE_ARGS+=--enable-dtrace
#.else
#CONFIGURE_ARGS+=--disable-dtrace
#.endif
#.endif


.if ${ARCH} == armv6 || ${ARCH} == armv7 || ${ARCH} == powerpc
CONFIGURE_ARGS+=--with-setjmp-type=_setjmp
CONFIGURE_ENV+=	ac_cv_func__setjmp=yes
.endif

# the package ruby34 for the default Ruby too (the official one is then ruby); the
# default keeps its links bin/ruby, irb ... (IF_DEFAULT)
PKGNAMESUFFIX=	${RUBY_SUFFIX}
.if ${RUBY_VER} == ${RUBY_DEFAULT_VER}
PLIST_SUB+=	IF_DEFAULT=""
.else
PLIST_SUB+=	IF_DEFAULT="@comment "
.endif

post-build:
#
# Hack to allow modules to be installed into separate PREFIX and/or under user
# privileges
#
	@${RB_SET_CONF_VAR} "prefix" "ENV['PREFIX'] || \3"
	@${RB_SET_CONF_VAR} "INSTALL" "'/usr/bin/install -c'"
	@${RB_SET_CONF_VAR} "INSTALL_PROGRAM" "ENV['RB_USER_INSTALL'] ? '${INSTALL} ${COPY} ${STRIP} -m ${BINMODE}' : '${INSTALL_PROGRAM}'"
	@${RB_SET_CONF_VAR} "INSTALL_SCRIPT" "ENV['RB_USER_INSTALL'] ? '${INSTALL} ${COPY} -m ${BINMODE}' : '${INSTALL_SCRIPT}'"
	@${RB_SET_CONF_VAR} "INSTALL_DATA" "ENV['RB_USER_INSTALL'] ? '${INSTALL} ${COPY} -m ${SHAREMODE}' : '${INSTALL_DATA}'"

post-build-CAPIDOCS-on:
	@${FIND} ${WRKSRC}/doc -type d -empty -delete

pre-install:
	${MKDIR} ${STAGEDIR}${RUBY_SITEARCHLIBDIR}
	${MKDIR} ${STAGEDIR}${RUBY_VENDORARCHLIBDIR}

pre-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${RUBY_DOCDIR}

pre-install-EXAMPLES-on:
	${MKDIR} ${STAGEDIR}${RUBY_EXAMPLESDIR}

pre-install-RDOC-on:
	${MKDIR} ${STAGEDIR}${RUBY_RIDIR}
	${MKDIR} ${STAGEDIR}${RUBY_SITERIDIR}

post-install:
.if ${RUBY_VER} == ${RUBY_DEFAULT_VER}
#
# Link just installed "ruby" to "ruby34", etc.
#
. for FILE in ${INSTALLED_SCRIPTS}
	${LN} -fs ${FILE}${RUBY_SUFFIX} ${STAGEDIR}${PREFIX}/bin/${FILE}
. endfor
#
# Link "ruby.1.gz" to "ruby34.1.gz", etc.
#
. for FILE in ${INSTALLED_MANUALS}
	${LN} -fs ${FILE}${RUBY_SUFFIX}.1.gz ${STAGEDIR}${PREFIX}/share/man/man1/${FILE}.1.gz
. endfor
.endif

post-install-CAPIDOCS-on:
	${RM} ${WRKSRC}/doc/capi/.timestamp ${STAGEDIR}${PREFIX}/share/doc/ruby${RUBY_SUFFIX}/capi/.timestamp
	cd ${STAGEDIR}${PREFIX} && ${FIND} share/doc/ruby${RUBY_SUFFIX}/capi/ -type f >> ${TMPPLIST}

post-install-DEBUG-off:
#
# XXX: hack to strip ruby binary. Ruby uses its own install script that seems
# bogus to hack.
#
.if defined(STRIP) && ${STRIP} == -s
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/ruby${RUBY_SUFFIX}
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/libruby${RUBY_SHLIBVER}.so.${RUBY_SHLIBVER}
	${FIND} ${STAGEDIR}${RUBY_ARCHLIBDIR} -type f -name '*\.so' -exec ${STRIP_CMD} {} \;
# the static library without the debug information of its objects (the Rust of YJIT is
# built with -g; no debug in our packages, aZ 17.11.2026)
	${STRIP_CMD} --strip-debug ${STAGEDIR}${PREFIX}/lib/libruby${RUBY_SHLIBVER}-static.a
.endif

post-install-DOCS-on:
# Create all dirs required (":u" isn't available in STABLE yet :-()
	${MKDIR} ${EXTDOCS:C|^([^/]+)/.*|\1|:S|^|${STAGEDIR}${RUBY_DOCDIR}/|}
.for FILE in ${EXTDOCS}
	${INSTALL_DATA} ${WRKSRC}/ext/${FILE} \
		${STAGEDIR}${RUBY_DOCDIR}/${FILE:C|^([^/]+)/.*|\1|}/
.endfor
	@(cd ${WRKSRC}/doc/ && ${COPYTREE_SHARE} \* ${STAGEDIR}${RUBY_DOCDIR}/)
	${INSTALL_DATA} ${WRKSRC}/COPYING* ${WRKSRC}/LEGAL ${WRKSRC}/README* ${STAGEDIR}${RUBY_DOCDIR}/

post-install-EXAMPLES-on:
	(cd ${WRKSRC}/sample/ && ${COPYTREE_SHARE} . ${STAGEDIR}${RUBY_EXAMPLESDIR}/)

do-test:
	cd ${WRKSRC} && ${MAKE_CMD} test

.include <bsd.port.post.mk>
