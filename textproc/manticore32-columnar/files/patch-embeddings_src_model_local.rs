The ONNX model (OnnxEmbeddingModel, its session) only with the feature onnx; without
it a model with ONNX weights only gives an error that says so.

--- embeddings/src/model/local.rs.orig
+++ embeddings/src/model/local.rs
@@ -149,17 +149,17 @@
 /// Thread-safe session wrapper with platform-specific strategy:
 /// - Linux/macOS: UnsafeCell for concurrent Run() (ORT C API is thread-safe)
 /// - Windows: Mutex for serialized Run() (Windows ORT has threading issues)
-#[cfg(not(target_os = "windows"))]
+#[cfg(all(feature = "onnx", not(target_os = "windows")))]
 struct SessionWrapper {
     inner: std::cell::UnsafeCell<ort::session::Session>,
 }
 
-#[cfg(not(target_os = "windows"))]
+#[cfg(all(feature = "onnx", not(target_os = "windows")))]
 unsafe impl Sync for SessionWrapper {}
-#[cfg(not(target_os = "windows"))]
+#[cfg(all(feature = "onnx", not(target_os = "windows")))]
 unsafe impl Send for SessionWrapper {}
 
-#[cfg(not(target_os = "windows"))]
+#[cfg(all(feature = "onnx", not(target_os = "windows")))]
 impl SessionWrapper {
     fn new(session: ort::session::Session) -> Self {
         Self {
@@ -172,17 +172,17 @@
     }
 }
 
-#[cfg(target_os = "windows")]
+#[cfg(all(feature = "onnx", target_os = "windows"))]
 struct SessionWrapper {
     inner: Mutex<std::cell::UnsafeCell<ort::session::Session>>,
 }
 
-#[cfg(target_os = "windows")]
+#[cfg(all(feature = "onnx", target_os = "windows"))]
 unsafe impl Sync for SessionWrapper {}
-#[cfg(target_os = "windows")]
+#[cfg(all(feature = "onnx", target_os = "windows"))]
 unsafe impl Send for SessionWrapper {}
 
-#[cfg(target_os = "windows")]
+#[cfg(all(feature = "onnx", target_os = "windows"))]
 impl SessionWrapper {
     fn new(session: ort::session::Session) -> Self {
         Self {
@@ -992,6 +992,7 @@
 
 /// ONNX embedding model using ORT (onnxruntime) for optimized inference.
 /// Uses a single session with concurrent inference via SessionWrapper wrapper.
+#[cfg(feature = "onnx")]
 pub struct OnnxEmbeddingModel {
     session: SessionWrapper,
     tokenizer: Tokenizer,
@@ -1003,6 +1004,7 @@
     pooling: OnnxPooling,
 }
 
+#[cfg(feature = "onnx")]
 impl OnnxEmbeddingModel {
     pub fn new(
         onnx_path: PathBuf,
@@ -1271,6 +1273,7 @@
     T5(T5EmbeddingModel),
     Causal(CausalEmbeddingModel),
     Quantized(QuantizedEmbeddingModel),
+    #[cfg(feature = "onnx")]
     Onnx(OnnxEmbeddingModel),
 }
 
@@ -1302,6 +1305,7 @@
             LocalModel::T5(m) => m.max_input_len = m.max_input_len.min(cap),
             LocalModel::Causal(m) => m.max_input_len = m.max_input_len.min(cap),
             LocalModel::Quantized(m) => m.max_input_len = m.max_input_len.min(cap),
+            #[cfg(feature = "onnx")]
             LocalModel::Onnx(m) => m.max_input_len = m.max_input_len.min(cap),
         }
     }
@@ -1331,8 +1335,20 @@
 
         // Check if this is an ONNX model
         if let Some(onnx_path) = model_info.onnx_path.clone() {
-            let model = OnnxEmbeddingModel::new(onnx_path, model_info, use_gpu)?;
-            return Ok(LocalModel::Onnx(model));
+            #[cfg(feature = "onnx")]
+            {
+                let model = OnnxEmbeddingModel::new(onnx_path, model_info, use_gpu)?;
+                return Ok(LocalModel::Onnx(model));
+            }
+            #[cfg(not(feature = "onnx"))]
+            {
+                return Err(format!(
+                    "{}: the model has ONNX weights only ({}), and this build has no ONNX Runtime (safetensors and GGUF models only)",
+                    model_id,
+                    onnx_path.display()
+                )
+                .into());
+            }
         }
 
         match arch {
@@ -1600,6 +1616,7 @@
             LocalModel::T5(m) => &m.tokenizer,
             LocalModel::Causal(m) => &m.tokenizer,
             LocalModel::Quantized(m) => &m.tokenizer,
+            #[cfg(feature = "onnx")]
             LocalModel::Onnx(m) => &m.tokenizer,
         }
     }
@@ -1612,6 +1629,7 @@
         // count. Model mutexes are taken here, on the caller thread — see `Locked`.
         match self {
             // ONNX manages its own worker count internally — no rayon pool involved.
+            #[cfg(feature = "onnx")]
             LocalModel::Onnx(m) => m.predict_pipelined(texts, threads),
             LocalModel::Bert(m) => {
                 let model = m.model.lock().unwrap();
@@ -1647,6 +1665,7 @@
             LocalModel::T5(m) => m.hidden_size,
             LocalModel::Causal(m) => m.hidden_size,
             LocalModel::Quantized(m) => m.hidden_size,
+            #[cfg(feature = "onnx")]
             LocalModel::Onnx(m) => m.hidden_size,
         }
     }
@@ -1657,6 +1676,7 @@
             LocalModel::T5(m) => m.max_input_len,
             LocalModel::Causal(m) => m.max_input_len,
             LocalModel::Quantized(m) => m.max_input_len,
+            #[cfg(feature = "onnx")]
             LocalModel::Onnx(m) => m.max_input_len,
         }
     }
