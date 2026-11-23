# security/stunnel of azsupport/ports: the official port (Mk/az-official.mk), the TLS
# wrapper of plain network services, stunnel 5.82 (aZ, 19.11.2026: «stunnel добавь в
# наши порты ещё»), with the options of aZ (23.11.2026: «да»): IPV6 and the PTHREAD
# model of threads (the defaults of the official port); without FIPS (the FIPS mode of
# OpenSSL), LIBWRAP (TCP wrappers: none in his configurations), the FORK and UCONTEXT
# models, DOCS and EXAMPLES (the make.conf of the builds); the OpenSSL of the base
# system, its rc.d script stunnel, the user and the group stunnel.

AZ_OFFICIAL=	security/stunnel
OPTIONS_EXCLUDE=	FIPS FORK LIBWRAP UCONTEXT

.include "${.CURDIR:H:H}/Mk/az-official.mk"
