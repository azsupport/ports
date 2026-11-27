/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * tm - the wall time and the CPU time of a command, with the resolution of the clock
 * (time -p has 10 ms; the tm of tools/lib-bench3 with the CPU time of wait4):
 * tm [-o <stdout>] [-e <stderr>] <command> [<argument>...]. On its own stdout
 * "<wall seconds>\t<cpu seconds>" ("%.6f"; cpu: user and system time of the command and
 * its threads), the output of the command into -o and -e (default /dev/null). Exit status
 * 0 when the command exited with 0, else 1, the reason on stderr.
 */
#include <sys/types.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int
redirect(const char *path, int fd)
{
	int f = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);

	if (f < 0 || dup2(f, fd) < 0)
		return -1;
	close(f);
	return 0;
}

int
main(int argc, char **argv)
{
	const char *out = "/dev/null", *err = "/dev/null";
	struct timespec a, b;
	struct rusage ru;
	int c, st;
	pid_t p;

	while ((c = getopt(argc, argv, "+o:e:")) != -1) {
		switch (c) {
		case 'o': out = optarg; break;
		case 'e': err = optarg; break;
		default: return 2;
		}
	}
	if (optind >= argc) {
		fprintf(stderr, "usage: tm [-o out] [-e err] command...\n");
		return 2;
	}
	fflush(stdout);
	clock_gettime(CLOCK_MONOTONIC, &a);
	p = fork();
	if (p == 0) {
		if (redirect(out, 1) < 0 || redirect(err, 2) < 0)
			_exit(126);
		execvp(argv[optind], argv + optind);
		_exit(127);
	}
	if (p < 0 || wait4(p, &st, 0, &ru) < 0) {
		perror("tm");
		return 1;
	}
	clock_gettime(CLOCK_MONOTONIC, &b);
	if (!WIFEXITED(st) || WEXITSTATUS(st) != 0) {
		fprintf(stderr, "tm: %s: %s %d\n", argv[optind],
		    WIFEXITED(st) ? "exit status" : "signal",
		    WIFEXITED(st) ? WEXITSTATUS(st) : WTERMSIG(st));
		return 1;
	}
	printf("%.6f\t%.6f\n", (double)(b.tv_sec - a.tv_sec) + (double)(b.tv_nsec - a.tv_nsec) * 1e-9,
	    (double)(ru.ru_utime.tv_sec + ru.ru_stime.tv_sec) + (double)(ru.ru_utime.tv_usec + ru.ru_stime.tv_usec) * 1e-6);
	return 0;
}
