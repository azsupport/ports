[
{ type: install
  message: <<EOM
The Apache module of PHP 8.3 is libexec/apache24/libphp83.so; it is not
loaded by itself. To load it into an Apache instance (one PHP module per
instance), copy
  etc/apache24/modules.d/280_mod_php83.conf.sample
of the prefix to 280_mod_php83.conf in the same directory, then restart
Apache. The sample makes .php files go to PHP and adds index.php to
DirectoryIndex.

PHP reads etc/php83/php.ini and the ini files of the modules in
etc/php83/conf.d (the packages php83-<module>).
EOM
}
]
