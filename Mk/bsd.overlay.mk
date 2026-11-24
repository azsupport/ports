# Settings of the overlay azsupport/ports for every port built with
# OVERLAYS=<this tree>: bsd.port.mk includes this file twice (once before and
# once after the port's own settings are processed), so it only adds to lists
# and assigns with ?=.
#
# AZ_PREFIX: the shared tree of the package az (origin az/az): lib/ (the
# shared libraries, SONAME and run path ${AZ_PREFIX}/lib, no ldconfig hints),
# lib/pkgconfig/, include/, bin/pkg-config and bin/*-config. AZ_STATIC: its
# static tree (lib/, include/, bin/pkg-config --static). Our ports use these
# two, never the literal path, and do not define them (aZ, 08.11.2026: the
# prefix is /usr/local/az). Lazy assignments, so that a port may use them in its
# Makefile before this file is read (no := and no .if on them in a port).

# az: the category of our own ports that have no place in the official tree
VALID_CATEGORIES+=	az

AZ_PREFIX?=	${LOCALBASE}/az
AZ_STATIC?=	${AZ_PREFIX}/static

# AZ_STAMP: the revision of our packages, the time of the build (yymmddhh),
# which the builder (tools/) passes, so that every build is an upgrade; 0
# without it. lang/php74 writes PORTREVISION= ${AZ_STAMP:U0}: bsd.port.mk tests
# PORTREVISION before it reads this file.
AZ_STAMP?=	0

# AZ_HASH: the hash of the port (with its master, Mk/ and its dependencies)
# that the builder computes, kept in the package as the annotation az_hash, so
# that the builder rebuilds a port only when its hash changes. Added once,
# although bsd.port.mk includes this file twice.
.if defined(AZ_HASH) && !empty(AZ_HASH) && empty(PKG_NOTES:Maz_hash)
PKG_NOTES+=	az_hash
PKG_NOTE_az_hash=	${AZ_HASH}
.endif

# The libraries of ${AZ_PREFIX}/lib (az, and the shared ones of ImageMagick7 and
# GraphicsMagick) count as libraries the packages provide: the framework gives
# pkg SHLIB_PROVIDE_PATHS_NATIVE from LIB_DIRS (and USE_LDCONFIG), only /lib,
# /usr/lib and ${LOCALBASE}/lib by default, so pkg 2 refused php74 ("Missing shlib
# libargon2.so.0", run 42514624927). No ldconfig hints for that directory (its
# libraries are found by their run path). Added once, although bsd.port.mk
# includes this file twice.
.if empty(LIB_DIRS:M${AZ_PREFIX}/lib)
LIB_DIRS+=	${AZ_PREFIX}/lib
.endif

# AZ_OVERLAY: this tree (the directory above this Mk/), for the files of Mk/ the targets
# below use
AZ_OVERLAY:=	${.PARSEDIR:H}

# No manual pages, documentation or info pages in our packages (aZ, 20.11.2026: «и доки и
# маны мы не юзаем»; DOCS, MAN3 and MANPAGES were off already, but most ports install
# their manual pages whatever the options, and the package script of postfix chowned the
# manual pages of the main.cf of a server: "chown: /usr/local/man/man1/mailq.1.gz: No such
# file or directory"). az-no-docs, a target of POST_PLIST (990 of the stage: after
# compress-man and the add-plist-* targets), takes out of the stage share/man, man,
# share/doc and share/info of the prefix, the manual directories of MANDIRS under it
# (the man3 of Perl), the empty site_perl/man/man1 and man3 that lang/perl5.* makes and
# etc/man.d (the manpath of those pages), and their lines out of the plist (files, @dir,
# @info and the other keywords). tools/docs-check.sh (tools/build.sh) fails a repository
# with such a file or directory.
.if empty(POST_PLIST:Maz-no-docs)
POST_PLIST+=	az-no-docs
.endif
.if !target(az-no-docs)
az-no-docs:
	@for d in ${MANDIRS:M${PREFIX}/*:S,^${PREFIX}/,,} man share/man share/doc share/info etc/man.d lib/perl5/site_perl/man; do \
		[ ! -e "${STAGEDIR}${PREFIX}/$$d" ] || ${RM} -r "${STAGEDIR}${PREFIX}/$$d"; \
		${SED} -i '' -E -e "\#^(@[^[:space:]]+[[:space:]]+)?(${PREFIX}/)?$$d(/|\$$)#d" ${TMPPLIST}; \
	done
.endif

# No info pages, so no print/indexinfo either (aZ, 24.11.2026 19:31: «а с какого хера
# bash зависимость к indexinfo? и тем более котоой у нас нет?»; 19:35: for every port in
# this file, automake too): bsd.port.mk adds indexinfo:print/indexinfo to RUN_DEPENDS
# and the @info lines of add-plist-info for INFO, both after both inclusions of this
# file, and az-no-docs takes share/info out of every package. INFO set by the port's
# Makefile (that of the official port for Mk/az-official.mk) is undefined here, in both
# passes.
.undef INFO

# The keywords of pkg create for our packages: those of the official tree with those of
# Mk/Keywords over them (pkg takes one directory, PLIST_KEYWORDS_DIR), copied by
# az-keywords in the stage. Mk/Keywords/sample.ucl: @sample without "You may need to
# manually remove ... if it is no longer needed." at an upgrade (see its head).
.if empty(PKG_ENV:MPLIST_KEYWORDS_DIR=*)
PKG_ENV+=	PLIST_KEYWORDS_DIR=${WRKDIR}/az-keywords
.endif
# the files of Mk/ the targets read (not makefiles): in the az_hash of every port
.if empty(AZ_HASH_FILES:M${AZ_OVERLAY}/Mk/Keywords)
AZ_HASH_FILES+=	${AZ_OVERLAY}/Mk/Keywords ${AZ_OVERLAY}/Mk/az-services.awk
.endif
.if empty(POST_PLIST:Maz-keywords)
POST_PLIST+=	az-keywords
.endif
.if !target(az-keywords)
az-keywords:
	@${MKDIR} ${WRKDIR}/az-keywords
	@${CP} ${KEYWORDS}/*.ucl ${AZ_OVERLAY}/Mk/Keywords/*.ucl ${WRKDIR}/az-keywords/
.endif

# The services of a package (aZ, 20.11.2026: at the end of pkg upgrade, the commands that
# restart what was upgraded): an empty directory share/az/services/<service> for each
# rc.d script of the package and for the service its modules belong to (lib/php/<API>
# and etc/php<NN>/conf.d: php_fpm<NN>; libexec/nginx: nginx; libexec/apache24:
# apache24). pkg counts the directories of a package it installs or removes as touched,
# and the trigger of az (az/az/files/az-services.ucl) names the services touched in the
# transaction that rc.conf enables.
.if empty(POST_PLIST:Maz-services)
POST_PLIST+=	az-services
.endif
.if !target(az-services)
az-services:
	@for s in $$(${AWK} -v p="${PREFIX}/" -f ${AZ_OVERLAY}/Mk/az-services.awk ${TMPPLIST} | ${SORT} -u); do \
		${MKDIR} ${STAGEDIR}${PREFIX}/share/az/services/$$s; \
		${ECHO_CMD} "@dir share/az/services/$$s" >> ${TMPPLIST}; \
	done
.endif
