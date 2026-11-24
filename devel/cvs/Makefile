# devel/cvs of azsupport/ports: the official port (Mk/az-official.mk), the CVS client
# of the workflows on our runners (openbsd-fetch of azsupport/php-src reads the -stable
# branches of the OpenBSD ports through anoncvs; aZ, 24.11.2026: a port of ours, built
# minimal). Without KERBEROS: the official package needs libgssapi_krb5.so.122,
# libkrb5.so.122, libkrb5support.so.122 and libcom_err.so.122 of the base system, which
# the worlds of our builds and of our servers have not (WITHOUT_KERBEROS), so that it
# did not start there ("Shared object "libgssapi_krb5.so.122" not found, required by
# "cvs""); anoncvs needs none of it (ssh). Without INFO and EXAMPLES; IPV6 excluded, as
# officially.

AZ_OFFICIAL=	devel/cvs
OPTIONS_EXCLUDE=	EXAMPLES INFO IPV6 KERBEROS

.include "${.CURDIR:H:H}/Mk/az-official.mk"
