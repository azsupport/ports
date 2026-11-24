--- actionsrunner/runner.go.orig
+++ actionsrunner/runner.go
@@ -150,6 +150,7 @@
 		// No retry on Fatal failures, like runner was removed or we received multiple jobs
 		fatalFailure := false
 		for _, instance := range settings.Instances {
+			//nolint:gosec
 			go func(instance *runnerconfiguration.RunnerInstance) (exitcode int) {
 				defer wg.Done()
 				defer func() {
@@ -329,6 +330,13 @@
 									runnerenv.Printf("Failed to get message, GitHub has rejected our authorization, recreate Session earlier: %v\n", err.Error())
 									session = nil
 									continue
+								} else if strings.Contains(err.Error(), "RunnerSessionInvalid") {
+									// the broker no longer knows the session (after a forced
+									// cancellation of a job): a new one at once, not after
+									// sessionExpired of failed retries
+									runnerenv.Printf("Failed to get message, the session is no longer valid, recreate it: %v\n", err.Error())
+									session = nil
+									continue
 								}
 								runnerenv.Printf("Failed to get message, waiting %d sec before retry: %v\n", retryShort/time.Second, err.Error())
 								select {
@@ -373,17 +381,42 @@
 									jobCompletedWG.Done()
 								}()
 								runJob(runnerenv, &joblock, vssConnection, run, cancel, cancelJob, finishJob, jobExecCtx, jobctx, session, *message, instance)
-								{
+								for jobExecCtx.Err() == nil {
+									runnerenv.Printf("Fetch next (Cancellation) Message\n")
 									session.Status = "Busy"
 									var err error
 									message, err = session.GetNextMessage(jobExecCtx)
+									if err != nil && !errors.Is(err, context.Canceled) && strings.Contains(err.Error(), "RunnerSessionInvalid") {
+										// the session went invalid while the job runs: a new one,
+										// so that its cancellation still comes in
+										runnerenv.Printf("The session is no longer valid while a job runs, recreate it: %v\n", err.Error())
+										session2, err2 := vssConnection.CreateSession(jobExecCtx)
+										if err2 == nil && session2 != nil {
+											session = session2
+											mu.Lock()
+											sessions = append(sessions, session.TaskAgentSession)
+											if err3 := runnerenv.WriteJSON("sessions.json", sessions); err3 != nil {
+												runnerenv.Printf("error: %v\n", err3)
+											}
+											mu.Unlock()
+										} else {
+											runnerenv.Printf("Failed to recreate Session, waiting %d sec before retry: %v\n", retryInterval/time.Second, err2)
+											select {
+											case <-jobExecCtx.Done():
+											case <-time.After(retryInterval):
+											}
+										}
+										continue
+									}
 									if !errors.Is(err, context.Canceled) && message != nil {
 										if firstJobReceived && (strings.EqualFold(message.MessageType, "PipelineAgentJobRequest") ||
 											strings.EqualFold(message.MessageType, "RunnerJobRequest")) {
 											runnerenv.Printf("Skip deleting the duplicated job request, " +
 												"we hope that the actions service reschedules your job to a different runner\n")
 										} else {
-											err = session.DeleteMessage(joblisteningctx, message)
+											// not joblisteningctx: cancelled once the job came in
+											// (upstream issue 243)
+											err = session.DeleteMessage(context.Background(), message)
 											if err != nil {
 												runnerenv.Printf("Failed to delete message: %v\n", err)
 											}
@@ -395,10 +428,10 @@
 										} else {
 											runnerenv.Printf("Received message, while still executing a job, of type: %v\n", message.MessageType)
 										}
-										runnerenv.Printf("Wait for worker to finish current job\n")
-										<-jobctx.Done()
 									}
 								}
+								runnerenv.Printf("Wait for worker to finish current job\n")
+								<-jobctx.Done()
 							}
 							// Skip deleting session for ephemeral, since the official actions service throws access denied
 							if !run.Once || isEphemeral {
