# devel/rubygem-logger of azsupport/ports: the official port (Mk/az-official.mk), logger
# 1.7.0, which www/rubygem-passenger needs (aZ, 20.11.2026).

AZ_OFFICIAL=	devel/rubygem-logger

# The package ruby34-logger (aZ, 21.11.2026: the name with the version first, as
# php84): PKGNAMEPREFIX of Ruby, which USES=gem sets to rubygem- only when it is not
# set; it conflicts with the official rubygem-logger (the same files).
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
CONFLICTS_INSTALL=	rubygem-logger

.include "${.CURDIR:H:H}/Mk/az-official.mk"
