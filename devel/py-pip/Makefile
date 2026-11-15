# devel/py-pip: the pip of azsupport/ports in the place of the official devel/py-pip
# (aZ, 15.11.2026), the package py312-pip of our lang/python312. pip 26.3 ahead of
# the official port (23.3.2): pip 23.3.2 unpacks tar archives with code of its own,
# which does not check where symbolic links point (CVE-2025-8869, fixed in pip 25.3).
# Its source of PyPI, built by flit_core (pyproject.toml: no setup.py since pip 25,
# so not the patch-setup.py of the official port, which took the scripts pip3 and
# pip3.X out): the script pip3 taken out of pyproject.toml, so that the package
# has the files of the official one (bin/pip; concurrent: bin/pip-3.12).

PORTNAME=	pip
PORTVERSION=	26.3
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	devel python
MASTER_SITES=	PYPI
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	github@azsupport.com
COMMENT=	Tool for installing and managing Python packages (of azsupport/ports)
WWW=		https://pip.pypa.io/en/latest/ \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

USES=		cpe python
CPE_VENDOR=	pypa
USE_PYTHON=	autoplist concurrent pep517
PEP517_BUILD_CMD=	${PYTHON_CMD} -m flit_core.wheel
PEP517_BUILD_DEPEND=	${PYTHON_PKGNAMEPREFIX}flit-core>=3.11:devel/py-flit-core@${PY_FLAVOR}

NO_ARCH=	yes

post-patch:
	@${REINPLACE_CMD} -e '/^pip3 = /d' ${WRKSRC}/pyproject.toml
	@${RM} -r ${WRKSRC}/src/pip/_vendor/colorama/tests/

.include <bsd.port.mk>
