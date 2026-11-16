# textproc/manticore31 of azsupport/ports (aZ, 16.11.2026: Manticore Search 14 and 31,
# one of the two installed): Manticore Search 31.0.24 of 13.11.2026, the current line.
# A slave of textproc/manticore14 (its head says what the build is: Galera, the
# libraries, the patches, the rc.d script with profiles, the sample, the user); here
# what the line 31 has of its own: cctz 8ca8e32, nlohmann/json 3.12.0, and the API of
# columnar from its submodule mcl (columnar b5ffd362 of 03.11.2026, after 14.5.6;
# MCL_LOCAL_RUNTIME=OFF: the libraries are textproc/manticore31-columnar).

DISTVERSION=	31.0.24
PKGNAMESUFFIX=	31

MC_TUPLES=	manticoresoftware:cctz:8ca8e325cb3d8a0b768f7530d0e31a907982c6d4:cctz/freebsd-deps/cctz \
		nlohmann:json:v3.12.0:nljson/freebsd-deps/nljson \
		manticoresoftware:columnar:b5ffd36220fdc92b5b06ea706ee4ab22266d2d6f:mcl/mcl
MC_COLUMNAR_ENV=
MC_COLUMNAR_ARGS=	-DMCL_LOCAL_RUNTIME=OFF
CONFLICTS_INSTALL=	manticore14

MASTERDIR=	${.CURDIR}/../manticore14
DESCR=		${.CURDIR}/pkg-descr
DISTINFO_FILE=	${.CURDIR}/distinfo
PLIST=		${.CURDIR}/pkg-plist

.include "${MASTERDIR}/Makefile"
