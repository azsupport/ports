ONNX Runtime optional: EMBEDDINGS_ONNX (ON, as upstream builds it) downloads the
static ONNX Runtime and turns on the cargo feature onnx; the port builds with it OFF
(upstream has ONNX Runtime for Linux, macOS and Windows only).

--- cmake/build_embeddings.cmake.orig
+++ cmake/build_embeddings.cmake
@@ -91,7 +91,13 @@
 	message ( STATUS "Using MANTICORE_EMBEDDINGS_TARGET_DIR=${MANTICORE_EMBEDDINGS_TARGET_DIR}" )
 	message ( STATUS "Using MANTICORE_EMBEDDINGS_DEPS_DIR=${MANTICORE_EMBEDDINGS_DEPS_DIR}" )
 
-	prepare_embeddings_ort()
+	# ONNX Runtime (the models of HuggingFace that have only ONNX weights): a static
+	# library upstream downloads for Linux, macOS and Windows; EMBEDDINGS_ONNX=OFF
+	# builds without it (the cargo feature onnx)
+	option ( EMBEDDINGS_ONNX "Build the embeddings with ONNX Runtime" ON )
+	if ( EMBEDDINGS_ONNX )
+		prepare_embeddings_ort()
+	endif()
 
 	# Enable platform-specific BLAS acceleration for candle when available.
 	if (DEFINED EMBEDDINGS_CARGO_FEATURES)
@@ -107,6 +113,9 @@
 				list(APPEND EMBEDDINGS_FEATURE_LIST mkl)
 			endif()
 		endif()
+		if ( EMBEDDINGS_ONNX )
+			list(APPEND EMBEDDINGS_FEATURE_LIST onnx)
+		endif()
 		list(JOIN EMBEDDINGS_FEATURE_LIST "," EMBEDDINGS_FEATURES_CSV)
 	endif()
 
