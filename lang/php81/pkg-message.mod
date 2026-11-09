[
{ type: install
  message: <<EOM
The Apache module of PHP 8.1 is libexec/apache24/libphp81.so; it is not
loaded by itself. To load it into an Apache instance (one PHP module per
instance), copy
  etc/apache24/modules.d/280_mod_php81.conf.sample
of the prefix to 280_mod_php81.conf in the same directory, then restart
Apache. The sample makes .php files go to PHP and adds index.php to
DirectoryIndex.

PHP reads etc/php81/php.ini and the ini files of the modules in
etc/php81/conf.d (the packages php81-<module>).
EOM
}
]
