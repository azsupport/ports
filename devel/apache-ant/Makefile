# devel/apache-ant of azsupport/ports: the official port (Mk/az-official.mk) on
# our java/openjdk17 (aZ, 11.11.2026: one JDK in the build of devel/jna; the
# official package runs on the official OpenJDK 25, which it brings with its
# desktop): JAVA_VERSION 17, and bin/ant runs its java by default (there is no
# javavmwrapper, so no /usr/local/bin/java; JAVACMD still chooses another).

AZ_OFFICIAL=	devel/apache-ant
JAVA_VERSION=	17

# ant.sh of the official port (SUB_FILES, apply-slist: before pre-configure)
pre-configure:
	@${REINPLACE_CMD} -e '/^JAVACMD=/s|"${LOCALBASE}/bin/java"|"${JAVA}"|' ${WRKDIR}/ant.sh
	@${GREP} -q '^JAVACMD="$${JAVACMD:-"${JAVA}"}"$$' ${WRKDIR}/ant.sh || \
		{ ${ECHO_MSG} "ant.sh: no JAVACMD with ${JAVA} by default: $$(${GREP} '^JAVACMD=' ${WRKDIR}/ant.sh)"; ${FALSE}; }

.include "${.CURDIR:H:H}/Mk/az-official.mk"
