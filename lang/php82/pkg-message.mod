[
{ type: install
  message: <<EOM
The Apache module of PHP 8.2 is libexec/apache24/libphp82.so; it is not
loaded by itself. To load it into an Apache instance (one PHP module per
instance), copy
  etc/apache24/modules.d/280_mod_php82.conf.sample
of the prefix to 280_mod_php82.conf in the same directory, then restart
Apache. The sample makes .php files go to PHP and adds index.php to
DirectoryIndex.

PHP reads etc/php82/php.ini and the ini files of the modules in
etc/php82/conf.d (the packages php82-<module>).
EOM
}
]
