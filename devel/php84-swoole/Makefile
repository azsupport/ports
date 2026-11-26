# PECL swoole of ext/swoole of the release tarball of azsupport/php-src:
# its version there (php-src freebsd/pecl.conf)
DISTVERSION=	6.3.0
CATEGORIES=	devel net

MASTERDIR=	${.CURDIR}/../../lang/php84

PKGNAMESUFFIX=	-swoole

# swoole.so never unloaded (-z nodelete): it has thread_local objects with destructors
# (SwooleTG, the std::random_device of its random numbers), which the libc of FreeBSD
# registers for the exit of the thread without holding the module, as glibc does; PHP
# unloads its modules at shutdown, and at the exit the libc skipped them with
# "__cxa_thread_call_dtors: dtr ... from unloaded dso, skipping" on stderr after each
# php run (check-php: runs 45734425567, 45870373659)
LDFLAGS+=	-Wl,-z,nodelete

.include "${MASTERDIR}/Makefile"
