CATEGORIES=	devel

MASTERDIR=	${.CURDIR}/../../lang/php74

PKGNAMESUFFIX=	-intl

# ICU 76 of the package az needs C++17 (the port: c++11-lib, gnu++11)
USES=		compiler:c++17-lang

CPPFLAGS+=	-DU_USING_ICU_NAMESPACE=1

TEST_TARGET=	test

.include "${MASTERDIR}/Makefile"
