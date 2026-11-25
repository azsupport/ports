# security/stunnel of azsupport/ports: the official port (Mk/azsupport-official.mk), the TLS
# wrapper of plain network services, stunnel 5.82 (aZ, 19.11.2026: «stunnel добавь в
# наши порты ещё»), with the options of aZ (23.11.2026: «да»): IPV6 and the PTHREAD
# model of threads (the defaults of the official port); without FIPS (the FIPS mode of
# OpenSSL), LIBWRAP (TCP wrappers: none in his configurations), the FORK and UCONTEXT
# models, DOCS and EXAMPLES (the make.conf of the builds); the OpenSSL of the base
# system, its rc.d script stunnel, the user and the group stunnel; no bin/stunnel3.

AZSUPPORT_OFFICIAL=	security/stunnel
OPTIONS_EXCLUDE=	FIPS FORK LIBWRAP UCONTEXT

# no bin/stunnel3 (aZ, 23.11.2026: «убирай»): the wrapper of the command line of
# stunnel 3.x, a Perl script, and Perl is for the build alone (USE_PERL5=build of the
# official port), so on the servers it could not run. Out of the stage and the plist
# (generate-plist comes before post-stage); defined before the official Makefile, so
# that bsd.port.mk runs it in the stage
post-stage:
	${RM} ${STAGEDIR}${PREFIX}/bin/stunnel3
	@${SED} -i '' -e '/^bin\/stunnel3$$/d' ${TMPPLIST}

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
