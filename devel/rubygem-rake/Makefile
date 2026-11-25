# devel/rubygem-rake of azsupport/ports: the official port (Mk/azsupport-official.mk), rake
# 13.4.2, which www/rubygem-passenger needs to build and to run, and
# www/nginx-devel-passenger to build (aZ, 20.11.2026).

AZSUPPORT_OFFICIAL=	devel/rubygem-rake

# The package ruby34-rake (aZ, 21.11.2026: the name with the version first, as php84):
# PKGNAMEPREFIX of Ruby, which USES=gem sets to rubygem- only when it is not set; it
# conflicts with the official rubygem-rake (the same files).
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
CONFLICTS_INSTALL=	rubygem-rake

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
