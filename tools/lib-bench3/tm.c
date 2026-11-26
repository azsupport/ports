/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * tm - the wall time of a command with the resolution of the clock (time -p has
 * 10 ms): tm [-i <stdin>] [-o <stdout>] [-e <stderr>] [-x <highest good exit status>]
 * <command> [<argument>...]; the seconds on its own stdout ("%.6f"), the output of
 * the command into -o (default /dev/null). Exit status 0 when the command exited
 * with at most -x (default 0), else 1, the reason on stderr.
 */
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int
redirect(const char *path, int fd, int flags)
{
	int f = open(path, flags, 0644);

	if (f < 0 || dup2(f, fd) < 0)
		return -1;
	close(f);
	return 0;
}

int
main(int argc, char **argv)
{
	const char *in = NULL, *out = "/dev/null", *err = "/dev/null";
	struct timespec a, b;
	int c, st, maxok = 0;
	pid_t p;

	while ((c = getopt(argc, argv, "+i:o:e:x:")) != -1) {
		switch (c) {
		case 'i': in = optarg; break;
		case 'o': out = optarg; break;
		case 'e': err = optarg; break;
		case 'x': maxok = atoi(optarg); break;
		default: return 2;
		}
	}
	if (optind >= argc) {
		fprintf(stderr, "usage: tm [-i in] [-o out] [-e err] [-x status] command...\n");
		return 2;
	}
	fflush(stdout);
	clock_gettime(CLOCK_MONOTONIC, &a);
	p = fork();
	if (p == 0) {
		if ((in != NULL && redirect(in, 0, O_RDONLY) < 0) ||
		    redirect(out, 1, O_WRONLY | O_CREAT | O_TRUNC) < 0 ||
		    redirect(err, 2, O_WRONLY | O_CREAT | O_TRUNC) < 0)
			_exit(126);
		execvp(argv[optind], argv + optind);
		_exit(127);
	}
	if (p < 0 || waitpid(p, &st, 0) < 0) {
		perror("tm");
		return 1;
	}
	clock_gettime(CLOCK_MONOTONIC, &b);
	if (!WIFEXITED(st) || WEXITSTATUS(st) > maxok) {
		fprintf(stderr, "tm: %s: %s %d\n", argv[optind],
		    WIFEXITED(st) ? "exit status" : "signal",
		    WIFEXITED(st) ? WEXITSTATUS(st) : WTERMSIG(st));
		return 1;
	}
	printf("%.6f\n", (double)(b.tv_sec - a.tv_sec) + (double)(b.tv_nsec - a.tv_nsec) * 1e-9);
	return 0;
}
