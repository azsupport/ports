galera and wsrep-API from the sources of the port (GALERA_SOURCE_DIR and
WSREP_SOURCE_DIR, distfiles of the port): no download and no checksum of a zip of
GitHub (cmake/galera-local.cmake.in, from files/).

--- cmake/GetGALERA.cmake.orig
+++ cmake/GetGALERA.cmake
@@ -59,10 +59,17 @@
 endif ()
 
 # not found. Populate and build cache package for now and future usage.
-select_nearest_url ( GALERA_PLACE "galera" ${GALERA_BUNDLE} ${GALERA_GITHUB} )
-select_nearest_url ( WSREP_PLACE "wsrep" ${WSREP_BUNDLE} ${WSREP_GITHUB} ) # WSREP_PATH provides path to galera-imported for build
+if (GALERA_SOURCE_DIR AND WSREP_SOURCE_DIR) # the sources of galera and wsrep-API in place: no download
+	set ( GALERA_PLACE "${GALERA_SOURCE_DIR}" )
+	set ( WSREP_PLACE "${WSREP_SOURCE_DIR}" )
+	set ( GALERA_TEMPLATE galera-local.cmake.in )
+else ()
+	select_nearest_url ( GALERA_PLACE "galera" ${GALERA_BUNDLE} ${GALERA_GITHUB} )
+	select_nearest_url ( WSREP_PLACE "wsrep" ${WSREP_BUNDLE} ${WSREP_GITHUB} ) # WSREP_PATH provides path to galera-imported for build
+	set ( GALERA_TEMPLATE galera-imported.cmake.in )
+endif ()
 get_build ( GALERA_BUILD galera )
-configure_file ( ${MANTICORE_SOURCE_DIR}/cmake/galera-imported.cmake.in galera-build/CMakeLists.txt @ONLY ) # consumes WSREP_PLACE, WSREP_SRC_MD5, GALERA_PLACE, GALERA_SRC_MD5, GALERA_REV, GALERA_BUILD
+configure_file ( ${MANTICORE_SOURCE_DIR}/cmake/${GALERA_TEMPLATE} galera-build/CMakeLists.txt @ONLY ) # consumes WSREP_PLACE, WSREP_SRC_MD5, GALERA_PLACE, GALERA_SRC_MD5, GALERA_REV, GALERA_BUILD
 execute_process ( COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" . WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/galera-build )
 execute_process ( COMMAND ${CMAKE_COMMAND} --build . WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/galera-build )
 
