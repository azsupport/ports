The flags of the port (those of the make.conf of the build: -O3, the -march of the
level, the protections of the compiler) for the plain build and for the
dependencies: upstream adds -march=x86-64-v2 to the plain build after the flags of
the port (the last one wins) and gives the dependencies the -march of the build
alone in place of CFLAGS and CXXFLAGS. The builds with AVX keep their -march, after
ours, but for _avx2 at the level x86-64-v4: its -march=x86-64-v3 would take down to
x86-64-v3 the library searchd loads on every CPU with AVX2, so on every CPU of the
level.

--- cmake/update_bundle.cmake.orig
+++ cmake/update_bundle.cmake
@@ -126,7 +126,8 @@
 		message ( STATUS "Add AVX2 flags to compiler flags for ${CMAKE_SYSTEM_PROCESSOR} arch" )
 		if (MSVC OR CLANG_CL)
 			set ( ${RESULT} "/arch:AVX2" PARENT_SCOPE )
-		else()
+		# the -march of the level of the build stays when it is x86-64-v4 (AVX2 and more)
+		elseif (NOT "$ENV{CXXFLAGS} ${CMAKE_CXX_FLAGS}" MATCHES "-march=x86-64-v4")
 			set ( ${RESULT} "-march=x86-64-v3" PARENT_SCOPE )
 		endif()
 	else ()
@@ -134,7 +135,7 @@
 		if (MSVC OR CLANG_CL)
 			set ( ${RESULT} "/arch:AVX" PARENT_SCOPE )
 		else ()
-			set ( ${RESULT} "-march=x86-64-v2" PARENT_SCOPE )
+			# the -march of the level of the build (CPUTYPE of the port) stays
 		endif ()
 	endif ()
 endfunction ( )
@@ -142,8 +143,8 @@
 function ( external_build module MODULE_SRC_NAME MODULE_BUILD_NAME )
 	get_avx_flags ( FLAGS )
 	if (FLAGS)
-		set ( ENV{CXXFLAGS} ${FLAGS} )
-		set ( ENV{CFLAGS} ${FLAGS} )
+		set ( ENV{CXXFLAGS} "$ENV{CXXFLAGS} ${FLAGS}" )
+		set ( ENV{CFLAGS} "$ENV{CFLAGS} ${FLAGS}" )
 	endif ()
 
 	set ( CMAKE_ARGS "" )
