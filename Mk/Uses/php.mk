# Support for PHP-based ports.
#
# The Mk/Uses/php.mk of freebsd-ports 036685c034ba (the ports commit of PHP
# 7.4) for the overlay azsupport/ports, with the framework of the pinned tree
# (f16b6dd0f7c1). What differs from the official file, and why:
# - Versions side by side (aZ): PHP_VER comes from the port (PHP_VER=74 in
#   lang/php74/Makefile.ext) or from its flavor php<ver>, one of
#   ${_ALL_PHP_VERSIONS}; no DEFAULT_VERSIONS of a single PHP, and no
#   etc/php.conf of a single installed PHP: what the installed core of the
#   version says is read from etc/php${PHP_VER}/php.conf (lang/php74 installs
#   it), the extension dir from php-config${PHP_VER} --extension-dir if php.conf
#   has none, else the table below (no -zts or -debug guess: our cores set
#   EXTENSION_DIR, lib/php/<API>).
# - The paths of a version: bin/phpize${PHP_VER}, bin/php-config${PHP_VER},
#   include/php${PHP_VER}/php (ext/<module> for the headers of a module and its
#   config.h, which @postexec lines collect in ext/php_config.h), the ini file
#   etc/php${PHP_VER}/conf.d/ext-${PHP_MOD_PRIO}-${PHP_MODNAME}.ini (@sample of
#   the .ini.sample, as php.mk of f16b6dd), the Apache module
#   libphp${PHP_VER}.so (aZ: for every version).
# - The modules of USE_PHP and their origins: Mk/php-modules.mk of the
#   overlay, <module>_DEPENDS=<origin> and <module>_PRIO=<NN> (the priority of
#   its ini file, the default of PHP_MOD_PRIO), for every module.
# - A module links the shared tree of the package az (${AZ_PREFIX} of
#   Mk/bsd.overlay.mk) with its run path (no ldconfig hints) and finds it with
#   its pkg-config (set in the post part, after USES=pkgconfig set pkgconf).
# - phpize reads config.m4 only: a config0.m4 or config9.m4 (so that php-src
#   runs it first or last) becomes config.m4 before phpize.
# - make EXTRA_CFLAGS="-include config.h": every source file of a module sees
#   its config.h first. Most include it themselves; those of mysqlnd do not
#   (php-src builds mysqlnd into PHP), so without it mysqlnd.so has no
#   get_module and no SSL code (php-src tools/build-pkg.sh).
# - No "pecl" in the names of the packages (aZ, 08.11.2026): PECL_PKGNAMEPREFIX
#   is php${PHP_VER}-.
# - apache.mk as the framework of f16b6dd wants it (apache_ARGS, USESDIR).
#
# Feature:	php
# Usage:	USES=php
# Valid ARGS:	(none), phpize, ext, zend, build, cli, cgi, mod, web, embed,
#		pecl, flavors, noflavors
#
#	- phpize   : Use to build a PHP extension.
#	- ext      : Use to build, install and register a PHP extension.
#	- zend     : Use to build, install and register a Zend extension.
#	- build    : Set PHP also as a build dependency.
#	- cli      : Want the CLI version of PHP.
#	- cgi      : Want the CGI version of PHP.
#	- mod      : Want the Apache Module for PHP.
#	- web      : Want the Apache Module or the CGI version of PHP.
#	- embed    : Want the embedded library version of PHP.
#	- pecl     : Fetches from PECL.
#	- flavors  : Generates flavors for supported versions.
#		     (implied by phpize,ext,zend,pecl)
#	- noflavors: Prevents generation of flavor.
#
# If the port requires a predefined set of PHP extensions, they can be
# listed in this way:
#
# USE_PHP=	ext1 ext2 ext3
#
# PHP and Zend extensions built with :ext and :zend are automatically enabled
# when the port is installed.  Each port creates a PHP_EXT_INI_FILE file and
# registers the extension in it.
#
# The PHP_EXT_INI_FILE file has a priority number embeded into its name so that
# extensions are loaded in the right order.  The priority is defined by
# PHP_MOD_PRIO and is a number between 00 and 99.
#
# For extensions that do not depend on any extension, the priority is
# automatically set to 20, for extensions that depend on another extension, the
# priority is automatically set to 30.  Some extensions may need to be loaded
# before everyone else (for example opcache), or after an extension with a
# priotity of 30, in that case, add PHP_MOD_PRIO=XX in the port's Makefile.
# For example:
#
# USES=		php:ext
# USE_PHP=	xml
# PHP_MOD_PRIO=	40
#
# In this overlay the priority of a module of Mk/php-modules.mk is its
# <module>_PRIO there, unless the port sets PHP_MOD_PRIO.
#
# The port can set these options in its Makefile before bsd.port.pre.mk:
#
# PHP_VER=N - The version of PHP the port is for (74), or the default flavor.
# IGNORE_WITH_PHP=N - The port doesn't work with PHP version N.
#
# BUILD_ONLY_DEFAULT_PHP_FLAVOR - explicitely marks non-default ignored (use in make.conf)
#
# You may combine multiple php:* arguments.
# Don't specify any php:* argument if your port will work with every PHP SAPI.
#
# If you are building PHP-based ports in poudriere(8) with ZTS enabled,
# add WITH_MPM=event to /etc/make.conf to prevent build failures.

.if !defined(_INCLUDE_USES_PHP_MK)

PHP_Include_MAINTAINER=	github@azsupport.com

_INCLUDE_USES_PHP_MK=	yes

_PHP_VALID_ARGS=	build cgi cli embed ext flavors mod noflavors pecl \
			phpize web zend
_PHP_UNKNOWN_ARGS=
.  for arg in ${php_ARGS}
.    if empty(_PHP_VALID_ARGS:M${arg})
_PHP_UNKNOWN_ARGS+=	${arg}
.    endif
.  endfor
.  if !empty(_PHP_UNKNOWN_ARGS)
IGNORE=	has unknown USES=php arguments: ${_PHP_UNKNOWN_ARGS}
.  endif

.  if ${php_ARGS:Mbuild} && ( ${php_ARGS:Mphpize} || ${php_ARGS:Mext} || ${php_ARGS:Mzend} )
DEV_WARNING+=	"USES=php:build is included in USES=php:phpize, USES=php:ext, and USES=php:zend, so it is not needed"
.  endif
.  if ${php_ARGS:Mflavors} && ( ${php_ARGS:Mphpize} || ${php_ARGS:Mext} || ${php_ARGS:Mzend} || ${php_ARGS:Mpecl} )
DEV_WARNING+=	"USES=php:flavors is included in phpize, ext, zend and pecl, so it is not needed."
.  endif
.  if ${php_ARGS:Mphpize} && ( ${php_ARGS:Mext} || ${php_ARGS:Mzend} )
DEV_WARNING+=	"USES=php:phpize is included in USES=php:ext and USES=php:zend, so it is not needed"
.  endif
.  if ${php_ARGS:Mext} && ${php_ARGS:Mzend}
DEV_WARNING+=	"USES=php:ext is included in USES=php:zend, so it is not needed"
.  endif
.  if ${php_ARGS:Mext} && ${php_ARGS:Mpecl}
DEV_WARNING+=	"USES=php:ext is included in USES=php:pecl, so it is not needed"
.  endif

.  if ( ${php_ARGS:Mphpize} || ${php_ARGS:Mext} || ${php_ARGS:Mzend} || ${php_ARGS:Mpecl} ) && !${php_ARGS:Mnoflavors}
php_ARGS+=	flavors
.  endif

.  if ${php_ARGS:Mnoflavors} && ${php_ARGS:Mflavors}
php_ARGS:=	${php_ARGS:Nflavors}
.  endif

.  if ${php_ARGS:Mpecl}
php_ARGS+=	ext
.    if !defined(USE_GITHUB)
EXTRACT_SUFX=	.tgz
MASTER_SITES=	https://pecl.php.net/get/ \
		http://pecl.php.net/get/
.    endif
PKGNAMEPREFIX=	${PECL_PKGNAMEPREFIX}
DIST_SUBDIR=	PECL
.  endif

PHPBASE?=	${LOCALBASE}

# the versions of PHP side by side
_ALL_PHP_VERSIONS=	56 74 81 82 83 84

.  if defined(BUILD_ONLY_DEFAULT_PHP_FLAVOR)
# Only build php ports of the default flavor
_ALL_FLAVOR_VERSIONS=	${PHP_VER}
.  else
# The version of the port first, so that it gets to be the default flavor.
_ALL_FLAVOR_VERSIONS=	${PHP_VER:U} ${_ALL_PHP_VERSIONS:N${PHP_VER:U}}
.  endif

# If we want flavors, fill in FLAVORS with the allowed PHP versions, if some
# cannot be used, or all of them if they all can.
# Then if there is no flavor set, use the first one as the default.
.  if ${php_ARGS:Mflavors}
.    if empty(FLAVORS)
.      if defined(IGNORE_WITH_PHP)
.        for _v in ${_ALL_FLAVOR_VERSIONS}
.          if empty(IGNORE_WITH_PHP:M${_v})
# Avoid a leading space in FLAVORS.
.            if empty(FLAVORS)
FLAVORS:=	php${_v}
.            else
FLAVORS:=	${FLAVORS} php${_v}
.            endif
.          endif
.        endfor
.      else # defined(IGNORE_WITH_PHP)
FLAVORS:=	${_ALL_FLAVOR_VERSIONS:S/^/php/}
.      endif # defined(IGNORE_WITH_PHP)
.    endif
.    if empty(FLAVOR)
FLAVOR=	${FLAVORS:[1]}
.    endif
.  endif

# So, we have PHP flavors, set PHP_VER accordingly.
.  if ${FLAVOR:Mphp[0-9][0-9]}
PHP_VER=	${FLAVOR:S/^php//}
.  endif

.  if empty(PHP_VER) || empty(_ALL_PHP_VERSIONS:M${PHP_VER})
IGNORE=	needs PHP_VER (or a flavor php<ver>), one of the versions side by side: ${_ALL_PHP_VERSIONS}
.  endif

.  if ${PHP_VER:U} == 74 && (${ARCH:Mmips*} || (${ARCH:Mpowerpc*} && !exists(/usr/bin/clang)) || ${ARCH} == sparc64)
USE_GCC=	yes
.  endif

# This variable is for dependencies lines, so you write:
# ${PHP_PKGNAMEPREFIX}foo:devel/php-foo@${PHP_FLAVOR}
PHP_FLAVOR=	php${PHP_VER}

# The installed core of the version: its php.conf (PHP_VERSION, PHP_SAPI,
# PHP_EXT_INC, PHP_EXT_DIR), else its php-config for the extension dir.
.  if exists(${PHPBASE}/etc/php${PHP_VER:U}/php.conf)
.include "${PHPBASE}/etc/php${PHP_VER}/php.conf"
.  endif
.  if !defined(PHP_EXT_DIR) && exists(${PHPBASE}/bin/php-config${PHP_VER:U})
PHP_EXT_DIR!=	${PHPBASE}/bin/php-config${PHP_VER} --extension-dir | ${SED} -ne 's,^${PHPBASE}/lib/php/\(.*\),\1,p'
.  endif

# The core of the version is not installed yet: what it will have. The module
# API of each version (the extension dir lib/php/<API>, which our cores set) and
# the extensions built into the core (those of the official ports for the
# versions other than 7.4, which are not written in the overlay yet).
.  if empty(PHP_EXT_DIR) || empty(PHP_EXT_INC)
.    if ${PHP_VER:U} == 84
PHP_EXT_DIR=	20240924
PHP_EXT_INC=	hash json openssl pcre random spl
.    elif ${PHP_VER:U} == 83
PHP_EXT_DIR=	20230831
PHP_EXT_INC=	hash json openssl pcre random spl
.    elif ${PHP_VER:U} == 82
PHP_EXT_DIR=	20220829
PHP_EXT_INC=	hash json openssl pcre random spl
.    elif ${PHP_VER:U} == 81
PHP_EXT_DIR=	20210902
PHP_EXT_INC=	hash json openssl pcre spl
.    elif ${PHP_VER:U} == 74
PHP_EXT_DIR=	20190902
PHP_EXT_INC=	hash pcre spl
.    elif ${PHP_VER:U} == 56
PHP_EXT_DIR=	20131226
PHP_EXT_INC=	pcre spl
.    endif
PHP_SAPI?=	""
.  endif # empty(PHP_EXT_DIR) || empty(PHP_EXT_INC)

# Set a few PKGNAME(PRE|SUF)FIX to be used in ports.
PHP_PKGNAMEPREFIX=	php${PHP_VER}-
PHP_PKGNAMESUFFIX=	-php${PHP_VER}
PECL_PKGNAMEPREFIX=	php${PHP_VER}-

.  if defined(IGNORE_WITH_PHP)
.    for VER in ${IGNORE_WITH_PHP}
.      if ${PHP_VER:U} == "${VER}"
_IGNORE_PHP_SET=
IGNORE=		cannot be installed: doesn't work with lang/php${PHP_VER} port\
		(doesn't support PHP ${IGNORE_WITH_PHP:C/^([578])/\1./})
.      endif
.    endfor
.  endif

.  if ${php_ARGS:Mweb}
.    if ${php_ARGS:Mcgi} || ${php_ARGS:Mmod}
check-makevars::
		@${ECHO_CMD} "If you use :web you cannot also use :cgi"
		@${ECHO_CMD} "or :mod. Use only one of them."
		@${FALSE}
.    endif
.  endif

.  if ${php_ARGS:Mcgi}
.    if defined(PHP_VERSION) && ${PHP_SAPI:Mcgi} == "" && ${PHP_SAPI:Mfpm} == ""
check-makevars::
		@${ECHO_CMD} "This port requires the CGI version of PHP, but you have already"
		@${ECHO_CMD} "installed a PHP port without CGI."
		@${FALSE}
.    endif
.  endif

.  if ${php_ARGS:Mcli}
.    if defined(PHP_VERSION) && ${PHP_SAPI:Mcli} == ""
check-makevars::
		@${ECHO_CMD} "This port requires the CLI version of PHP, but you have already"
		@${ECHO_CMD} "installed a PHP port without CLI."
		@${FALSE}
.    endif
.  endif

.  if ${php_ARGS:Membed}
.    if defined(PHP_VERSION) && ${PHP_SAPI:Membed} == ""
check-makevars::
		@${ECHO_CMD} "This port requires the embedded library version of PHP, but you have already"
		@${ECHO_CMD} "installed a PHP port without the embedded library."
		@${FALSE}
.    endif
.  endif

PHP_PORT?=	lang/php${PHP_VER}
MOD_PHP_PORT?=	www/mod_php${PHP_VER}

.  if ${php_ARGS:Mbuild}
BUILD_DEPENDS+=	${PHPBASE}/include/php${PHP_VER}/php/main/php.h:${PHP_PORT}
.  endif
RUN_DEPENDS+=	${PHPBASE}/include/php${PHP_VER}/php/main/php.h:${PHP_PORT}
.  if  ${php_ARGS:Mmod} || (${php_ARGS:Mweb} && defined(PHP_VERSION) && ${PHP_SAPI:Mcgi} == "" && ${PHP_SAPI:Mfpm} == "")
apache_ARGS?=	run
.include "${USESDIR}/apache.mk"
# libphpXY.so for every version (aZ), so that the versions do not overwrite each other
RUN_DEPENDS+=	${PHPBASE}/${APACHEMODDIR}/libphp${PHP_VER}.so:${MOD_PHP_PORT}
.  endif

PLIST_SUB+=	PHP_EXT_DIR=${PHP_EXT_DIR}
SUB_LIST+=	PHP_EXT_DIR=${PHP_EXT_DIR}

.  if ${php_ARGS:Mphpize} || ${php_ARGS:Mext} || ${php_ARGS:Mzend}
BUILD_DEPENDS+=	${PHPBASE}/bin/phpize${PHP_VER}:${PHP_PORT} \
		autoconf>0:devel/autoconf
GNU_CONFIGURE=	yes
CONFIGURE_ARGS+=--with-php-config=${PHPBASE}/bin/php-config${PHP_VER}
# the shared tree of the package az: its libraries with their run path (no
# ldconfig hints for ${AZ_PREFIX}/lib); its pkg-config below (post part)
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib
# every source file of the module sees its config.h first (mysqlnd's do not
# include it)
MAKE_ARGS+=	EXTRA_CFLAGS="-include ${WRKSRC}/config.h"

_USES_configure+=	190:phpize-message 250:do-phpize

phpize-message:
	@${ECHO_MSG} "===>  PHPizing for ${PKGNAME}"

# phpize reads config.m4 only: config0.m4 or config9.m4 becomes config.m4
do-phpize:
	@cd ${WRKSRC} && if [ ! -f config.m4 ]; then \
		for c in config[0-9].m4; do \
			if [ -f "$$c" ]; then \
				${ECHO_MSG} "===>  ${PKGNAME}: $$c as config.m4 for phpize${PHP_VER}"; \
				${MV} "$$c" config.m4; \
				break; \
			fi; \
		done; \
	fi
	@(cd ${WRKSRC}; ${SETENV} ${SCRIPTS_ENV} ${PHPBASE}/bin/phpize${PHP_VER})
.  endif

_USES_POST+=php
.endif

.if defined(_POSTMKINCLUDED) && !defined(_INCLUDE_USES_PHP_POST_MK)

_INCLUDE_USES_PHP_POST_MK=yes

# the modules of the overlay: <module>_DEPENDS (the origin of its port) and
# <module>_PRIO (the priority of its ini file)
.include "${.PARSEDIR}/../php-modules.mk"

# the pkg-config of the package az (it runs pkgconf with the .pc files of
# ${AZ_PREFIX} first), here in the post part: USES=pkgconfig adds
# PKG_CONFIG=pkgconf to CONFIGURE_ENV, and the last one is the one configure gets
.  if ${php_ARGS:Mphpize} || ${php_ARGS:Mext} || ${php_ARGS:Mzend}
CONFIGURE_ENV+=	PKG_CONFIG=${AZ_PREFIX}/bin/pkg-config
.  endif

.  if ${php_ARGS:Mext} || ${php_ARGS:Mzend}
PHP_MODNAME?=	${PORTNAME}
PHP_EXT_PKGMESSAGE=	${WRKDIR}/php-ext-pkg-message
_PKGMESSAGES+=	${PHP_EXT_PKGMESSAGE}
PHP_HEADER_DIRS+=	.
# If there is no priority defined, that of Mk/php-modules.mk, else we wing it.
.    if !defined(PHP_MOD_PRIO)
.      if defined(${PHP_MODNAME}_PRIO)
PHP_MOD_PRIO=	${${PHP_MODNAME}_PRIO}
.      elif defined(USE_PHP)
# If an extension needs another, put it after the others.
PHP_MOD_PRIO=	30
.      else
# Otherwise, put it where it with everybody.
PHP_MOD_PRIO=	20
.      endif
.    endif
PHP_EXT_INI_FILE=	etc/php${PHP_VER}/conf.d/ext-${PHP_MOD_PRIO}-${PHP_MODNAME}.ini.sample

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}
	@${INSTALL_LIB} ${WRKSRC}/modules/${PHP_MODNAME}.so \
		${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}
.    for header in ${PHP_HEADER_DIRS}
		@${MKDIR} ${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/${PHP_MODNAME}/${header}
		@${INSTALL_DATA} ${WRKSRC}/${header}/*.h \
			${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/${PHP_MODNAME}/${header}
.    endfor
	@${RM} ${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/${PHP_MODNAME}/config.h
	@${EGREP} "#define (COMPILE|HAVE|USE)_" ${WRKSRC}/config.h \
		> ${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/${PHP_MODNAME}/config.h
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/php${PHP_VER}/conf.d
.    if ${php_ARGS:Mzend}
	@${ECHO_CMD} "zend_extension=${PHP_MODNAME}.so" > ${STAGEDIR}${PREFIX}/${PHP_EXT_INI_FILE}
.    else
	@${ECHO_CMD} "extension=${PHP_MODNAME}.so" > ${STAGEDIR}${PREFIX}/${PHP_EXT_INI_FILE}
.    endif

_USES_stage+=	899:add-plist-phpext
add-plist-phpext:
	@${ECHO_CMD} "lib/php/${PHP_EXT_DIR}/${PHP_MODNAME}.so" \
		>> ${TMPPLIST}
	@${FIND} -P ${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/${PHP_MODNAME} ! -type d 2>/dev/null | \
		${SED} -ne 's,^${STAGEDIR}${PREFIX}/,,p' >> ${TMPPLIST}
	@${ECHO_CMD} "@postexec echo \#include \\\"ext/${PHP_MODNAME}/config.h\\\" >> %D/include/php${PHP_VER}/php/ext/php_config.h" \
		>> ${TMPPLIST}
	@${ECHO_CMD} "@preunexec cp %D/include/php${PHP_VER}/php/ext/php_config.h %D/include/php${PHP_VER}/php/ext/php_config.h.orig" \
		>> ${TMPPLIST}
	@${ECHO_CMD} "@preunexec grep -v ext/${PHP_MODNAME}/config.h %D/include/php${PHP_VER}/php/ext/php_config.h.orig > %D/include/php${PHP_VER}/php/ext/php_config.h || true" \
		>> ${TMPPLIST}
	@${ECHO_CMD} "@preunexec ${RM} %D/include/php${PHP_VER}/php/ext/php_config.h.orig" \
		>> ${TMPPLIST}
	@${ECHO_CMD} "@sample ${PHP_EXT_INI_FILE}" \
		>> ${TMPPLIST}
	@${ECHO_CMD} "[" > ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "{" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "  message: <<EOD" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "This file has been added to automatically load the installed extension:" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "${PREFIX}/${PHP_EXT_INI_FILE:S/.sample$//}" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "EOD" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "  type: install" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "}" >> ${PHP_EXT_PKGMESSAGE}
	@${ECHO_CMD} "]" >> ${PHP_EXT_PKGMESSAGE}
.  endif

# Extensions: those of Mk/php-modules.mk of the overlay (a module with a
# <module>_DEPENDS line there), and those built into the core of the version
# (PHP_EXT_INC), which need no package
.  if defined(USE_PHP) && ${USE_PHP:tl} != "yes"
.    for extension in ${USE_PHP}
ext=		${extension}
.      if !empty(PHP_EXT_INC:M${extension:S/:build//})
.      elif defined(${extension:S/:build//}_DEPENDS)
.        if !empty(php_ARGS:Mbuild) || !empty(ext:M*\:build)
BUILD_DEPENDS+=	${PHPBASE}/lib/php/${PHP_EXT_DIR}/${extension:S/:build//}.so:${${extension:S/:build//}_DEPENDS}
.        endif
RUN_DEPENDS+=	${PHPBASE}/lib/php/${PHP_EXT_DIR}/${extension:S/:build//}.so:${${extension:S/:build//}_DEPENDS}
.      elif ${ext:tl} != "yes" && !defined(_IGNORE_PHP_SET)
check-makevars::
			@${ECHO_CMD} "Unknown extension ${extension:S/:build//} for PHP ${PHP_VER}: no ${extension:S/:build//}_DEPENDS in Mk/php-modules.mk of the overlay."
			@${FALSE}
.      endif
.    endfor
.  endif
.endif
