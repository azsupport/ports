The flags of the port (those of the make.conf of the build: -O3, the -march of the
level, the protections of the compiler) for the plain build and for the
dependencies: upstream adds -march=x86-64-v2 to the plain build after the flags of
the port (the last one wins) and gives the dependencies the -march of the build
alone in place of CFLAGS and CXXFLAGS. The builds with AVX keep their -march, after
ours, but for _avx2 at the level x86-64-v4: its -march=x86-64-v3 would take down to
x86-64-v3 the library searchd loads on a CPU of the level without AVX512-VPOPCNTDQ,
which _avx512 (-march=x86-64-v4 -mavx512vpopcntdq) needs.

--- cmake/update_bundle.cmake.orig
+++ cmake/update_bundle.cmake
@@ -135,7 +135,8 @@
 		message ( STATUS "Add AVX2 flags to compiler flags for ${CMAKE_SYSTEM_PROCESSOR} arch" )
 		if (MSVC OR CLANG_CL)
 			set ( ${RESULT} "/arch:AVX2" PARENT_SCOPE )
-		else()
+		# the -march of the level of the build stays when it is x86-64-v4 (AVX2 and more)
+		elseif (NOT "$ENV{CXXFLAGS} ${CMAKE_CXX_FLAGS}" MATCHES "-march=x86-64-v4")
 			set ( ${RESULT} "-march=x86-64-v3" PARENT_SCOPE )
 		endif()
 	else ()
@@ -143,7 +144,7 @@
 		if (MSVC OR CLANG_CL)
 			set ( ${RESULT} "/arch:AVX" PARENT_SCOPE )
 		else ()
-			set ( ${RESULT} "-march=x86-64-v2" PARENT_SCOPE )
+			# the -march of the level of the build (CPUTYPE of the port) stays
 		endif ()
 	endif ()
 endfunction ( )
@@ -152,8 +153,8 @@
 	get_avx_flags ( FLAGS )
 	if (FLAGS)
 		string ( REPLACE ";" " " FLAGS_STR "${FLAGS}" )
-		set ( ENV{CXXFLAGS} "${FLAGS_STR}" )
-		set ( ENV{CFLAGS} "${FLAGS_STR}" )
+		set ( ENV{CXXFLAGS} "$ENV{CXXFLAGS} ${FLAGS_STR}" )
+		set ( ENV{CFLAGS} "$ENV{CFLAGS} ${FLAGS_STR}" )
 	endif ()
 
 	set ( CMAKE_ARGS "" )
