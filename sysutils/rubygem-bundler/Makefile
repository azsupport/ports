# sysutils/rubygem-bundler of azsupport/ports: the official port (Mk/azsupport-official.mk),
# Bundler 4.0.24 for lang/ruby34, whose port leaves Bundler out (--exclude of
# lib/bundler* there): the command bundle, which installs the gems of a Gemfile
# into a directory of the application (bundle config set path), and bundler/setup,
# through which Phusion Passenger loads an application with a Gemfile (aZ,
# 20.11.2026). No options.

AZSUPPORT_OFFICIAL=	sysutils/rubygem-bundler

# The package ruby34-bundler (aZ, 21.11.2026: the name with the version first, as
# php84): PKGNAMEPREFIX of Ruby, which USES=gem sets to rubygem- only when it is not
# set; the conflicts on the command line of make (.MAKEFLAGS), which the assignment of
# the official Makefile does not replace: its go-tools (bin/bundle) and the official
# rubygem-bundler (the same files).
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
.MAKEFLAGS:	CONFLICTS_INSTALL="go-tools rubygem-bundler"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
