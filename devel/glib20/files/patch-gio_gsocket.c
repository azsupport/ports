The whole union of the address to getsockname() and getpeername(), not its member
struct sockaddr (azsupport/ports, 27.11.2026): with _FORTIFY_SOURCE=2 the
<ssp/socket.h> of FreeBSD checks the length of the address against
__builtin_object_size(address, 1), which GCC takes for the 16 bytes of that member
(clang, through the inline functions of <ssp/socket.h>, for the whole object), so
that built by GCC 16 (Mk/Uses/azgcc.mk) g_socket_new_from_fd(),
g_socket_get_local_address() and g_socket_get_remote_address() end in __chk_fail(),
as getsockname() of the _socket module of Python 3.12 did (prog-bench run
45935459608). The same address, so the same calls for clang.

--- gio/gsocket.c.orig	2026-11-25 14:25:19 UTC
+++ gio/gsocket.c
@@ -531,7 +531,7 @@
 
 #ifndef G_OS_WIN32
   addrlen = sizeof address;
-  if (getsockname (fd, &address.sa, &addrlen) != 0)
+  if (getsockname (fd, (struct sockaddr *) &address, &addrlen) != 0)
     {
       errsv = get_socket_errno ();
       goto err;
@@ -601,7 +601,7 @@
   if (socket->priv->family != G_SOCKET_FAMILY_INVALID)
     {
       addrlen = sizeof address;
-      if (getpeername (fd, &address.sa, &addrlen) >= 0)
+      if (getpeername (fd, (struct sockaddr *) &address, &addrlen) >= 0)
         {
           socket->priv->connected_read = TRUE;
           socket->priv->connected_write = TRUE;
@@ -2088,7 +2088,7 @@
 
   g_return_val_if_fail (G_IS_SOCKET (socket), NULL);
 
-  if (getsockname (socket->priv->fd, &buffer.sa, &len) < 0)
+  if (getsockname (socket->priv->fd, (struct sockaddr *) &buffer, &len) < 0)
     {
       int errsv = get_socket_errno ();
       g_set_error (error, G_IO_ERROR, socket_io_error_from_errno (errsv),
@@ -2134,7 +2134,7 @@
 
   if (!socket->priv->remote_address)
     {
-      if (getpeername (socket->priv->fd, &buffer.sa, &len) < 0)
+      if (getpeername (socket->priv->fd, (struct sockaddr *) &buffer, &len) < 0)
 	{
 	  int errsv = get_socket_errno ();
 	  g_set_error (error, G_IO_ERROR, socket_io_error_from_errno (errsv),
