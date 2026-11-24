--- vendor/github.com/actions-oss/act-cli/pkg/container/host_environment.go.orig
+++ vendor/github.com/actions-oss/act-cli/pkg/container/host_environment.go
@@ -13,6 +13,7 @@
 	"path/filepath"
 	"runtime"
 	"strings"
+	"syscall"
 	"time"
 
 	"github.com/go-git/go-billy/v5/helper/polyfill"
@@ -310,6 +311,23 @@
 	cmd.Stderr = e.StdOut
 	cmd.Dir = wd
 	cmd.SysProcAttr = getSysProcAttr(cmdline, false)
+	// A cancelled step stops whole: the step runs in a process group of its own
+	// (Setpgid, or Setsid with a terminal), so its group gets SIGTERM, and SIGKILL 30
+	// seconds later; exec.CommandContext alone killed the first process only, and
+	// what it started (make and its compilers) went on.
+	cmd.Cancel = func() error {
+		if cmd.Process == nil {
+			return nil
+		}
+		pgid := cmd.Process.Pid
+		_ = syscall.Kill(-pgid, syscall.SIGTERM)
+		go func() {
+			time.Sleep(30 * time.Second)
+			_ = syscall.Kill(-pgid, syscall.SIGKILL)
+		}()
+		return nil
+	}
+	cmd.WaitDelay = 40 * time.Second
 	var ppty *os.File
 	var tty *os.File
 	defer func() {
