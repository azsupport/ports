# net/rsync: the rsync of azsupport/ports in the place of the official net/rsync
# (aZ, 10.11.2026): the official port (its patches, the extra patch of the option
# FLAGS: the flags of the files, --fileflags; ssh; zlib of the base system; the popt
# it bundles; its rc.d script, pkg-plist, pkg-descr, pkg-message) with lz4, zstd and
# xxhash the shared libraries of az, with the run path /usr/local/az/lib (our
# ports link each other's shared libraries: aZ, 10.11.2026), so that it takes no
# package but az (the official one takes liblz4, zstd and xxhash), and the
# OpenSSL of the base system (MD4, MD5). Without ICONV (--iconv: GNU libiconv)
# and IDN.
# rsync 3.5.2 (04.11.2026) ahead of the official port (3.5.1 with the fix of the
# delta-transfer sender, CVE-2026-119741, which 3.5.2 has): the rest of the fixes of
# 3.5.2 (rule of 04.11.2026: a vulnerability that touches us) - a write past a buffer
# after a read error, the stack of the daemon receiver at --max-alloc, --files-from
# of a subdirectory of a module read from the module root past its filters, the
# --inplace matcher past the checksums of the peer, IPv6 peers in hosts allow/deny,
# control characters of names escaped (aZ, 11.11.2026). Its distfile: SHA-256 of the
# release of GitHub as OpenBSD has it, the size as OpenBSD and Gentoo. The patch of
# FLAGS of the official port brought up to 3.5.2: in options.c of 3.5.2 the
# arguments of the server go through ADD_SERVER_ARG (bounded), --fileflags and
# --force-change too; "file-flags" of --version after "crtimes" as before; not the
# first lines of rsync.1 (its date and prefix only). Built with it on Linux:
# --version and --help say file-flags and --force-change.

PORTNAME=	rsync
DISTVERSION=	3.5.2
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	net
MASTER_SITES=	https://www.mirrorservice.org/sites/rsync.samba.org/src/ \
		http://rsync.mirror.garr.it/src/ \
		http://www.mirrorservice.org/sites/rsync.samba.org/src/ \
		https://download.samba.org/pub/rsync/src/

MAINTAINER=	github@azsupport.com
COMMENT=	Network file distribution/synchronization utility (of azsupport/ports)
WWW=		https://rsync.samba.org/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv3+
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${AZ_PREFIX}/lib/liblz4.so:az/az \
		${AZ_PREFIX}/lib/libxxhash.so:az/az \
		${AZ_PREFIX}/lib/libzstd.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/liblz4.so:az/az \
		${AZ_PREFIX}/lib/libxxhash.so:az/az \
		${AZ_PREFIX}/lib/libzstd.so:az/az

USES=		autoreconf:build cpe python shebangfix ssl
CPE_VENDOR=	samba
CPE_PRODUCT=	rsync
PYTHON_NO_DEPENDS=	yes
USE_RC_SUBR=	rsyncd
SHEBANG_FILES=	runtests.py support/rrsync

GNU_CONFIGURE=		yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
CONFIGURE_ARGS=		--disable-debug \
			--disable-md2man \
			--enable-ipv6 \
			--enable-md5-asm \
			--enable-roll-asm \
			--enable-roll-simd \
			--with-rsyncd-conf=${ETCDIR}/rsyncd.conf \
			--disable-iconv \
			--disable-iconv-open \
			--disable-idn \
			--with-included-popt \
			--with-included-zlib=no \
			--with-rsh=ssh \
			ac_cv_search_libiconv_open=no
INSTALL_TARGET=	install-strip

# the shared tree of az, with its run path (iconv is off, so its GNU iconv.h does
# not matter); libcrypto is that of the base system
CPPFLAGS+=	-I${AZ_PREFIX}/include
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

SUB_LIST=	NAME=rsyncd
EXTRA_PATCHES=	${FILESDIR}/extra-patch-file-flags.diff

post-patch:
	@${REINPLACE_CMD} -e 's:/etc/rsync/:${ETCDIR}/:g' \
		-e 's:/etc/rsyncd:${ETCDIR}/rsyncd:g' \
		-e 's:/etc/letsencrypt:${PREFIX}/etc/letsencrypt:g' \
		${WRKSRC}/rsync.1 ${WRKSRC}/rsyncd.conf.5
	@${REINPLACE_CMD} -e 's|/usr/bin/rsync|${PREFIX}/bin/rsync|g' ${WRKSRC}/support/rrsync

pre-configure:
	@(cd ${WRKSRC} && ${SETENVI} ${WRK_ENV} ${MAKE_CMD} -f prepare-source.mak)

post-install:
	@${MKDIR} ${STAGEDIR}${ETCDIR}
	${INSTALL_DATA} ${FILESDIR}/rsyncd.conf.sample ${STAGEDIR}${ETCDIR}/
	${INSTALL_SCRIPT} ${WRKSRC}/support/rrsync ${STAGEDIR}${PREFIX}/sbin

.include <bsd.port.mk>
