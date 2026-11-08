ICU 75 and later (ICU 76 of the package az) need C++17. PHP 7.4 asks for C++11,
and its -std=c++11 comes after CXXFLAGS on the command line (USES=compiler:c++17-lang
of the Makefile), so it won (build.yml 42519391339: no template is_convertible_v in
std). PHP 8.1 and later pick C++17 for ICU 74 and later themselves.

--- config.m4.orig
+++ config.m4
@@ -83,7 +83,7 @@
     breakiterator/codepointiterator_methods.cpp"
 
   PHP_REQUIRE_CXX()
-  PHP_CXX_COMPILE_STDCXX(11, mandatory, PHP_INTL_STDCXX)
+  PHP_CXX_COMPILE_STDCXX(17, mandatory, PHP_INTL_STDCXX)
   PHP_INTL_CXX_FLAGS="$INTL_COMMON_FLAGS $PHP_INTL_STDCXX $ICU_CXXFLAGS"
   if test "$ext_shared" = "no"; then
     PHP_ADD_SOURCES(PHP_EXT_DIR(intl), $PHP_INTL_CXX_SOURCES, $PHP_INTL_CXX_FLAGS)
