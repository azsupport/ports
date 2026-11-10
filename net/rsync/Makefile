# net/rsync of azsupport/ports: the official port (Mk/az-official.mk) without
# ICONV (--iconv, the conversion of the names between charsets, which takes
# GNU libiconv); xxhash, lz4 and zstd (checksums, compression) are the libraries
# of the official packages.

AZ_OFFICIAL=	net/rsync
OPTIONS_EXCLUDE=	ICONV

.include "${.CURDIR:H:H}/Mk/az-official.mk"
