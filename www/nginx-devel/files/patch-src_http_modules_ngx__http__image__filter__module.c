The watermark of the image_filter module of Intaro
(https://github.com/intaro/nginx-image-filter-watermark, commit 62d1468 of 18.01.2019,
MIT), in the place of their whole file, which aZ put over that of nginx for years (aZ,
17.11.2026: «надо портировать улучшения из этого файла и при это проверить на возможные
уязвимости»): their change of the image_filter of nginx 1.11.6 (nginx commit 9ec0b1fe)
brought to that of nginx 1.31.8, with the same directives:

    image_filter watermark;            ("image_filter watermark W H" too, as theirs)
    image_filter_watermark path;       (variables allowed)
    image_filter_watermark_position    top-left | top-right | bottom-left |
                                       bottom-right (the default) | top-center |
                                       bottom-center | left-center | right-center |
                                       center-center | center-random;
    image_filter_watermark_width_from  pixels;
    image_filter_watermark_height_from pixels;

a PNG watermark with its alpha, 10 pixels from the edges, merged at 75%, a GIF or PNG
source put on white first; with resize, crop and rotate too; image_filter_watermark and
image_filter_watermark_position are not inherited, as theirs. The output is byte for
byte that of their file wherever theirs works (JPEG, PNG, GIF, WebP, every position,
resize, crop, rotate). Fixed:
- the path and the position of a request were written into the configuration of the
  location, in memory of the request: with no image_filter_watermark_position the next
  request read the default position from freed memory (valgrind: invalid read in
  ngx_cpystrn), and the watermark could land in the top left corner;
- a watermark file missing, or an empty path: fclose(NULL), the worker crashed; now an
  error in the log and the image without the watermark (an empty path: the image as it
  is, so a variable can turn the watermark off);
- a watermark file not PNG: gdImageDestroy(NULL), the worker crashed; now an error in
  the log and the image without the watermark;
- "image_filter rotate" with "image_filter watermark" on an image under the thresholds:
  the source destroyed twice, the worker crashed; now the image rotated;
- a variable of the path or position that failed: an uninitialized value; now 415;
- the images of libgd not checked for NULL; image_filter_watermark_width_from inherited
  the height; the thresholds compared with the size before crop, now that of the output
  (as their README says); rand() without a seed, now ngx_random().

--- src/http/modules/ngx_http_image_filter_module.c.orig
+++ src/http/modules/ngx_http_image_filter_module.c
@@ -18,6 +18,7 @@
 #define NGX_HTTP_IMAGE_RESIZE    3
 #define NGX_HTTP_IMAGE_CROP      4
 #define NGX_HTTP_IMAGE_ROTATE    5
+#define NGX_HTTP_IMAGE_WATERMARK 6
 
 
 #define NGX_HTTP_IMAGE_START     0
@@ -49,12 +50,17 @@
     ngx_flag_t                   transparency;
     ngx_flag_t                   interlace;
 
+    ngx_int_t                    watermark_width_from;
+    ngx_int_t                    watermark_height_from;
+
     ngx_http_complex_value_t    *wcv;
     ngx_http_complex_value_t    *hcv;
     ngx_http_complex_value_t    *acv;
     ngx_http_complex_value_t    *jqcv;
     ngx_http_complex_value_t    *wqcv;
     ngx_http_complex_value_t    *shcv;
+    ngx_http_complex_value_t    *wmcv;
+    ngx_http_complex_value_t    *wmpcv;
 
     size_t                       buffer_size;
 } ngx_http_image_filter_conf_t;
@@ -75,6 +81,9 @@
     ngx_uint_t                   phase;
     ngx_uint_t                   type;
     ngx_uint_t                   force;
+
+    ngx_str_t                    watermark;
+    ngx_str_t                    watermark_position;
 } ngx_http_image_filter_ctx_t;
 
 
@@ -99,7 +108,11 @@
     int colors);
 static u_char *ngx_http_image_out(ngx_http_request_t *r, ngx_uint_t type,
     gdImagePtr img, int *size);
+static gdImagePtr ngx_http_image_watermark(ngx_http_request_t *r,
+    ngx_http_image_filter_ctx_t *ctx, gdImagePtr dst);
 static void ngx_http_image_cleanup(void *data);
+static ngx_int_t ngx_http_image_filter_get_str(ngx_http_request_t *r,
+    ngx_http_complex_value_t *cv, ngx_str_t *value);
 static ngx_uint_t ngx_http_image_filter_get_value(ngx_http_request_t *r,
     ngx_http_complex_value_t *cv, ngx_uint_t v);
 static ngx_uint_t ngx_http_image_filter_value(ngx_str_t *value);
@@ -170,6 +183,34 @@
       offsetof(ngx_http_image_filter_conf_t, buffer_size),
       NULL },
 
+    { ngx_string("image_filter_watermark"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_http_set_complex_value_slot,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_image_filter_conf_t, wmcv),
+      NULL },
+
+    { ngx_string("image_filter_watermark_position"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_http_set_complex_value_slot,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_image_filter_conf_t, wmpcv),
+      NULL },
+
+    { ngx_string("image_filter_watermark_height_from"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_conf_set_num_slot,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_image_filter_conf_t, watermark_height_from),
+      NULL },
+
+    { ngx_string("image_filter_watermark_width_from"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_conf_set_num_slot,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_image_filter_conf_t, watermark_width_from),
+      NULL },
+
       ngx_null_command
 };
 
@@ -552,6 +593,34 @@
         return ngx_http_image_resize(r, ctx);
     }
 
+    if (conf->wmcv) {
+
+        if (ngx_http_image_filter_get_str(r, conf->wmcv, &ctx->watermark)
+            != NGX_OK)
+        {
+            return NULL;
+        }
+
+        if (conf->wmpcv == NULL) {
+            ngx_str_set(&ctx->watermark_position, "bottom-right");
+
+        } else if (ngx_http_image_filter_get_str(r, conf->wmpcv,
+                                                 &ctx->watermark_position)
+                   != NGX_OK)
+        {
+            return NULL;
+        }
+    }
+
+    if (conf->filter == NGX_HTTP_IMAGE_WATERMARK) {
+
+        if (ctx->watermark.len == 0) {
+            return ngx_http_image_asis(r, ctx);
+        }
+
+        return ngx_http_image_resize(r, ctx);
+    }
+
     ctx->max_width = ngx_http_image_filter_get_value(r, conf->wcv, conf->width);
     if (ctx->max_width == 0) {
         return NULL;
@@ -567,7 +636,8 @@
         && ctx->width <= ctx->max_width
         && ctx->height <= ctx->max_height
         && ctx->angle == 0
-        && !ctx->force)
+        && !ctx->force
+        && ctx->watermark.len == 0)
     {
         return ngx_http_image_asis(r, ctx);
     }
@@ -844,7 +914,8 @@
     if (!ctx->force
         && ctx->angle == 0
         && (ngx_uint_t) sx <= ctx->max_width
-        && (ngx_uint_t) sy <= ctx->max_height)
+        && (ngx_uint_t) sy <= ctx->max_height
+        && ctx->watermark.len == 0)
     {
         gdImageDestroy(src);
         return ngx_http_image_asis(r, ctx);
@@ -894,8 +965,9 @@
 
         resize = 1;
 
-    } else if (conf->filter == NGX_HTTP_IMAGE_ROTATE) {
-
+    } else if (conf->filter == NGX_HTTP_IMAGE_ROTATE
+               || conf->filter == NGX_HTTP_IMAGE_WATERMARK)
+    {
         resize = 0;
 
     } else { /* NGX_HTTP_IMAGE_CROP */
@@ -1043,6 +1115,21 @@
         gdImageColorTransparent(dst, gdImageColorExact(dst, red, green, blue));
     }
 
+    if (ctx->watermark.len) {
+
+        if (gdImageSX(dst) >= conf->watermark_width_from
+            && gdImageSY(dst) >= conf->watermark_height_from)
+        {
+            dst = ngx_http_image_watermark(r, ctx, dst);
+
+        } else if (conf->filter == NGX_HTTP_IMAGE_WATERMARK
+                   && ctx->angle == 0)
+        {
+            gdImageDestroy(dst);
+            return ngx_http_image_asis(r, ctx);
+        }
+    }
+
     sharpen = ngx_http_image_filter_get_value(r, conf->shcv, conf->sharpen);
     if (sharpen > 0) {
         gdImageSharpen(dst, sharpen);
@@ -1090,6 +1177,149 @@
 
 
 static gdImagePtr
+ngx_http_image_watermark(ngx_http_request_t *r,
+    ngx_http_image_filter_ctx_t *ctx, gdImagePtr dst)
+{
+    int          dx, dy, wx, wy, ox, oy;
+    FILE        *file;
+    u_char      *pos;
+    gdImagePtr   mark, mix, white, flat;
+
+    file = fopen((const char *) ctx->watermark.data, "r");
+
+    if (file == NULL) {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, ngx_errno,
+                      "fopen(\"%s\") failed", ctx->watermark.data);
+        return dst;
+    }
+
+    mark = gdImageCreateFromPng(file);
+
+    fclose(file);
+
+    if (mark == NULL) {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                      "watermark file \"%s\" is not PNG",
+                      ctx->watermark.data);
+        return dst;
+    }
+
+    dx = gdImageSX(dst);
+    dy = gdImageSY(dst);
+    wx = gdImageSX(mark);
+    wy = gdImageSY(mark);
+
+    pos = ctx->watermark_position.data;
+
+    if (ngx_strcmp(pos, "bottom-right") == 0) {
+        ox = dx - wx - 10;
+        oy = dy - wy - 10;
+
+    } else if (ngx_strcmp(pos, "top-left") == 0) {
+        ox = 10;
+        oy = 10;
+
+    } else if (ngx_strcmp(pos, "top-right") == 0) {
+        ox = dx - wx - 10;
+        oy = 10;
+
+    } else if (ngx_strcmp(pos, "bottom-left") == 0) {
+        ox = 10;
+        oy = dy - wy - 10;
+
+    } else if (ngx_strcmp(pos, "top-center") == 0) {
+        ox = dx / 2 - wx / 2;
+        oy = 10;
+
+    } else if (ngx_strcmp(pos, "bottom-center") == 0) {
+        ox = dx / 2 - wx / 2;
+        oy = dy - wy - 10;
+
+    } else if (ngx_strcmp(pos, "left-center") == 0) {
+        ox = 10;
+        oy = dy / 2 - wy / 2;
+
+    } else if (ngx_strcmp(pos, "right-center") == 0) {
+        ox = dx - wx - 10;
+        oy = dy / 2 - wy / 2;
+
+    } else if (ngx_strcmp(pos, "center-center") == 0) {
+        ox = dx / 2 - wx / 2;
+        oy = dy / 2 - wy / 2;
+
+    } else if (ngx_strcmp(pos, "center-random") == 0) {
+        ox = dx / 2 - wx / 2;
+        oy = dy / 2 - wy / 2;
+
+        if (ngx_random() & 1) {
+            ox -= (int) (ngx_random() % 15);
+            oy += (int) (ngx_random() % 15);
+
+        } else {
+            ox += (int) (ngx_random() % 15);
+            oy -= (int) (ngx_random() % 15);
+        }
+
+    } else {
+        ox = 0;
+        oy = 0;
+    }
+
+    mix = gdImageCreateTrueColor(wx, wy);
+    if (mix == NULL) {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                      "gdImageCreateTrueColor() failed");
+        gdImageDestroy(mark);
+        return dst;
+    }
+
+    if (ctx->type == NGX_HTTP_IMAGE_GIF || ctx->type == NGX_HTTP_IMAGE_PNG) {
+
+        /* a transparent source on a white background */
+
+        white = gdImageCreateTrueColor(dx, dy);
+        flat = gdImageCreateTrueColor(dx, dy);
+
+        if (white == NULL || flat == NULL) {
+            ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                          "gdImageCreateTrueColor() failed");
+
+            if (white) {
+                gdImageDestroy(white);
+            }
+
+            if (flat) {
+                gdImageDestroy(flat);
+            }
+
+            gdImageDestroy(mix);
+            gdImageDestroy(mark);
+            return dst;
+        }
+
+        gdImageFill(white, 0, 0, gdImageColorAllocate(white, 255, 255, 255));
+        gdImageCopy(flat, white, 0, 0, 0, 0, dx, dy);
+        gdImageCopy(flat, dst, 0, 0, 0, 0, dx, dy);
+        gdImageCopyMerge(white, flat, 0, 0, 0, 0, dx, dy, 100);
+
+        gdImageDestroy(dst);
+        gdImageDestroy(flat);
+
+        dst = white;
+    }
+
+    gdImageCopy(mix, dst, 0, 0, ox, oy, wx, wy);
+    gdImageCopy(mix, mark, 0, 0, 0, 0, wx, wy);
+    gdImageCopyMerge(dst, mix, ox, oy, 0, 0, wx, wy, 75);
+
+    gdImageDestroy(mix);
+    gdImageDestroy(mark);
+
+    return dst;
+}
+
+
+static gdImagePtr
 ngx_http_image_source(ngx_http_request_t *r, ngx_http_image_filter_ctx_t *ctx)
 {
     char        *failed;
@@ -1253,6 +1483,27 @@
 }
 
 
+static ngx_int_t
+ngx_http_image_filter_get_str(ngx_http_request_t *r,
+    ngx_http_complex_value_t *cv, ngx_str_t *value)
+{
+    ngx_str_t  val;
+
+    if (ngx_http_complex_value(r, cv, &val) != NGX_OK) {
+        return NGX_ERROR;
+    }
+
+    value->data = ngx_pnalloc(r->pool, val.len + 1);
+    if (value->data == NULL) {
+        return NGX_ERROR;
+    }
+
+    value->len = ngx_cpystrn(value->data, val.data, val.len + 1) - value->data;
+
+    return NGX_OK;
+}
+
+
 static ngx_uint_t
 ngx_http_image_filter_value(ngx_str_t *value)
 {
@@ -1294,6 +1545,8 @@
      *     conf->jqcv = NULL;
      *     conf->wqcv = NULL;
      *     conf->shcv = NULL;
+     *     conf->wmcv = NULL;
+     *     conf->wmpcv = NULL;
      */
 
     conf->filter = NGX_CONF_UNSET_UINT;
@@ -1303,6 +1556,8 @@
     conf->transparency = NGX_CONF_UNSET;
     conf->interlace = NGX_CONF_UNSET;
     conf->buffer_size = NGX_CONF_UNSET_SIZE;
+    conf->watermark_width_from = NGX_CONF_UNSET;
+    conf->watermark_height_from = NGX_CONF_UNSET;
 
     return conf;
 }
@@ -1365,6 +1620,16 @@
     ngx_conf_merge_size_value(conf->buffer_size, prev->buffer_size,
                               1 * 1024 * 1024);
 
+    /*
+     * image_filter_watermark and image_filter_watermark_position
+     * are not inherited, as in the module of Intaro
+     */
+
+    ngx_conf_merge_value(conf->watermark_width_from,
+                         prev->watermark_width_from, 0);
+    ngx_conf_merge_value(conf->watermark_height_from,
+                         prev->watermark_height_from, 0);
+
     return NGX_CONF_OK;
 }
 
@@ -1394,6 +1659,9 @@
         } else if (ngx_strcmp(value[i].data, "size") == 0) {
             imcf->filter = NGX_HTTP_IMAGE_SIZE;
 
+        } else if (ngx_strcmp(value[i].data, "watermark") == 0) {
+            imcf->filter = NGX_HTTP_IMAGE_WATERMARK;
+
         } else {
             goto failed;
         }
@@ -1451,6 +1719,9 @@
     } else if (ngx_strcmp(value[i].data, "crop") == 0) {
         imcf->filter = NGX_HTTP_IMAGE_CROP;
 
+    } else if (ngx_strcmp(value[i].data, "watermark") == 0) {
+        imcf->filter = NGX_HTTP_IMAGE_WATERMARK;
+
     } else {
         goto failed;
     }
