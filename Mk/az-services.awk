# Mk/az-services.awk: the services of a package from its plist (Mk/bsd.overlay.mk,
# az-services), a name a line: each rc.d script; php_fpm<NN> for the modules of PHP NN
# (etc/php<NN>/conf.d, lib/php/<API>); nginx for libexec/nginx; apache24 for
# libexec/apache24 (its modules, mod_php<NN>). p: the prefix with a slash at its end.
BEGIN {
	api["20131226"] = "56"; api["20190902"] = "74"; api["20210902"] = "81"
	api["20220829"] = "82"; api["20230831"] = "83"; api["20240924"] = "84"
}
{
	f = $0
	if (f ~ /^@/) {
		if (f !~ /^@[^ \t]+[ \t]+/)
			next
		sub(/^@[^ \t]+[ \t]+/, "", f)
	}
	sub(/[ \t].*$/, "", f)
	if (index(f, p) == 1)
		f = substr(f, length(p) + 1)
	if (f ~ /^etc\/rc\.d\/[^\/]+$/) {
		sub(/^etc\/rc\.d\//, "", f)
		print f
	} else if (f ~ /^etc\/php[0-9][0-9]\/conf\.d\//) {
		print "php_fpm" substr(f, 8, 2)
	} else if (f ~ /^lib\/php\/[0-9]+\//) {
		split(f, a, "/")
		if (a[3] in api)
			print "php_fpm" api[a[3]]
	} else if (f ~ /^libexec\/nginx\//) {
		print "nginx"
	} else if (f ~ /^libexec\/apache24\//) {
		print "apache24"
	}
}
