/* SPDX-License-Identifier: BSD-2-Clause */
/* d-yaml <file.yaml> [<scale>]: libyaml (PHP yaml, Ruby psych): the events, and the documents */
#include <yaml.h>
#include "lb.h"

static int
emit_to(void *data, unsigned char *buf, size_t size)
{
	(void)buf;
	*(size_t *)data += size;
	return 1;
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	size_t len, out = 0;
	unsigned char *y = (unsigned char *)lb_read(argc > 1 ? argv[1] : "in.yaml", &len);
	yaml_parser_t p;
	yaml_event_t ev;
	yaml_document_t doc;
	yaml_emitter_t em;
	double t;

	t = lb_now();
	for (i = 0; i < 3 * s; i++) {
		int done = 0;

		yaml_parser_initialize(&p);
		yaml_parser_set_input_string(&p, y, len);
		while (!done) {
			if (!yaml_parser_parse(&p, &ev)) {
				fprintf(stderr, "parse error\n");
				return 1;
			}
			done = ev.type == YAML_STREAM_END_EVENT;
			LB_KEEP(ev.type);
			yaml_event_delete(&ev);
		}
		yaml_parser_delete(&p);
	}
	lb_out("parse events x3", t);
	t = lb_now();
	for (i = 0; i < 2 * s; i++) {
		yaml_parser_initialize(&p);
		yaml_parser_set_input_string(&p, y, len);
		if (!yaml_parser_load(&p, &doc)) {
			fprintf(stderr, "load error\n");
			return 1;
		}
		if (i == 0) {
			yaml_emitter_initialize(&em);
			yaml_emitter_set_output(&em, emit_to, &out);
			yaml_emitter_open(&em);
			yaml_emitter_dump(&em, &doc);
			yaml_emitter_close(&em);
			yaml_emitter_delete(&em);
		} else
			yaml_document_delete(&doc);
		yaml_parser_delete(&p);
	}
	LB_KEEP(out);
	lb_out("load documents x2 and dump x1", t);
	return 0;
}
