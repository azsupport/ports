# www/nginx-devel-passenger: the Phusion Passenger module of www/nginx-devel of
# azsupport/ports, a package of its own (aZ, 20.11.2026: «nginx-devel-passenger нужен
# обязательно»): Ruby and Rack applications under nginx, with the agent of
# www/rubygem-passenger; the design is in the head of www/nginx-devel/Makefile.
NGINX_AZ_MODULE=	passenger
COMMENT=	Phusion Passenger module for nginx-devel (of azsupport/ports)
# no PIE of the framework (WITH_PIE of tools/make.conf.in): the rake of Passenger builds
# libev with CFLAGS of its own, without -fPIE, and the -pie of LDFLAGS failed its
# configure ("relocation R_X86_64_64 cannot be used against local symbol", run
# 45702768445); the module is a shared object, position independent anyway
PIE_UNSAFE=	the rake of Passenger builds libev without -fPIE
MASTERDIR=	${.CURDIR}/../nginx-devel
.include "${MASTERDIR}/Makefile"
