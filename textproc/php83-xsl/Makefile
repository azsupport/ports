CATEGORIES=	textproc

MASTERDIR=	${.CURDIR}/../../lang/php83

PKGNAMESUFFIX=	-xsl

# as the official port: php_xsl.h of 8.3 includes ../dom/xml_common.h, which is
# not next to ext/xsl in the build of the module (phpize); php83-dom installs it
# as ext/dom/xml_common.h (build.yml 42526293332)
post-patch:
	${REINPLACE_CMD} -e \
		's|#include "../dom/xml_common.h"|#include "ext/dom/xml_common.h"|g' \
		${WRKSRC}/php_xsl.h

.include "${MASTERDIR}/Makefile"
