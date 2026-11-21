# www/rubygem-rack of azsupport/ports: the official port (Mk/az-official.mk), Rack
# 3.2.8, which www/rubygem-passenger needs (aZ, 20.11.2026).

AZ_OFFICIAL=	www/rubygem-rack

# The package ruby34-rack (aZ, 21.11.2026: the name with the version first, as php84):
# PKGNAMEPREFIX of Ruby, which USES=gem sets to rubygem- only when it is not set; it
# conflicts with the official rubygem-rack (the same files).
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
CONFLICTS_INSTALL=	rubygem-rack

.include "${.CURDIR:H:H}/Mk/az-official.mk"
