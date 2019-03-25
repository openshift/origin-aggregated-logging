/**
 * @file normalizer.c
 * @brief A small tool to normalize data.
 *
 * This is the most basic example demonstrating how to use liblognorm.
 * It loads log samples from the files specified on the command line,
 * reads to-be-normalized data from stdin and writes the normalized
 * form to stdout. Besides being an example, it also carries out useful
 * processing.
 *
 * @author Rainer Gerhards <rgerhards@adiscon.com>
 *
 *//*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2016 by Rainer Gerhards and Adiscon GmbH.
 *
 * This file is part of liblognorm.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * A copy of the LGPL v2.1 can be found in the file "COPYING" in this distribution.
 */
#include "config.h"
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <libestr.h>

#include "liblognorm.h"
#include "lognorm.h"
#include "enc.h"

/* we need to turn off this warning, as it also comes up in C99 mode, which
 * we use.
 */
#pragma GCC diagnostic ignored "-Wdeclaration-after-statement"

static ln_ctx ctx;

static int verbose = 0;
#define OUTPUT_PARSED_RECS 0x01
#define OUTPUT_UNPARSED_RECS 0x02
static int recOutput = OUTPUT_PARSED_RECS | OUTPUT_UNPARSED_RECS;
				/**< controls which records to output */
static int outputSummaryLine = 0;
static int outputNbrUnparsed = 0;
static int addErrLineNbr = 0;	/**< add line number info to unparsed events */
static int flatTags = 0;	/**< print event.tags in JSON? */
static FILE *fpDOT;
static es_str_t *encFmt = NULL; /**< a format string for encoder use */
static es_str_t *mandatoryTag = NULL; /**< tag which must be given so that mesg will
					   be output. NULL=all */
static enum { f_syslog, f_json, f_xml, f_csv, f_raw } outfmt = f_json;

static void
errCallBack(void __attribute__((unused)) *cookie, const char *msg,
	    size_t __attribute__((unused)) lenMsg)
{
	fprintf(stderr, "liblognorm error: %s\n", msg);
}

static void
dbgCallBack(void __attribute__((unused)) *cookie, const char *msg,
	    size_t __attribute__((unused)) lenMsg)
{
	fprintf(stderr, "liblognorm: %s\n", msg);
}

static void
complain(const char *errmsg)
{
	fprintf(stderr, "%s\n", errmsg);
}


/* rawmsg is, as the name says, the raw message, in case we have
 * "raw" formatter requested.
 */
static void
outputEvent(struct json_object *json, const char *const rawmsg)
{
	char *cstr = NULL;
	es_str_t *str = NULL;

	if(outfmt == f_raw) {
		printf("%s\n", rawmsg);
		return;
	}

	switch(outfmt) {
	case f_json:
		if(!flatTags) {
			json_object_object_del(json, "event.tags");
		}
		cstr = (char*)json_object_to_json_string(json);
		break;
	case f_syslog:
		ln_fmtEventToRFC5424(json, &str);
		break;
	case f_xml:
		ln_fmtEventToXML(json, &str);
		break;
	case f_csv:
		ln_fmtEventToCSV(json, &str, encFmt);
		break;
	case f_raw:
		fprintf(stderr, "program error: f_raw should not occur "
			"here (file %s, line %d)\n", __FILE__, __LINE__);
		abort();
		break;
	default:
		fprintf(stderr, "program error: default case should not occur "
			"here (file %s, line %d)\n", __FILE__, __LINE__);
		abort();
		break;
	}
	if (str != NULL)
		cstr = es_str2cstr(str, NULL);
	if(verbose > 0) fprintf(stderr, "normalized: '%s'\n", cstr);
	printf("%s\n", cstr);
	if (str != NULL)
		free(cstr);
	es_deleteStr(str);
}

/* test if the tag exists */
static int
eventHasTag(struct json_object *json, const char *tag)
{
	struct json_object *tagbucket, *tagObj;
	int i;
	const char *tagCstr;
	
	if (tag == NULL)
		return 1;
	if (json_object_object_get_ex(json, "event.tags", &tagbucket)) {
		if (json_object_get_type(tagbucket) == json_type_array) {
			for (i = json_object_array_length(tagbucket) - 1; i >= 0; i--) {
				tagObj = json_object_array_get_idx(tagbucket, i);
				tagCstr = json_object_get_string(tagObj);
				if (!strcmp(tag, tagCstr))
					return 1;
			}
		}
	}
	if (verbose > 1)
		printf("Mandatory tag '%s' has not been found\n", tag);
	return 0;
}

static void
amendLineNbr(json_object *const json, const int line_nbr)
{
	
	if(addErrLineNbr) {
		struct json_object *jval;
		jval = json_object_new_int(line_nbr);
		json_object_object_add(json, "lognormalizer.line_nbr", jval);
	}
}

#define DEFAULT_LINE_SIZE (10 * 1024)

static char *
read_line(FILE *fp)
{
	size_t line_capacity = DEFAULT_LINE_SIZE;
	char *line = NULL;
	size_t line_len = 0;
	int ch = 0;
	do {
		ch = fgetc(fp);
		if (ch == EOF) break;
		if (line == NULL) {
			line = malloc(line_capacity);
		} else if (line_len == line_capacity) {
			line_capacity *= 2;
			line = realloc(line, line_capacity);
		}
		if (line == NULL) {
			fprintf(stderr, "Couldn't allocate working-buffer for log-line\n");
			return NULL;
		}
		line[line_len++] = ch;
	} while(ch != '\n');

	if (line != NULL) {
		line[--line_len] = '\0';
		if(line_len > 0 && line[line_len - 1] == '\r')
			line[--line_len] = '\0';
	}
	return line;
}

/* normalize input data
 */
static void
normalize(void)
{
	FILE *fp = stdin;
	char *line = NULL;
	struct json_object *json = NULL;
	long long unsigned numParsed = 0;
	long long unsigned numUnparsed = 0;
	long long unsigned numWrongTag = 0;
	char *mandatoryTagCstr = NULL;
	int line_nbr = 0;	/* must be int to keep compatible with older json-c */

	if (mandatoryTag != NULL) {
		mandatoryTagCstr = es_str2cstr(mandatoryTag, NULL);
	}

	while((line = read_line(fp)) != NULL) {
		++line_nbr;
		if(verbose > 0) fprintf(stderr, "To normalize: '%s'\n", line);
		ln_normalize(ctx, line, strlen(line), &json);
		if(json != NULL) {
			if(eventHasTag(json, mandatoryTagCstr)) {
				struct json_object *dummy;
				const int parsed = !json_object_object_get_ex(json,
					"unparsed-data", &dummy);
				if(parsed) {
					numParsed++;
					if(recOutput & OUTPUT_PARSED_RECS) {
						outputEvent(json, line);
					}
				} else {
					numUnparsed++;
					amendLineNbr(json, line_nbr);
					if(recOutput & OUTPUT_UNPARSED_RECS) {
						outputEvent(json, line);
					}
				}
			} else {
				numWrongTag++;
			}
			json_object_put(json);
			json = NULL;
		}
	free(line);
	}
	if(outputNbrUnparsed && numUnparsed > 0)
		fprintf(stderr, "%llu unparsable entries\n", numUnparsed);
	if(numWrongTag > 0)
		fprintf(stderr, "%llu entries with wrong tag dropped\n", numWrongTag);
	if(outputSummaryLine) {
		fprintf(stderr, "%llu records processed, %llu parsed, %llu unparsed\n",
			numParsed+numUnparsed, numParsed, numUnparsed);
	}
	free(mandatoryTagCstr);
}


/**
 * Generate a command file for the GNU DOT tools.
 */
static void
genDOT(void)
{
	es_str_t *str;

	str = es_newStr(1024);
	ln_genDotPDAGGraph(ctx->pdag, &str);
	fwrite(es_getBufAddr(str), 1, es_strlen(str), fpDOT);
}

static
void printVersion(void)
{
	fprintf(stderr, "lognormalizer version: " VERSION "\n");
	fprintf(stderr, "liblognorm version: %s\n", ln_version());
	fprintf(stderr, "\tadvanced stats: %s\n",
		ln_hasAdvancedStats() ? "available" : "not available");
}

static void
handle_generic_option(const char* opt) {
	if (strcmp("allowRegex", opt) == 0) {
		ln_setCtxOpts(ctx, LN_CTXOPT_ALLOW_REGEX);
	} else if (strcmp("addExecPath", opt) == 0) {
		ln_setCtxOpts(ctx, LN_CTXOPT_ADD_EXEC_PATH);
	} else if (strcmp("addOriginalMsg", opt) == 0) {
		ln_setCtxOpts(ctx, LN_CTXOPT_ADD_ORIGINALMSG);
	} else if (strcmp("addRule", opt) == 0) {
		ln_setCtxOpts(ctx, LN_CTXOPT_ADD_RULE);
	} else if (strcmp("addRuleLocation", opt) == 0) {
		ln_setCtxOpts(ctx, LN_CTXOPT_ADD_RULE_LOCATION);
	} else {
		fprintf(stderr, "invalid -o option '%s'\n", opt);
		exit(1);
	}
}

static void usage(void)
{
fprintf(stderr,
	"Options:\n"
	"    -r<rulebase> Rulebase to use. This is required option\n"
	"    -H           print summary line (nbr of msgs Handled)\n"
	"    -U           print number of unparsed messages (only if non-zero)\n"
	"    -e<json|xml|csv|cee-syslog|raw>\n"
	"                 Change output format. By default, json is used\n"
	"                 Raw is exactly like the input. It is useful in combination\n"
	"                 with -p/-P options to extract known good/bad messages\n"
	"    -E<format>   Encoder-specific format (used for CSV, read docs)\n"
	"    -T           Include 'event.tags' in JSON format\n"
	"    -oallowRegex Allow regexp matching (read docs about performance penalty)\n"
	"    -oaddRule    Add a mockup of the matching rule.\n"
	"    -oaddRuleLocation Add location of matching rule to metadata\n"
	"    -oaddExecPath Add exec_path attribute to output\n"
	"    -oaddOriginalMsg Always add original message to output, not just in error case\n"
	"    -p           Print back only if the message has been parsed succesfully\n"
	"    -P           Print back only if the message has NOT been parsed succesfully\n"
	"    -L           Add source file line number information to unparsed line output\n"
	"    -t<tag>      Print back only messages matching the tag\n"
	"    -v           Print debug. When used 3 times, prints parse DAG\n"
	"    -V           Print version information\n"
	"    -d           Print DOT file to stdout and exit\n"
	"    -d<filename> Save DOT file to the filename\n"
	"    -s<filename> Print parse dag statistics and exit\n"
	"    -S<filename> Print extended parse dag statistics and exit (includes -s)\n"
	"    -x<filename> Print statistics as dot file (called only)\n"
	"\n"
	);
}

int main(int argc, char *argv[])
{
	int opt;
	char *repository = NULL;
	int usedRB = 0; /* 0=no rule; 1=rule from rulebase; 2=rule from string */
	int ret = 0;
	FILE *fpStats = NULL;
	FILE *fpStatsDOT = NULL;
	int extendedStats = 0;

	if((ctx = ln_initCtx()) == NULL) {
		complain("Could not initialize liblognorm context");
		ret = 1;
		goto exit;
	}

	while((opt = getopt(argc, argv, "d:s:S:e:r:R:E:vVpPt:To:hHULx:")) != -1) {
		switch (opt) {
		case 'V':
			printVersion();
			exit(1);
			break;
		case 'd': /* generate DOT file */
			if(!strcmp(optarg, "")) {
				fpDOT = stdout;
			} else {
				if((fpDOT = fopen(optarg, "w")) == NULL) {
					perror(optarg);
					complain("Cannot open DOT file");
					ret = 1;
					goto exit;
				}
			}
			break;
		case 'x': /* generate statistics DOT file */
			if(!strcmp(optarg, "")) {
				fpStatsDOT = stdout;
			} else {
				if((fpStatsDOT = fopen(optarg, "w")) == NULL) {
					perror(optarg);
					complain("Cannot open statistics DOT file");
					ret = 1;
					goto exit;
				}
			}
			break;
		case 'S': /* generate pdag statistic file */
			extendedStats = 1;
			/* INTENTIONALLY NO BREAK! - KEEP order! */
			/*FALLTHROUGH*/
		case 's': /* generate pdag statistic file */
			if(!strcmp(optarg, "-")) {
				fpStats = stdout;
			} else {
				if((fpStats = fopen(optarg, "w")) == NULL) {
					perror(optarg);
					complain("Cannot open parser statistics file");
					ret = 1;
					goto exit;
				}
			}
			break;
		case 'v':
			verbose++;
			break;
		case 'E': /* encoder-specific format string (will be validated by encoder) */
			encFmt = es_newStrFromCStr(optarg, strlen(optarg));
			break;
		case 'p':
			recOutput = OUTPUT_PARSED_RECS;
			break;
		case 'P':
			recOutput = OUTPUT_UNPARSED_RECS;
			break;
		case 'H':
			outputSummaryLine = 1;
			break;
		case 'U':
			outputNbrUnparsed = 1;
			break;
		case 'L':
			addErrLineNbr = 1;
			break;
		case 'T':
			flatTags = 1;
			break;
		case 'e': /* encoder to use */
			if(!strcmp(optarg, "json")) {
				outfmt = f_json;
			} else if(!strcmp(optarg, "xml")) {
				outfmt = f_xml;
			} else if(!strcmp(optarg, "cee-syslog")) {
				outfmt = f_syslog;
			} else if(!strcmp(optarg, "csv")) {
				outfmt = f_csv;
			} else if(!strcmp(optarg, "raw")) {
				outfmt = f_raw;
			}
			break;
		case 'r': /* rule base to use */
			if(usedRB != 2) {
				repository = optarg;
				usedRB = 1;
			} else {
				usedRB = -1;
			}
			break;
		case 'R':
			if(usedRB != 1) {
				repository = optarg;
				usedRB = 2;
			} else {
				usedRB = -1;
			}
			break;
		case 't': /* if given, only messages tagged with the argument
			     are output */
			mandatoryTag = es_newStrFromCStr(optarg, strlen(optarg));
			break;
		case 'o':
			handle_generic_option(optarg);
			break;
		case 'h':
		default:
			usage();
			ret = 1;
			goto exit;
			break;
		}
	}

	if(repository == NULL) {
		complain("Samples repository or String must be given (-r or -R)");
		ret = 1;
		goto exit;
	}

	if(usedRB == -1) {
		complain("Only use one rulebase (-r or -R)");
		ret = 1;
		goto exit;
	}

	ln_setErrMsgCB(ctx, errCallBack, NULL);
	if(verbose) {
		ln_setDebugCB(ctx, dbgCallBack, NULL);
		ln_enableDebug(ctx, 1);
	}

	if(usedRB == 1) {
		if(ln_loadSamples(ctx, repository)) {
			fprintf(stderr, "fatal error: cannot load rulebase\n");
			exit(1);
		}
	} else if(usedRB == 2) {
		if(ln_loadSamplesFromString(ctx, repository)) {
			fprintf(stderr, "fatal error: cannot load rule from String\n");
			exit(1);
		}
	}

	if(verbose > 0)
		fprintf(stderr, "number of tree nodes: %d\n", ctx->nNodes);

	if(fpDOT != NULL) {
		genDOT();
		ret=1;
		goto exit;
	}

	if(verbose > 2) ln_displayPDAG(ctx);

	normalize();

	if(fpStats != NULL) {
		ln_fullPdagStats(ctx, fpStats, extendedStats);
	}

	if(fpStatsDOT != NULL) {
		ln_fullPDagStatsDOT(ctx, fpStatsDOT);
	}

exit:
	if (ctx) ln_exitCtx(ctx);
	if (encFmt != NULL)
		free(encFmt);
	return ret;
}
