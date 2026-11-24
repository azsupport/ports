# devel/github-act-runner of azsupport/ports: the official port as it is
# (Mk/az-official.mk), github-act-runner, the self-hosted runner of GitHub Actions
# in Go (aZ, 20.11.2026: the builds in a jail of FreeBSD; actions/runner of GitHub
# has no FreeBSD build): a static binary (CGO_ENABLED=0 of the official port).

AZ_OFFICIAL=	devel/github-act-runner
# A job cancelled on GitHub stops on the runner (aZ, 24.11.2026 21:28: «надо бы
# пофиксить чтобы через гитхаб работало»; run 45475520418 of build-jail.yml, cancelled
# and force-cancelled, went on with its steps until make was killed on the server):
# - actionsrunner/runner.go: while a job runs, the messages are fetched until it ends,
#   not one only, so its JobCancellation comes in (upstream 7aa5ae4 of 07.03.2026,
#   "Fix job cancellation broker listener", issue 236, after v0.13.0); the message of
#   that loop deleted with a context of its own (upstream issue 243: the context of the
#   listening is cancelled by then); a session the broker answers "RunnerSessionInvalid"
#   for (it did after the forced cancellation, and the runner retried it every 10 s and
#   took no job for minutes) made again at once, in the loop of a job and in that of the
#   listening;
# - protocol/session.go: GetNextMessage gives that error back instead of retrying;
# - act-cli (vendor/, pkg/container/host_environment.go): a cancelled step ends whole:
#   its process group gets SIGTERM, then SIGKILL 30 seconds later (exec.CommandContext
#   alone killed the first process only, its children went on).
EXTRA_PATCHES=	${.CURDIR}/files/patch-actionsrunner_runner.go \
		${.CURDIR}/files/patch-protocol_session.go \
		${.CURDIR}/files/patch-vendor_github.com_actions-oss_act-cli_pkg_container_host__environment.go

.include "${.CURDIR:H:H}/Mk/az-official.mk"
