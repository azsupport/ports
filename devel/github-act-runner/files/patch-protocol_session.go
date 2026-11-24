--- protocol/session.go.orig
+++ protocol/session.go
@@ -210,6 +210,10 @@
 		if err != nil {
 			if errors.Is(err, context.Canceled) {
 				return nil, err
+			} else if strings.Contains(err.Error(), "RunnerSessionInvalid") {
+				// no retry with a session the broker no longer knows: the caller makes a
+				// new one
+				return nil, err
 			} else if !errors.Is(err, io.EOF) {
 				fmt.Printf("Failed to get message, waiting 10 sec before retry: %v\n", err.Error())
 				select {
