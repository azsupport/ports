# databases/py-sqlite3 of azsupport/ports: the module sqlite3 of Python (_sqlite3),
# the package py312-sqlite3 of our lang/python312 (aZ, 11.11.2026), on the SQLite
# of az with the run path /usr/local/az/lib (our ports link each other's shared
# libraries: aZ, 10.11.2026), not on databases/sqlite3. The official port (its
# flavours: every version of Python, py312 the default one, which tools/build.sh
# builds; pyproject.toml, pkg-descr) with its setup.py made from setup.py.in: the
# include directory, the library and the run path of az instead of those of the
# prefix of Python, and the test of sqlite3_load_extension on the libsqlite3 of az
# (az builds it with --enable-load-extension, as databases/sqlite3). The source is
# Python of the official tree (the distinfo of its lang/python3XX; for py312 the
# same as that of our lang/python312).

PORTNAME=	sqlite3
DISTVERSION=	${PYTHON_DISTVERSION}
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	databases python
MASTER_SITES=	PYTHON/ftp/python/${DISTVERSION}
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
DISTNAME=	Python-${DISTVERSION}
DIST_SUBDIR=	python

MAINTAINER=	github@azsupport.com
COMMENT=	Standard Python binding to the SQLite3 library (Python ${PYTHON_VER}) (of azsupport/ports)
WWW=		https://docs.python.org/3/library/sqlite3.html \
		https://github.com/azsupport/ports

LICENSE=	PSFL
LICENSE_FILE=	${WRKDIR}/Python-${DISTVERSION}/LICENSE

# the SQLite of az, to build and to run (no ldconfig hints for /usr/local/az/lib:
# by a file)
BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}setuptools>0:devel/py-setuptools@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}wheel>0:devel/py-wheel@${PY_FLAVOR} \
		${AZ_PREFIX}/lib/libsqlite3.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libsqlite3.so:az/az

USES=		compiler:c11 python tar:xz
USE_PYTHON=	allflavors autoplist pep517

DISTINFO_FILE=	${PORTSDIR}/lang/python${PYTHON_BASESUFFIX}/distinfo
WRKSRC_SUBDIR=	Modules

SUB_LIST+=	AZ_PREFIX=${AZ_PREFIX} \
		DISTVERSION=${DISTVERSION}
SUB_FILES=	pyproject.toml setup.py
PLIST_FILES=	${PYTHONPREFIX_LIBDIR:S;${PREFIX}/;;}/lib-dynload/_sqlite3${PYTHON_SOABI}.so

PORTSCOUT=	ignore:1

pre-configure:
	@${MV} ${WRKDIR}/setup.py ${WRKDIR}/pyproject.toml ${WRKSRC}

post-install:
	@${STRIP_CMD} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/_sqlite3${PYTHON_SOABI}.so
	# lib-dynload is the expected location
	@${MKDIR} ${STAGEDIR}${PYTHONPREFIX_LIBDIR}/lib-dynload
	@(cd ${STAGEDIR}${PYTHONPREFIX_LIBDIR}/lib-dynload && ${LN} -s ../site-packages/_sqlite3${PYTHON_SOABI}.so)
# _sqlite3: the libsqlite3 of az, by its run path
	@${READELF} -d ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/_sqlite3${PYTHON_SOABI}.so | \
		${GREP} -q 'Shared library: \[libsqlite3\.so' || \
		{ ${ECHO_MSG} "_sqlite3${PYTHON_SOABI}.so does not link libsqlite3"; ${FALSE}; }
	@${READELF} -d ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/_sqlite3${PYTHON_SOABI}.so | \
		${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "_sqlite3${PYTHON_SOABI}.so has no run path ${AZ_PREFIX}/lib"; ${FALSE}; }

do-test:
	@${PYTHON_CMD} -c 'import sqlite3'  # minimal smoke test

.include <bsd.port.mk>
