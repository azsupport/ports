The flags of the port (those of the make.conf of the build: -O3, the -march of the
level, the protections of the compiler) for the plain build and for the
dependencies: upstream adds -march=x86-64-v2 to the plain build after the flags of
the port (the last one wins) and gives the dependencies the -march of the build
alone in place of CFLAGS and CXXFLAGS. The builds with AVX keep their -march, after
ours.

--- cmake/update_bundle.cmake.orig
+++ cmake/update_bundle.cmake
@@ -134,7 +134,7 @@
 		if (MSVC OR CLANG_CL)
 			set ( ${RESULT} "/arch:AVX" PARENT_SCOPE )
 		else ()
-			set ( ${RESULT} "-march=x86-64-v2" PARENT_SCOPE )
+			# the -march of the level of the build (CPUTYPE of the port) stays
 		endif ()
 	endif ()
 endfunction ( )
@@ -142,8 +142,8 @@
 function ( external_build module MODULE_SRC_NAME MODULE_BUILD_NAME )
 	get_avx_flags ( FLAGS )
 	if (FLAGS)
-		set ( ENV{CXXFLAGS} ${FLAGS} )
-		set ( ENV{CFLAGS} ${FLAGS} )
+		set ( ENV{CXXFLAGS} "$ENV{CXXFLAGS} ${FLAGS}" )
+		set ( ENV{CFLAGS} "$ENV{CFLAGS} ${FLAGS}" )
 	endif ()
 
 	set ( CMAKE_ARGS "" )
