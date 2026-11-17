mp4_limit_rate and mp4_limit_rate_after of Angie (aZ, 17.11.2026: «замена стандартного
mp4 модуля на его файл из agnie ... там есть крутые фичи из nginx plus по ограничению
скорости»), the directives of the mp4 module of NGINX Plus: the rate of the response
limited to a factor (on: 1.1) of the average bitrate of the file, after the playback
time given (60s by default). The change of src/http/modules/ngx_http_mp4_module.c of
Angie 1.12.4 (https://github.com/webserver-llc/angie, tag Angie-1.12.4, BSD-2-Clause as
nginx) against that of nginx 1.31.8: its file is that of nginx with these directives,
and NULL in the place of ngx_conf_size_nonzero_post of mp4_buffer_size and
mp4_max_buffer_size, which nginx has and Angie has not (the check that they are not
zero): that is kept, so this file is the one of Angie with the check of nginx.

--- src/http/modules/ngx_http_mp4_module.c.orig
+++ src/http/modules/ngx_http_mp4_module.c
@@ -1,5 +1,6 @@
 
 /*
+ * Copyright (C) 2023 Web Server LLC
  * Copyright (C) Igor Sysoev
  * Copyright (C) Nginx, Inc.
  */
@@ -45,6 +46,8 @@
 typedef struct {
     size_t                buffer_size;
     size_t                max_buffer_size;
+    ngx_uint_t            limit_rate;
+    ngx_msec_t            limit_rate_after;
     ngx_flag_t            start_key_frame;
 } ngx_http_mp4_conf_t;
 
@@ -156,9 +159,11 @@
 
     off_t                 offset;
     off_t                 end;
+    off_t                 mdat_length;
     off_t                 content_length;
     ngx_uint_t            start;
     ngx_uint_t            length;
+    uint64_t              duration;
     uint32_t              timescale;
     ngx_http_request_t   *request;
     ngx_array_t           trak;
@@ -260,6 +265,7 @@
 
 
 static ngx_int_t ngx_http_mp4_handler(ngx_http_request_t *r);
+static void ngx_http_mp4_set_limit(ngx_http_mp4_file_t *mp4);
 static ngx_int_t ngx_http_mp4_atofp(u_char *line, size_t n, size_t point);
 
 static ngx_int_t ngx_http_mp4_process(ngx_http_mp4_file_t *mp4);
@@ -356,6 +362,8 @@
     ngx_http_mp4_trak_t *trak, off_t adjustment);
 
 static char *ngx_http_mp4(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);
+static char *ngx_http_mp4_limit_rate(ngx_conf_t *cf, ngx_command_t *cmd,
+    void *conf);
 static void *ngx_http_mp4_create_conf(ngx_conf_t *cf);
 static char *ngx_http_mp4_merge_conf(ngx_conf_t *cf, void *parent, void *child);
 
@@ -383,6 +391,20 @@
       offsetof(ngx_http_mp4_conf_t, max_buffer_size),
       &ngx_conf_size_nonzero_post },
 
+    { ngx_string("mp4_limit_rate"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_http_mp4_limit_rate,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_mp4_conf_t, limit_rate),
+      NULL },
+
+    { ngx_string("mp4_limit_rate_after"),
+      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
+      ngx_conf_set_msec_slot,
+      NGX_HTTP_LOC_CONF_OFFSET,
+      offsetof(ngx_http_mp4_conf_t, limit_rate_after),
+      NULL },
+
     { ngx_string("mp4_start_key_frame"),
       NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_FLAG,
       ngx_conf_set_flag_slot,
@@ -484,6 +506,7 @@
     ngx_log_t                 *log;
     ngx_buf_t                 *b;
     ngx_chain_t                out;
+    ngx_http_mp4_conf_t       *conf;
     ngx_http_mp4_file_t       *mp4;
     ngx_open_file_info_t       of;
     ngx_http_core_loc_conf_t  *clcf;
@@ -577,7 +600,9 @@
     r->root_tested = !r->error_page;
     r->allow_ranges = 1;
 
-    start = -1;
+    conf = ngx_http_get_module_loc_conf(r, ngx_http_mp4_module);
+
+    start = conf->limit_rate ? 0 : -1;
     length = 0;
     r->headers_out.content_length_n = of.size;
     mp4 = NULL;
@@ -630,6 +655,8 @@
         switch (ngx_http_mp4_process(mp4)) {
 
         case NGX_DECLINED:
+            ngx_http_mp4_set_limit(mp4);
+
             if (mp4->buffer) {
                 ngx_pfree(r->pool, mp4->buffer);
             }
@@ -640,6 +667,7 @@
             break;
 
         case NGX_OK:
+            ngx_http_mp4_set_limit(mp4);
             r->headers_out.content_length_n = mp4->content_length;
             break;
 
@@ -728,6 +756,45 @@
 }
 
 
+static void
+ngx_http_mp4_set_limit(ngx_http_mp4_file_t *mp4)
+{
+    double                bitrate, duration;
+    ngx_http_request_t   *r;
+    ngx_http_mp4_conf_t  *conf;
+
+    conf = ngx_http_get_module_loc_conf(mp4->request, ngx_http_mp4_module);
+
+    if (conf->limit_rate == 0 || mp4->timescale == 0 || mp4->mdat_length == 0) {
+        return;
+    }
+
+    duration = (double) mp4->duration / mp4->timescale * 1000;
+
+    if ((ngx_msec_t) duration <= conf->limit_rate_after) {
+        return;
+    }
+
+    bitrate = (double) mp4->mdat_length / duration;
+
+    r = mp4->request;
+
+    r->limit_rate = (size_t) (bitrate * conf->limit_rate);
+
+    if (r->limit_rate == 0) {
+        r->limit_rate = 1;
+    }
+
+    r->limit_rate_set = 1;
+
+    if (conf->limit_rate_after != 0) {
+        r->limit_rate_after = mp4->ftyp_size + mp4->moov_size
+                              + (size_t) (bitrate * conf->limit_rate_after);
+        r->limit_rate_after_set = 1;
+    }
+}
+
+
 static ngx_int_t
 ngx_http_mp4_atofp(u_char *line, size_t n, size_t point)
 {
@@ -827,6 +894,8 @@
         prev = &mp4->ftyp_atom.next;
     }
 
+    mp4->moov_size = 0;
+
     *prev = &mp4->moov_atom;
     prev = &mp4->moov_atom.next;
 
@@ -1181,14 +1250,22 @@
 
     ngx_log_debug0(NGX_LOG_DEBUG_HTTP, mp4->file.log, 0, "mp4 moov atom");
 
+    conf = ngx_http_get_module_loc_conf(mp4->request, ngx_http_mp4_module);
+
     no_mdat = (mp4->mdat_atom.buf == NULL);
 
     if (no_mdat && mp4->start == 0 && mp4->length == 0) {
+
         /*
          * send original file if moov atom resides before
          * mdat atom and client requests integral file
          */
-        return NGX_DECLINED;
+
+        if (conf->limit_rate == 0) {
+            return NGX_DECLINED;
+        }
+
+        /* need to calculate bitrate for rate limiting */
     }
 
     if (mp4->moov_atom.buf) {
@@ -1197,8 +1274,6 @@
         return NGX_ERROR;
     }
 
-    conf = ngx_http_get_module_loc_conf(mp4->request, ngx_http_mp4_module);
-
     if (atom_data_size > mp4->buffer_size) {
 
         if (atom_data_size > conf->max_buffer_size) {
@@ -1234,6 +1309,8 @@
 
     mp4->moov_atom.buf = &mp4->moov_atom_buf;
 
+    mp4->moov_size = sizeof(mp4->moov_atom_header) + atom_data_size;
+
     rc = ngx_http_mp4_read_atom(mp4, ngx_http_mp4_moov_atoms, atom_data_size);
 
     ngx_log_debug0(NGX_LOG_DEBUG_HTTP, mp4->file.log, 0, "mp4 moov atom done");
@@ -1260,10 +1337,32 @@
 static ngx_int_t
 ngx_http_mp4_read_mdat_atom(ngx_http_mp4_file_t *mp4, uint64_t atom_data_size)
 {
+    uint32_t    atom_header_size;
     ngx_buf_t  *data;
 
     ngx_log_debug0(NGX_LOG_DEBUG_HTTP, mp4->file.log, 0, "mp4 mdat atom");
 
+    if (mp4->moov_atom.buf != NULL && mp4->start == 0 && mp4->length == 0) {
+
+        /*
+         * calculate mp4->mdat_length for limit rate and send original file
+         * if moov atom resides before mdat atom and client requests
+         * integral file
+         */
+
+        if (atom_data_size
+            > (uint64_t) 0xffffffff - sizeof(ngx_mp4_atom_header_t))
+        {
+            atom_header_size = sizeof(ngx_mp4_atom_header64_t);
+        } else {
+            atom_header_size = sizeof(ngx_mp4_atom_header_t);
+        }
+
+        mp4->mdat_length = atom_header_size + atom_data_size;
+
+        return NGX_DECLINED;
+    }
+
     if (mp4->mdat_atom.buf) {
         ngx_log_error(NGX_LOG_ERR, mp4->file.log, 0,
                       "duplicate mp4 mdat atom in \"%s\"", mp4->file.name.data);
@@ -1324,7 +1423,8 @@
         atom_header_size = sizeof(ngx_mp4_atom_header_t);
     }
 
-    mp4->content_length += atom_header_size + atom_data_size;
+    mp4->mdat_length = atom_header_size + atom_data_size;
+    mp4->content_length += mp4->mdat_length;
 
     ngx_mp4_set_32value(atom_header, atom_size);
     ngx_mp4_set_atom_name(atom_header, 'm', 'd', 'a', 't');
@@ -1457,6 +1557,8 @@
         }
     }
 
+    mp4->duration = duration;
+
     ngx_log_debug2(NGX_LOG_DEBUG_HTTP, mp4->file.log, 0,
                    "mvhd new duration:%uL, time:%.3fs",
                    duration, (double) duration / timescale);
@@ -3956,6 +4058,42 @@
 }
 
 
+static char *
+ngx_http_mp4_limit_rate(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
+{
+    ngx_http_mp4_conf_t *mlcf = conf;
+
+    ngx_str_t  *value;
+    ngx_int_t   limit_rate;
+
+    if (mlcf->limit_rate != NGX_CONF_UNSET_UINT) {
+        return "is duplicate";
+    }
+
+    value = cf->args->elts;
+
+    if (value[1].len == 2 && ngx_strcmp(value[1].data, "on") == 0) {
+        limit_rate = 1.1 * 1000;
+
+    } else if (value[1].len == 3 && ngx_strcmp(value[1].data, "off") == 0) {
+        limit_rate = 0;
+
+    } else {
+        limit_rate = ngx_http_mp4_atofp(value[1].data, value[1].len, 3);
+
+        if (limit_rate <= 0) {
+            ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
+                               "invalid parameter \"%V\"", &value[1]);
+            return NGX_CONF_ERROR;
+        }
+    }
+
+    mlcf->limit_rate = (ngx_uint_t) limit_rate;
+
+    return NGX_CONF_OK;
+}
+
+
 static void *
 ngx_http_mp4_create_conf(ngx_conf_t *cf)
 {
@@ -3968,6 +4106,8 @@
 
     conf->buffer_size = NGX_CONF_UNSET_SIZE;
     conf->max_buffer_size = NGX_CONF_UNSET_SIZE;
+    conf->limit_rate = NGX_CONF_UNSET_UINT;
+    conf->limit_rate_after = NGX_CONF_UNSET_MSEC;
     conf->start_key_frame = NGX_CONF_UNSET;
 
     return conf;
@@ -3983,6 +4123,9 @@
     ngx_conf_merge_size_value(conf->buffer_size, prev->buffer_size, 512 * 1024);
     ngx_conf_merge_size_value(conf->max_buffer_size, prev->max_buffer_size,
                               10 * 1024 * 1024);
+    ngx_conf_merge_uint_value(conf->limit_rate, prev->limit_rate, 0);
+    ngx_conf_merge_msec_value(conf->limit_rate_after, prev->limit_rate_after,
+                              60 * 1000);
     ngx_conf_merge_value(conf->start_key_frame, prev->start_key_frame, 0);
 
     return NGX_CONF_OK;
