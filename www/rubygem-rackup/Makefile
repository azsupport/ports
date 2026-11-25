# www/rubygem-rackup of azsupport/ports: the official port (Mk/azsupport-official.mk), rackup
# 2.3.1, which www/rubygem-passenger needs (aZ, 20.11.2026).

AZSUPPORT_OFFICIAL=	www/rubygem-rackup

# The package ruby34-rackup (aZ, 21.11.2026: the name with the version first, as
# php84): PKGNAMEPREFIX of Ruby, which USES=gem sets to rubygem- only when it is not
# set; RUN_DEPENDS on the command line of make (.MAKEFLAGS), which the assignment of
# the official Makefile does not replace: the rack of our name and what USES=gem and
# ruby add (gem of devel/ruby-gems, ruby), which the command line keeps out; the
# conflicts of the official port and the official rubygem-rackup (the same files).
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
.MAKEFLAGS:	RUN_DEPENDS="$${RUBY_PKGNAMEPREFIX}rack>=3,3:www/rubygem-rack $${DEPEND_RUBY} \
		$${RUBYGEMBIN}:devel/ruby-gems" CONFLICTS_INSTALL="rubygem-rackup rubygem-rackup21"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
