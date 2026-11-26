# textproc/manticore32 of azsupport/ports (aZ, 16.11.2026: Manticore Search 14 and the
# current line, one of the two installed; 20.11.2026: «manticore32 уже вышла, так что на
# неё переходи, а manticore31 удаляем (нигде ещё не ставил)»): Manticore Search 32.1.12 of
# 26.11.2026, the current line (upstream fixes no older line: a release is a tag of its
# master; after 32.1.6: the permissions of the tables in the HTTP API compatible with
# Elasticsearch, the NULLs of a JOIN, the terms aggregation of mixed numeric JSON arrays;
# 32.1.11: the crashes of indexer on the field lengths of an SQL source and of searchd
# after ATTACH, the real field lengths in the secondary index of a plain table; 32.1.12:
# the version of Buddy alone, not built here (aZ, 26.11.2026: «бери сейчас»); cmake/ and
# the dependencies as in 32.1.6). A slave of textproc/manticore14 (its head says what the build is: Galera, the
# libraries, the patches, the rc.d script with profiles, the sample, the user); here
# what the line 32 has of its own: cctz 8ca8e32, nlohmann/json 3.12.0 (cmake/ of 32.1.12
# is that of 31.0.24), and the API of columnar from its submodule mcl (columnar 12f86b42
# of 16.11.2026, 14.5.8 and two commits; MCL_LOCAL_RUNTIME=OFF: the libraries are
# textproc/manticore32-columnar).

DISTVERSION=	32.1.12
PKGNAMESUFFIX=	32

MC_TUPLES=	manticoresoftware:cctz:8ca8e325cb3d8a0b768f7530d0e31a907982c6d4:cctz/freebsd-deps/cctz \
		nlohmann:json:v3.12.0:nljson/freebsd-deps/nljson \
		manticoresoftware:columnar:12f86b4299dcef1495972838b76931bf46e4426f:mcl/mcl
MC_COLUMNAR_ENV=
MC_COLUMNAR_ARGS=	-DMCL_LOCAL_RUNTIME=OFF
CONFLICTS_INSTALL=	manticore14

MASTERDIR=	${.CURDIR}/../manticore14
DESCR=		${.CURDIR}/pkg-descr
DISTINFO_FILE=	${.CURDIR}/distinfo

.include "${MASTERDIR}/Makefile"
