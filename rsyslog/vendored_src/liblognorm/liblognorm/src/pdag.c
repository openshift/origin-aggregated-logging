/**
 * @file pdag.c
 * @brief Implementation of the parse dag object.
 * @class ln_pdag pdag.h
 *//*
 * Copyright 2015 by Rainer Gerhards and Adiscon GmbH.
 *
 * Released under ASL 2.0.
 */
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <libestr.h>

#include "liblognorm.h"
#include "v1_liblognorm.h"
#include "v1_ptree.h"
#include "lognorm.h"
#include "samp.h"
#include "pdag.h"
#include "annot.h"
#include "internal.h"
#include "parser.h"
#include "helpers.h"

void ln_displayPDAGComponentAlternative(struct ln_pdag *dag, int level);
void ln_displayPDAGComponent(struct ln_pdag *dag, int level);

#ifdef	ADVANCED_STATS
uint64_t advstats_parsers_called = 0;
uint64_t advstats_parsers_success = 0;
int advstats_max_pathlen = 0;
int advstats_pathlens[ADVSTATS_MAX_ENTITIES];
int advstats_max_backtracked = 0;
int advstats_backtracks[ADVSTATS_MAX_ENTITIES];
int advstats_max_parser_calls = 0;
int advstats_parser_calls[ADVSTATS_MAX_ENTITIES];
int advstats_max_lit_parser_calls = 0;
int advstats_lit_parser_calls[ADVSTATS_MAX_ENTITIES];
#endif

/* parser lookup table
 * This is a memory- and cache-optimized way of calling parsers.
 * VERY IMPORTANT: the initialization must be done EXACTLY in the
 * order of parser IDs (also see comment in pdag.h).
 *
 * Rough guideline for assigning priorites:
 * 0 is highest, 255 lowest. 255 should be reserved for things that
 * *really* should only be run as last resort --> rest. Also keep in
 * mind that the user-assigned priority is put in the upper 24 bits, so
 * parser-specific priorities only count when the user has assigned
 * no priorities (which is expected to be common) or user-assigned
 * priorities are equal for some parsers.
 */
#ifdef ADVANCED_STATS
#define PARSER_ENTRY_NO_DATA(identifier, parser, prio) \
{ identifier, prio, NULL, ln_v2_parse##parser, NULL, 0, 0 }
#define PARSER_ENTRY(identifier, parser, prio) \
{ identifier, prio, ln_construct##parser, ln_v2_parse##parser, ln_destruct##parser, 0, 0 }
#else
#define PARSER_ENTRY_NO_DATA(identifier, parser, prio) \
{ identifier, prio, NULL, ln_v2_parse##parser, NULL }
#define PARSER_ENTRY(identifier, parser, prio) \
{ identifier, prio, ln_construct##parser, ln_v2_parse##parser, ln_destruct##parser }
#endif
static struct ln_parser_info parser_lookup_table[] = {
	PARSER_ENTRY("literal", Literal, 4),
	PARSER_ENTRY("repeat", Repeat, 4),
	PARSER_ENTRY("date-rfc3164", RFC3164Date, 8),
	PARSER_ENTRY("date-rfc5424", RFC5424Date, 8),
	PARSER_ENTRY("number", Number, 16),
	PARSER_ENTRY("float", Float, 16),
	PARSER_ENTRY("hexnumber", HexNumber, 16),
	PARSER_ENTRY_NO_DATA("kernel-timestamp", KernelTimestamp, 16),
	PARSER_ENTRY_NO_DATA("whitespace", Whitespace, 4),
	PARSER_ENTRY_NO_DATA("ipv4", IPv4, 4),
	PARSER_ENTRY_NO_DATA("ipv6", IPv6, 4),
	PARSER_ENTRY_NO_DATA("word", Word, 32),
	PARSER_ENTRY_NO_DATA("alpha", Alpha, 32),
	PARSER_ENTRY_NO_DATA("rest", Rest, 255),
	PARSER_ENTRY_NO_DATA("op-quoted-string", OpQuotedString, 64),
	PARSER_ENTRY_NO_DATA("quoted-string", QuotedString, 64),
	PARSER_ENTRY_NO_DATA("date-iso", ISODate, 8),
	PARSER_ENTRY_NO_DATA("time-24hr", Time24hr, 8),
	PARSER_ENTRY_NO_DATA("time-12hr", Time12hr, 8),
	PARSER_ENTRY_NO_DATA("duration", Duration, 16),
	PARSER_ENTRY_NO_DATA("cisco-interface-spec", CiscoInterfaceSpec, 4),
	PARSER_ENTRY_NO_DATA("name-value-list", NameValue, 8),
	PARSER_ENTRY_NO_DATA("json", JSON, 4),
	PARSER_ENTRY_NO_DATA("cee-syslog", CEESyslog, 4),
	PARSER_ENTRY_NO_DATA("mac48", MAC48, 16),
	PARSER_ENTRY_NO_DATA("cef", CEF, 4),
	PARSER_ENTRY_NO_DATA("checkpoint-lea", CheckpointLEA, 4),
	PARSER_ENTRY_NO_DATA("v2-iptables", v2IPTables, 4),
	PARSER_ENTRY("string-to", StringTo, 32),
	PARSER_ENTRY("char-to", CharTo, 32),
	PARSER_ENTRY("char-sep", CharSeparated, 32),
	PARSER_ENTRY("string", String, 32)
};
#define NPARSERS (sizeof(parser_lookup_table)/sizeof(struct ln_parser_info))
#define DFLT_USR_PARSER_PRIO 30000 /**< default priority if user has not specified it */
static inline const char *
parserName(const prsid_t id)
{
	const char *name;
	if(id == PRS_CUSTOM_TYPE)
		name = "USER-DEFINED";
	else
		name = parser_lookup_table[id].name;
	return name;
}

prsid_t
ln_parserName2ID(const char *const __restrict__ name)
{
	unsigned i;

	for(  i = 0
	    ; i < sizeof(parser_lookup_table) / sizeof(struct ln_parser_info)
	    ; ++i) {
	    	if(!strcmp(parser_lookup_table[i].name, name)) {
			return i;
		}
	    }
	return PRS_INVALID;
}

/* find type pdag in table. If "bAdd" is set, add it if not
 * already present, a new entry will be added.
 * Returns NULL on error, ptr to type pdag entry otherwise
 */
struct ln_type_pdag *
ln_pdagFindType(ln_ctx ctx, const char *const __restrict__ name, const int bAdd)
{
	struct ln_type_pdag *td = NULL;
	int i;

	LN_DBGPRINTF(ctx, "ln_pdagFindType, name '%s', bAdd: %d, nTypes %d",
		name, bAdd, ctx->nTypes);
	for(i = 0 ; i < ctx->nTypes ; ++i) {
		if(!strcmp(ctx->type_pdags[i].name, name)) {
			td = ctx->type_pdags + i;
			goto done;
		}
	}

	if(!bAdd) {
		LN_DBGPRINTF(ctx, "custom type '%s' not found", name);
		goto done;
	}

	/* type does not yet exist -- create entry */
	LN_DBGPRINTF(ctx, "custom type '%s' does not yet exist, adding...", name);
	struct ln_type_pdag *newarr;
	newarr = realloc(ctx->type_pdags, sizeof(struct ln_type_pdag) * (ctx->nTypes+1));
	if(newarr == NULL) {
		LN_DBGPRINTF(ctx, "ln_pdagFindTypeAG: alloc newarr failed");
		goto done;
	}
	ctx->type_pdags = newarr;
	td = ctx->type_pdags + ctx->nTypes;
	++ctx->nTypes;
	td->name = strdup(name);
	td->pdag = ln_newPDAG(ctx);
done:
	return td;
}

/* we clear some multiple times, but as long as we have no loops
 * (dag!) we have no real issue.
 */
static void
ln_pdagComponentClearVisited(struct ln_pdag *const dag)
{
	dag->flags.visited = 0;
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *prs = dag->parsers+i;
		ln_pdagComponentClearVisited(prs->node);
	}
}
static void
ln_pdagClearVisited(ln_ctx ctx)
{
	for(int i = 0 ; i < ctx->nTypes ; ++i)
		ln_pdagComponentClearVisited(ctx->type_pdags[i].pdag);
	ln_pdagComponentClearVisited(ctx->pdag);
}

/**
 * Process a parser defintion. Note that a single defintion can potentially
 * contain many parser instances.
 * @return parser node ptr or NULL (on error)
 */
ln_parser_t*
ln_newParser(ln_ctx ctx,
	json_object *prscnf)
{
	ln_parser_t *node = NULL;
	json_object *json;
	const char *val;
	prsid_t prsid;
	struct ln_type_pdag *custType = NULL;
	const char *name = NULL;
	const char *textconf = json_object_to_json_string(prscnf);
	int assignedPrio = DFLT_USR_PARSER_PRIO;
	int parserPrio;

	json_object_object_get_ex(prscnf, "type", &json);
	if(json == NULL) {
		ln_errprintf(ctx, 0, "parser type missing in config: %s",
			json_object_to_json_string(prscnf));
		goto done;
	}
	val = json_object_get_string(json);
	if(*val == '@') {
		prsid = PRS_CUSTOM_TYPE;
		custType = ln_pdagFindType(ctx, val, 0);
		parserPrio = 16; /* hopefully relatively specific... */
		if(custType == NULL) {
			ln_errprintf(ctx, 0, "unknown user-defined type '%s'", val);
			goto done;
		}
	} else {
		prsid = ln_parserName2ID(val);
		if(prsid == PRS_INVALID) {
			ln_errprintf(ctx, 0, "invalid field type '%s'", val);
			goto done;
		}
		parserPrio = parser_lookup_table[prsid].prio;
	}

	json_object_object_get_ex(prscnf, "name", &json);
	if(json == NULL || !strcmp(json_object_get_string(json), "-")) {
		name = NULL;
	} else {
		name = strdup(json_object_get_string(json));
	}

	json_object_object_get_ex(prscnf, "priority", &json);
	if(json != NULL) {
		assignedPrio = json_object_get_int(json);
	}
	LN_DBGPRINTF(ctx, "assigned priority is %d", assignedPrio);

	/* we need to remove already processed items from the config, so
	 * that we can pass the remaining parameters to the parser.
	 */
	json_object_object_del(prscnf, "type");
	json_object_object_del(prscnf, "priority");
	if(name != NULL)
		json_object_object_del(prscnf, "name");

	/* got all data items */
	if((node = calloc(1, sizeof(ln_parser_t))) == NULL) {
		LN_DBGPRINTF(ctx, "lnNewParser: alloc node failed");
		free((void*)name);
		goto done;
	}

	node->node = NULL;
	node->prio = ((assignedPrio << 8) & 0xffffff00) | (parserPrio & 0xff);
	node->name = name;
	node->prsid = prsid;
	node->conf = strdup(textconf);
	if(prsid == PRS_CUSTOM_TYPE) {
		node->custType = custType;
	} else {
		if(parser_lookup_table[prsid].construct != NULL) {
			parser_lookup_table[prsid].construct(ctx, prscnf, &node->parser_data);
		}
	}
done:
	return node;
}


struct ln_pdag*
ln_newPDAG(ln_ctx ctx)
{
	struct ln_pdag *dag;

	if((dag = calloc(1, sizeof(struct ln_pdag))) == NULL)
		goto done;
	
	dag->refcnt = 1;
	dag->ctx = ctx;
	ctx->nNodes++;
done:	return dag;
}

/* note: we must NOT free the parser itself, because
 * it is stored inside a parser table (so no single
 * alloc for the parser!).
 */
static void
pdagDeletePrs(ln_ctx ctx, ln_parser_t *const __restrict__ prs)
{
	// TODO: be careful here: once we move to real DAG from tree, we
	// cannot simply delete the next node! (refcount? something else?)
	if(prs->node != NULL)
		ln_pdagDelete(prs->node);
	free((void*)prs->name);
	free((void*)prs->conf);
	if(prs->parser_data != NULL)
		parser_lookup_table[prs->prsid].destruct(ctx, prs->parser_data);
}

void
ln_pdagDelete(struct ln_pdag *const __restrict__ pdag)
{
	if(pdag == NULL)
		goto done;

	LN_DBGPRINTF(pdag->ctx, "delete %p[%d]: %s", pdag, pdag->refcnt, pdag->rb_id);
	--pdag->refcnt;
	if(pdag->refcnt > 0)
		goto done;

	if(pdag->tags != NULL)
		json_object_put(pdag->tags);

	for(int i = 0 ; i < pdag->nparsers ; ++i) {
		pdagDeletePrs(pdag->ctx, pdag->parsers+i);
	}
	free(pdag->parsers);
	free((void*)pdag->rb_id);
	free((void*)pdag->rb_file);
	free(pdag);
done:	return;
}


/**
 * pdag optimizer step: literal path compaction
 *
 * We compress as much as possible and evalute the path down to
 * the first non-compressable element. Note that we must NOT
 * compact those literals that are either terminal nodes OR
 * contain names so that the literal is to be parsed out.
 */
static inline int
optLitPathCompact(ln_ctx ctx, ln_parser_t *prs)
{
	int r = 0;

	while(prs != NULL) {
		/* note the NOT prefix in the condition below! */
		if(!(   prs->prsid == PRS_LITERAL
		     && prs->name == NULL
		     && prs->node->flags.isTerminal == 0
		     && prs->node->refcnt == 1
		     && prs->node->nparsers == 1
		     /* we need to do some checks on the child as well */
		     && prs->node->parsers[0].prsid == PRS_LITERAL
		     && prs->node->parsers[0].name == NULL
		     && prs->node->parsers[0].node->refcnt == 1)
		  )
			goto done;

		/* ok, we have two compactable literals in a row, let's compact the nodes */
		ln_parser_t *child_prs = prs->node->parsers;
		LN_DBGPRINTF(ctx, "opt path compact: add %p to %p", child_prs, prs);
		CHKR(ln_combineData_Literal(prs->parser_data, child_prs->parser_data));
		ln_pdag *const node_del = prs->node;
		prs->node = child_prs->node;
		child_prs->node = NULL; /* remove, else this would be destructed! */
		ln_pdagDelete(node_del);
	}
done:
	return r;
}


static int
qsort_parserCmp(const void *v1, const void *v2)
{
	const ln_parser_t *const p1 = (const ln_parser_t *const) v1;
	const ln_parser_t *const p2 = (const ln_parser_t *const) v2;
	return p1->prio - p2->prio;
}

static int
ln_pdagComponentOptimize(ln_ctx ctx, struct ln_pdag *const dag)
{
	int r = 0;

for(int i = 0 ; i < dag->nparsers ; ++i) { /* TODO: remove when confident enough */
	ln_parser_t *prs = dag->parsers+i;
	LN_DBGPRINTF(ctx, "pre sort, parser %d:%s[%d]", i, prs->name, prs->prio);
}
	/* first sort parsers in priority order */
	if(dag->nparsers > 1) {
		qsort(dag->parsers, dag->nparsers, sizeof(ln_parser_t), qsort_parserCmp);
	}
for(int i = 0 ; i < dag->nparsers ; ++i) { /* TODO: remove when confident enough */
	ln_parser_t *prs = dag->parsers+i;
	LN_DBGPRINTF(ctx, "post sort, parser %d:%s[%d]", i, prs->name, prs->prio);
}

	/* now on to rest of processing */
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *prs = dag->parsers+i;
		LN_DBGPRINTF(dag->ctx, "optimizing %p: field %d type '%s', name '%s': '%s':",
			prs->node, i, parserName(prs->prsid), prs->name,
			(prs->prsid == PRS_LITERAL) ?  ln_DataForDisplayLiteral(dag->ctx, prs->parser_data)
				: "UNKNOWN");

		optLitPathCompact(ctx, prs);

		ln_pdagComponentOptimize(ctx, prs->node);
	}
	return r;
}


static void
deleteComponentID(struct ln_pdag *const __restrict__ dag)
{
	free((void*)dag->rb_id);
	dag->rb_id = NULL;
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *prs = dag->parsers+i;
		deleteComponentID(prs->node);
	}
}
/* fixes rb_ids for this node as well as it predecessors.
 * This is required if the ALTERNATIVE parser type is used,
 * which will create component IDs for each of it's invocations.
 * As such, we do not only fix the string, but know that all
 * children also need fixning. We do this be simply deleting
 * all of their rb_ids, as we know they will be visited again.
 * Note: if we introduce the same situation by new functionality,
 * we may need to review this code here as well. Also note
 * that the component ID will not be 100% correct after our fix,
 * because that ID could acutally be created by two sets of rules.
 * But this is the best we can do.
 */
static void
fixComponentID(struct ln_pdag *const __restrict__ dag, const char *const new)
{
	char *updated;
	const char *const curr = dag->rb_id;
	int i;
	int len = (int) strlen(curr);
	for(i = 0 ; i < len ; ++i){
		if(curr[i] != new [i])
			break;
	}
	if(i >= 1 && curr[i-1] == '%')
		--i;
	if(asprintf(&updated, "%.*s[%s|%s]", i, curr, curr+i, new+i) == -1)
		goto done;
	deleteComponentID(dag);
	dag->rb_id = updated;
done:	return;
}
/**
 * Assign human-readable identifiers (names) to each node. These are
 * later used in stats, debug output and whereever else this may make
 * sense.
 */
static void
ln_pdagComponentSetIDs(ln_ctx ctx, struct ln_pdag *const dag, const char *prefix)
{
	char *id = NULL;

	if(prefix == NULL)
		goto done;
	if(dag->rb_id == NULL) {
		dag->rb_id = strdup(prefix);
	} else {
		LN_DBGPRINTF(ctx, "rb_id already exists - fixing as good as "
			"possible. This happens with ALTERNATIVE parser. "
			"old: '%s', new: '%s'",
			dag->rb_id, prefix);
		fixComponentID(dag, prefix);
		LN_DBGPRINTF(ctx, "\"fixed\" rb_id: %s", dag->rb_id);
		prefix = dag->rb_id;
	}
	/* now on to rest of processing */
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *prs = dag->parsers+i;
		if(prs->prsid == PRS_LITERAL) {
			if(prs->name == NULL) {
				if(asprintf(&id, "%s%s", prefix,
					ln_DataForDisplayLiteral(dag->ctx, prs->parser_data)) == -1)
					goto done;
			} else {
				if(asprintf(&id, "%s%%%s:%s:%s%%", prefix,
					prs->name,
					parserName(prs->prsid),
					ln_DataForDisplayLiteral(dag->ctx, prs->parser_data)) == -1)
					goto done;
			}
		} else {
			if(asprintf(&id, "%s%%%s:%s%%", prefix,
				prs->name ? prs->name : "-",
				parserName(prs->prsid)) == -1)
					goto done;
		}
		ln_pdagComponentSetIDs(ctx, prs->node, id);
		free(id);
	}
done:	return;
}

/**
 * Optimize the pdag.
 * This includes all components.
 */
int
ln_pdagOptimize(ln_ctx ctx)
{
	int r = 0;

	for(int i = 0 ; i < ctx->nTypes ; ++i) {
		LN_DBGPRINTF(ctx, "optimizing component %s\n", ctx->type_pdags[i].name);
		ln_pdagComponentOptimize(ctx, ctx->type_pdags[i].pdag);
		ln_pdagComponentSetIDs(ctx, ctx->type_pdags[i].pdag, "");
	}

	LN_DBGPRINTF(ctx, "optimizing main pdag component");
	ln_pdagComponentOptimize(ctx, ctx->pdag);
	LN_DBGPRINTF(ctx, "finished optimizing main pdag component");
	ln_pdagComponentSetIDs(ctx, ctx->pdag, "");
LN_DBGPRINTF(ctx, "---AFTER OPTIMIZATION------------------");
ln_displayPDAG(ctx);
LN_DBGPRINTF(ctx, "=======================================");
	return r;
}


#define LN_INTERN_PDAG_STATS_NPARSERS 100
/* data structure for pdag statistics */
struct pdag_stats {
	int nodes;
	int term_nodes;
	int parsers;
	int max_nparsers;
	int nparsers_cnt[LN_INTERN_PDAG_STATS_NPARSERS];
	int nparsers_100plus;
	int *prs_cnt;
};

/**
 * Recursive step of statistics gatherer.
 */
static int
ln_pdagStatsRec(ln_ctx ctx, struct ln_pdag *const dag, struct pdag_stats *const stats)
{
	if(dag->flags.visited)
		return 0;
	dag->flags.visited = 1;
	stats->nodes++;
	if(dag->flags.isTerminal)
		stats->term_nodes++;
	if(dag->nparsers > stats->max_nparsers)
		stats->max_nparsers = dag->nparsers;
	if(dag->nparsers >= LN_INTERN_PDAG_STATS_NPARSERS)
		stats->nparsers_100plus++;
	else
		stats->nparsers_cnt[dag->nparsers]++;
	stats->parsers += dag->nparsers;
	int max_path = 0;
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *prs = dag->parsers+i;
		if(prs->prsid != PRS_CUSTOM_TYPE)
			stats->prs_cnt[prs->prsid]++;
		const int path_len = ln_pdagStatsRec(ctx, prs->node, stats);
		if(path_len > max_path)
			max_path = path_len;
	}
	return max_path + 1;
}


static void
ln_pdagStatsExtended(ln_ctx ctx, struct ln_pdag *const dag, FILE *const fp, int level)
{
	char indent[2048];

	if(level > 1023)
		level = 1023;
	memset(indent, ' ', level * 2);
	indent[level * 2] = '\0';

	if(dag->stats.called > 0) {
		fprintf(fp, "%u, %u, %s\n",
			dag->stats.called,
			dag->stats.backtracked,
			dag->rb_id);
	}
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *const prs = dag->parsers+i;
		if(prs->node->stats.called > 0) {
			ln_pdagStatsExtended(ctx, prs->node, fp, level+1);
		}
	}
}

/**
 * Gather pdag statistics for a *specific* pdag.
 *
 * Data is sent to given file ptr.
 */
static void
ln_pdagStats(ln_ctx ctx, struct ln_pdag *const dag, FILE *const fp, const int extendedStats)
{
	struct pdag_stats *const stats = calloc(1, sizeof(struct pdag_stats));
	stats->prs_cnt = calloc(NPARSERS, sizeof(int));
	//ln_pdagClearVisited(ctx);
	const int longest_path = ln_pdagStatsRec(ctx, dag, stats);

	fprintf(fp, "nodes.............: %4d\n", stats->nodes);
	fprintf(fp, "terminal nodes....: %4d\n", stats->term_nodes);
	fprintf(fp, "parsers entries...: %4d\n", stats->parsers);
	fprintf(fp, "longest path......: %4d\n", longest_path);

	fprintf(fp, "Parser Type Counts:\n");
	for(prsid_t i = 0 ; i < NPARSERS ; ++i) {
		if(stats->prs_cnt[i] != 0)
			fprintf(fp, "\t%20s: %d\n", parserName(i), stats->prs_cnt[i]);
	}

	int pp = 0;
	fprintf(fp, "Parsers per Node:\n");
	fprintf(fp, "\tmax:\t%4d\n", stats->max_nparsers);
	for(int i = 0 ; i < 100 ; ++i) {
		pp += stats->nparsers_cnt[i];
		if(stats->nparsers_cnt[i] != 0)
			fprintf(fp, "\t%d:\t%4d\n", i, stats->nparsers_cnt[i]);
	}

	free(stats->prs_cnt);
	free(stats);
	
	if(extendedStats) {
		fprintf(fp, "Usage Statistics:\n"
			    "-----------------\n");
		fprintf(fp, "called, backtracked, rule\n");
		ln_pdagComponentClearVisited(dag);
		ln_pdagStatsExtended(ctx, dag, fp, 0);
	}
}


/**
 * Gather and output pdag statistics for the full pdag (ctx)
 * including all disconnected components (type defs).
 *
 * Data is sent to given file ptr.
 */
void
ln_fullPdagStats(ln_ctx ctx, FILE *const fp, const int extendedStats)
{
	if(ctx->ptree != NULL) {
		/* we need to handle the old cruft */
		ln_fullPTreeStats(ctx, fp, extendedStats);
		return;
	}

	fprintf(fp, "User-Defined Types\n"
	            "==================\n");
	fprintf(fp, "number types: %d\n", ctx->nTypes);
	for(int i = 0 ; i < ctx->nTypes ; ++i)
		fprintf(fp, "type: %s\n", ctx->type_pdags[i].name);

	for(int i = 0 ; i < ctx->nTypes ; ++i) {
		fprintf(fp, "\n"
			    "type PDAG: %s\n"
		            "----------\n", ctx->type_pdags[i].name);
		ln_pdagStats(ctx, ctx->type_pdags[i].pdag, fp, extendedStats);
	}

	fprintf(fp, "\n"
		    "Main PDAG\n"
	            "=========\n");
	ln_pdagStats(ctx, ctx->pdag, fp, extendedStats);

#ifdef	ADVANCED_STATS
	const uint64_t parsers_failed = advstats_parsers_called - advstats_parsers_success;
	fprintf(fp, "\n"
		    "Advanced Runtime Stats\n"
	            "======================\n");
	fprintf(fp, "These are actual number from analyzing the control flow "
		    "at runtime.\n");
	fprintf(fp, "Note that literal matching is also done via parsers. As such, \n"
		    "it is expected that fail rates increase with the size of the \n"
		    "rule base.\n");
	fprintf(fp, "\n");
	fprintf(fp, "Parser Calls:\n");
	fprintf(fp, "total....: %10" PRIu64 "\n", advstats_parsers_called);
	fprintf(fp, "succesful: %10" PRIu64 "\n", advstats_parsers_success);
	fprintf(fp, "failed...: %10" PRIu64 " [%d%%]\n",
		parsers_failed,
		(int) ((parsers_failed * 100) / advstats_parsers_called) );
	fprintf(fp, "\nIndividual Parser Calls "
		    "(never called parsers are not shown):\n");
	for(  size_t i = 0
	    ; i < sizeof(parser_lookup_table) / sizeof(struct ln_parser_info)
	    ; ++i) {
		if(parser_lookup_table[i].called > 0) {
			const uint64_t failed = parser_lookup_table[i].called
				- parser_lookup_table[i].success;
			fprintf(fp, "%20s: %10" PRIu64 " [%5.2f%%] "
				    "success: %10" PRIu64 " [%5.1f%%] "
				    "fail: %10" PRIu64 " [%5.1f%%]"
			            "\n",
				parser_lookup_table[i].name,
				parser_lookup_table[i].called,
				(float)(parser_lookup_table[i].called * 100)
				        / advstats_parsers_called,
				parser_lookup_table[i].success,
				(float)(parser_lookup_table[i].success * 100)
				        / parser_lookup_table[i].called,
				failed,
				(float)(failed * 100)
				        / parser_lookup_table[i].called
			       );
		}
	}

	uint64_t total_len;
	uint64_t total_cnt;
	fprintf(fp, "\n");
	fprintf(fp, "\n"
	            "Path Length Statistics\n"
	            "----------------------\n"
	            "The regular path length is the number of nodes being visited,\n"
		    "where each node potentially evaluates several parsers. The\n"
		    "parser call statistic is the number of parsers called along\n"
		    "the path. That number is higher, as multiple parsers may be\n"
		    "called at each node. The number of literal parser calls is\n"
		    "given explicitely, as they use almost no time to process.\n"
		    "\n"
		);
	total_len = 0;
	total_cnt = 0;
	fprintf(fp, "Path Length\n");
	for(int i = 0 ; i < ADVSTATS_MAX_ENTITIES ; ++i) {
		if(advstats_pathlens[i] > 0 ) {
			fprintf(fp, "%3d: %d\n", i, advstats_pathlens[i]);
			total_len += i * advstats_pathlens[i];
			total_cnt += advstats_pathlens[i];
		}
	}
	fprintf(fp, "avg: %f\n", (double) total_len / (double) total_cnt);
	fprintf(fp, "max: %d\n", advstats_max_pathlen);
	fprintf(fp, "\n");

	total_len = 0;
	total_cnt = 0;
	fprintf(fp, "Nbr Backtracked\n");
	for(int i = 0 ; i < ADVSTATS_MAX_ENTITIES ; ++i) {
		if(advstats_backtracks[i] > 0 ) {
			fprintf(fp, "%3d: %d\n", i, advstats_backtracks[i]);
			total_len += i * advstats_backtracks[i];
			total_cnt += advstats_backtracks[i];
		}
	}
	fprintf(fp, "avg: %f\n", (double) total_len / (double) total_cnt);
	fprintf(fp, "max: %d\n", advstats_max_backtracked);
	fprintf(fp, "\n");

	/* we calc some stats while we output */
	total_len = 0;
	total_cnt = 0;
	fprintf(fp, "Parser Calls\n");
	for(int i = 0 ; i < ADVSTATS_MAX_ENTITIES ; ++i) {
		if(advstats_parser_calls[i] > 0 ) {
			fprintf(fp, "%3d: %d\n", i, advstats_parser_calls[i]);
			total_len += i * advstats_parser_calls[i];
			total_cnt += advstats_parser_calls[i];
		}
	}
	fprintf(fp, "avg: %f\n", (double) total_len / (double) total_cnt);
	fprintf(fp, "max: %d\n", advstats_max_parser_calls);
	fprintf(fp, "\n");

	total_len = 0;
	total_cnt = 0;
	fprintf(fp, "LITERAL Parser Calls\n");
	for(int i = 0 ; i < ADVSTATS_MAX_ENTITIES ; ++i) {
		if(advstats_lit_parser_calls[i] > 0 ) {
			fprintf(fp, "%3d: %d\n", i, advstats_lit_parser_calls[i]);
			total_len += i * advstats_lit_parser_calls[i];
			total_cnt += advstats_lit_parser_calls[i];
		}
	}
	fprintf(fp, "avg: %f\n", (double) total_len / (double) total_cnt);
	fprintf(fp, "max: %d\n", advstats_max_lit_parser_calls);
	fprintf(fp, "\n");
#endif
}

/**
 * Check if the provided dag is a leaf. This means that it
 * does not contain any subdags.
 * @return 1 if it is a leaf, 0 otherwise
 */
static inline int
isLeaf(struct ln_pdag *dag)
{
	return dag->nparsers == 0 ? 1 : 0;
}


/**
 * Add a parser instance to the pdag at the current position.
 *
 * @param[in] ctx
 * @param[in] prscnf json parser config *object* (no array!)
 * @param[in] pdag current pdag position (to which parser is to be added)
 * @param[in/out] nextnode contains point to the next node, either
 *            an existing one or one newly created.
 *
 * The nextnode parameter permits to use this function to create
 * multiple parsers alternative parsers with a single run. To do so,
 * set nextnode=NULL on first call. On successive calls, keep the
 * value. If a value is present, we will not accept non-identical
 * parsers which point to different nodes - this will result in an
 * error.
 *
 * IMPORTANT: the caller is responsible to update its pdag pointer
 *            to the nextnode value when he is done adding parsers.
 *
 * If a parser of the same type with identical data already exists,
 * it is "resued", which means the function is effectively used to
 * walk the path. This is used during parser construction to
 * navigate to new parts of the pdag.
 */
static int
ln_pdagAddParserInstance(ln_ctx ctx,
	json_object *const __restrict__ prscnf,
	struct ln_pdag *const __restrict__ pdag,
	struct ln_pdag **nextnode)
{
	int r;
	ln_parser_t *newtab;
	LN_DBGPRINTF(ctx, "ln_pdagAddParserInstance: %s, nextnode %p",
		json_object_to_json_string(prscnf), *nextnode);
	ln_parser_t *const parser = ln_newParser(ctx, prscnf);
	CHKN(parser);
	LN_DBGPRINTF(ctx, "pdag: %p, parser %p", pdag, parser);
	/* check if we already have this parser, if so, merge
	 */
	int i;
	for(i = 0 ; i < pdag->nparsers ; ++i) {
		LN_DBGPRINTF(ctx, "parser  comparison:\n%s\n%s",  pdag->parsers[i].conf, parser->conf);
		if(   pdag->parsers[i].prsid == parser->prsid
		   && !strcmp(pdag->parsers[i].conf, parser->conf)) {
		   	// FIXME: the current ->conf object is depending on
			//        the order of json elements. We should do a JSON
			//        comparison (a bit more complex). For now, it
			//        works like we do it now.
			// FIXME: if nextnode is set, check we can actually combine,
			//        else err out
			*nextnode = pdag->parsers[i].node;
			r = 0;
			LN_DBGPRINTF(ctx, "merging with pdag %p", pdag);
			pdagDeletePrs(ctx, parser); /* no need for data items */
			goto done;
		}
	}
	/* if we reach this point, we have a new parser type */
	if(*nextnode == NULL) {
		CHKN(*nextnode = ln_newPDAG(ctx)); /* we need a new node */
	} else {
		(*nextnode)->refcnt++;
	}
	parser->node = *nextnode;
	newtab = realloc(pdag->parsers, (pdag->nparsers+1) * sizeof(ln_parser_t));
	CHKN(newtab);
	pdag->parsers = newtab;
	memcpy(pdag->parsers+pdag->nparsers, parser, sizeof(ln_parser_t));
	pdag->nparsers++;

	r = 0;

done:
	free(parser);
	return r;
}

static int ln_pdagAddParserInternal(ln_ctx ctx, struct ln_pdag **pdag, const int mode, json_object *const prscnf,
struct ln_pdag **nextnode);

/**
 * add parsers to current pdag. This is used
 * to add parsers stored in an array. The mode specifies
 * how parsers shall be added.
 */
#define PRS_ADD_MODE_SEQ 0
#define PRS_ADD_MODE_ALTERNATIVE 1
static int
ln_pdagAddParsers(ln_ctx ctx,
	json_object *const prscnf,
	const int mode,
	struct ln_pdag **pdag,
	struct ln_pdag **p_nextnode)
{
	int r = LN_BADCONFIG;
	struct ln_pdag *dag = *pdag;
	struct ln_pdag *nextnode = *p_nextnode;
	
	const int lenarr = json_object_array_length(prscnf);
	for(int i = 0 ; i < lenarr ; ++i) {
		struct json_object *const curr_prscnf =
			json_object_array_get_idx(prscnf, i);
		LN_DBGPRINTF(ctx, "parser %d: %s", i, json_object_to_json_string(curr_prscnf));
		if(json_object_get_type(curr_prscnf) == json_type_array) {
			struct ln_pdag *local_dag = dag;
			CHKR(ln_pdagAddParserInternal(ctx, &local_dag, mode,
						      curr_prscnf, &nextnode));
			if(mode == PRS_ADD_MODE_SEQ) {
				dag = local_dag;
			}
		} else {
			CHKR(ln_pdagAddParserInstance(ctx, curr_prscnf, dag, &nextnode));
		}
		if(mode == PRS_ADD_MODE_SEQ) {
			dag = nextnode;
			*p_nextnode = nextnode;
			nextnode = NULL;
		}
	}

	if(mode != PRS_ADD_MODE_SEQ)
		dag = nextnode;
	*pdag = dag;
	r = 0;
done:
	return r;
}

/* add a json parser config object. Note that this object may contain
 * multiple parser instances. Additionally, moves the pdag object to
 * the next node, which is either newly created or previously existed.
 */
static int
ln_pdagAddParserInternal(ln_ctx ctx, struct ln_pdag **pdag,
	const int mode, json_object *const prscnf, struct ln_pdag **nextnode)
{
	int r = LN_BADCONFIG;
	struct ln_pdag *dag = *pdag;
	
	LN_DBGPRINTF(ctx, "ln_pdagAddParserInternal: %s", json_object_to_json_string(prscnf));
	if(json_object_get_type(prscnf) == json_type_object) {
		/* check for special types we need to handle here */
		struct json_object *json;
		json_object_object_get_ex(prscnf, "type", &json);
		const char *const ftype = json_object_get_string(json);
		if(!strcmp(ftype, "alternative")) {
			json_object_object_get_ex(prscnf, "parser", &json);
			if(json_object_get_type(json) != json_type_array) {
				ln_errprintf(ctx, 0, "alternative type needs array of parsers. "
					"Object: '%s', type is %s",
					json_object_to_json_string(prscnf),
					json_type_to_name(json_object_get_type(json)));
				goto done;
			}
			CHKR(ln_pdagAddParsers(ctx, json, PRS_ADD_MODE_ALTERNATIVE, &dag, nextnode));
		} else {
			CHKR(ln_pdagAddParserInstance(ctx, prscnf, dag, nextnode));
			if(mode == PRS_ADD_MODE_SEQ)
				dag = *nextnode;
		}
	} else if(json_object_get_type(prscnf) == json_type_array) {
		CHKR(ln_pdagAddParsers(ctx, prscnf, PRS_ADD_MODE_SEQ, &dag, nextnode));
	} else {
		ln_errprintf(ctx, 0, "bug: prscnf object of wrong type. Object: '%s'",
			json_object_to_json_string(prscnf));
		goto done;
	}
	*pdag = dag;

done:
	return r;
}

/* add a json parser config object. Note that this object may contain
 * multiple parser instances. Additionally, moves the pdag object to
 * the next node, which is either newly created or previously existed.
 */
int
ln_pdagAddParser(ln_ctx ctx, struct ln_pdag **pdag, json_object *const prscnf)
{
	struct ln_pdag *nextnode = NULL;
	int r = ln_pdagAddParserInternal(ctx, pdag, PRS_ADD_MODE_SEQ, prscnf, &nextnode);
	json_object_put(prscnf);
	return r;
}


void
ln_displayPDAGComponent(struct ln_pdag *dag, int level)
{
	char indent[2048];

	if(level > 1023)
		level = 1023;
	memset(indent, ' ', level * 2);
	indent[level * 2] = '\0';

	LN_DBGPRINTF(dag->ctx, "%ssubDAG%s %p (children: %d parsers, ref %d) [called %u, backtracked %u]",
		     indent, dag->flags.isTerminal ? " [TERM]" : "", dag, dag->nparsers, dag->refcnt,
		     dag->stats.called, dag->stats.backtracked);

for(int i = 0 ; i < dag->nparsers ; ++i) {
	ln_parser_t *const prs = dag->parsers+i;
	LN_DBGPRINTF(dag->ctx, "%sfield type '%s', name '%s': '%s': called %u", indent,
		parserName(prs->prsid),
		dag->parsers[i].name,
		(prs->prsid == PRS_LITERAL) ?  ln_DataForDisplayLiteral(dag->ctx, prs->parser_data) : "UNKNOWN",
	dag->parsers[i].node->stats.called);
}
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *const prs = dag->parsers+i;
		LN_DBGPRINTF(dag->ctx, "%sfield type '%s', name '%s': '%s':", indent,
			parserName(prs->prsid),
			dag->parsers[i].name,
			(prs->prsid == PRS_LITERAL) ?  ln_DataForDisplayLiteral(dag->ctx, prs->parser_data) :
				"UNKNOWN");
		if(prs->prsid == PRS_REPEAT) {
			struct data_Repeat *const data = (struct data_Repeat*) prs->parser_data;
			LN_DBGPRINTF(dag->ctx, "%sparser:", indent);
			ln_displayPDAGComponent(data->parser, level + 1);
			LN_DBGPRINTF(dag->ctx, "%swhile:", indent);
			ln_displayPDAGComponent(data->while_cond, level + 1);
			LN_DBGPRINTF(dag->ctx, "%send repeat def", indent);
		}
		ln_displayPDAGComponent(dag->parsers[i].node, level + 1);
	}
}


void ln_displayPDAGComponentAlternative(struct ln_pdag *dag, int level)
{
	char indent[2048];

	if(level > 1023)
		level = 1023;
	memset(indent, ' ', level * 2);
	indent[level * 2] = '\0';

	LN_DBGPRINTF(dag->ctx, "%s%p[ref %d]: %s", indent, dag, dag->refcnt, dag->rb_id);
	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_displayPDAGComponentAlternative(dag->parsers[i].node, level + 1);
	}
}


/* developer debug aid, to be used for example as follows:
 * LN_DBGPRINTF(dag->ctx, "---------------------------------------");
 * ln_displayPDAG(dag);
 * LN_DBGPRINTF(dag->ctx, "=======================================");
 */
void
ln_displayPDAG(ln_ctx ctx)
{
	ln_pdagClearVisited(ctx);
	for(int i = 0 ; i < ctx->nTypes ; ++i) {
		LN_DBGPRINTF(ctx, "COMPONENT: %s", ctx->type_pdags[i].name);
		ln_displayPDAGComponent(ctx->type_pdags[i].pdag, 0);
	}

	LN_DBGPRINTF(ctx, "MAIN COMPONENT:");
	ln_displayPDAGComponent(ctx->pdag, 0);

	LN_DBGPRINTF(ctx, "MAIN COMPONENT (alternative):");
	ln_displayPDAGComponentAlternative(ctx->pdag, 0);
}


/* the following is a quick hack, which should be moved to the
 * string class.
 */
static inline void dotAddPtr(es_str_t **str, void *p)
{
	char buf[64];
	int i;
	i = snprintf(buf, sizeof(buf), "l%p", p);
	es_addBuf(str, buf, i);
}
struct data_Literal { const char *lit; }; // TODO remove when this hack is no longe needed
/**
 * recursive handler for DOT graph generator.
 */
static void
ln_genDotPDAGGraphRec(struct ln_pdag *dag, es_str_t **str)
{
	char s_refcnt[16];
	LN_DBGPRINTF(dag->ctx, "in dot: %p, visited %d", dag, (int) dag->flags.visited);
	if(dag->flags.visited)
		return; /* already processed this subpart */
	dag->flags.visited = 1;
	dotAddPtr(str, dag);
	snprintf(s_refcnt, sizeof(s_refcnt), "%d", dag->refcnt);
	s_refcnt[sizeof(s_refcnt)-1] = '\0';
	es_addBufConstcstr(str, " [ label=\"");
	es_addBuf(str, s_refcnt, strlen(s_refcnt));
	es_addBufConstcstr(str, "\"");

	if(isLeaf(dag)) {
		es_addBufConstcstr(str, " style=\"bold\"");
	}
	es_addBufConstcstr(str, "]\n");

	/* display field subdags */

	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *const prs = dag->parsers+i;
		dotAddPtr(str, dag);
		es_addBufConstcstr(str, " -> ");
		dotAddPtr(str, prs->node);
		es_addBufConstcstr(str, " [label=\"");
		es_addBuf(str, parserName(prs->prsid), strlen(parserName(prs->prsid)));
		es_addBufConstcstr(str, ":");
		//es_addStr(str, node->name);
		if(prs->prsid == PRS_LITERAL) {
			for(const char *p = ((struct data_Literal*)prs->parser_data)->lit ; *p ; ++p) {
				// TODO: handle! if(*p == '\\')
					//es_addChar(str, '\\');
				if(*p != '\\' && *p != '"')
					es_addChar(str, *p);
			}
		}
		es_addBufConstcstr(str, "\"");
		es_addBufConstcstr(str, " style=\"dotted\"]\n");
		ln_genDotPDAGGraphRec(prs->node, str);
	}
}


void
ln_genDotPDAGGraph(struct ln_pdag *dag, es_str_t **str)
{
	ln_pdagClearVisited(dag->ctx);
	es_addBufConstcstr(str, "digraph pdag {\n");
	ln_genDotPDAGGraphRec(dag, str);
	es_addBufConstcstr(str, "}\n");
}

/**
 * recursive handler for statistics DOT graph generator.
 */
static void
ln_genStatsDotPDAGGraphRec(struct ln_pdag *dag, FILE *const __restrict__ fp)
{
	if(dag->flags.visited)
		return; /* already processed this subpart */
	dag->flags.visited = 1;
	fprintf(fp, "l%p [ label=\"%u:%u\"", dag,
		dag->stats.called, dag->stats.backtracked);

	if(isLeaf(dag)) {
		fprintf(fp, " style=\"bold\"");
	}
	fprintf(fp, "]\n");

	/* display field subdags */

	for(int i = 0 ; i < dag->nparsers ; ++i) {
		ln_parser_t *const prs = dag->parsers+i;
		if(prs->node->stats.called == 0)
			continue;
		fprintf(fp, "l%p -> l%p [label=\"", dag, prs->node);
		if(prs->prsid == PRS_LITERAL) {
			for(const char *p = ((struct data_Literal*)prs->parser_data)->lit ; *p ; ++p) {
				if(*p != '\\' && *p != '"')
					fputc(*p, fp);
			}
		} else {
			fprintf(fp, "%s", parserName(prs->prsid));
		}
		fprintf(fp, "\" style=\"dotted\"]\n");
		ln_genStatsDotPDAGGraphRec(prs->node, fp);
	}
}


static void
ln_genStatsDotPDAGGraph(struct ln_pdag *dag, FILE *const fp)
{
	ln_pdagClearVisited(dag->ctx);
	fprintf(fp, "digraph pdag {\n");
	ln_genStatsDotPDAGGraphRec(dag, fp);
	fprintf(fp, "}\n");
}

void
ln_fullPDagStatsDOT(ln_ctx ctx, FILE *const fp)
{
	ln_genStatsDotPDAGGraph(ctx->pdag, fp);
}


static inline int
addOriginalMsg(const char *str, const size_t strLen, struct json_object *const json)
{
	int r = 1;
	struct json_object *value;

	value = json_object_new_string_len(str, strLen);
	if (value == NULL) {
		goto done;
	}
	json_object_object_add(json, ORIGINAL_MSG_KEY, value);
	r = 0;
done:
	return r;
}

static char *
strrev(char *const __restrict__ str)
{
	char ch;
	size_t i = strlen(str)-1,j=0;
	while(i>j)
	{
		ch = str[i];
		str[i]= str[j];
		str[j] = ch;
		i--;
		j++;
	}
	return str;
}

/* note: "originalmsg" is NOT added as metadata in order to keep
 * backwards compatible.
 */
static inline void
addRuleMetadata(npb_t *const __restrict__ npb,
	struct json_object *const json,
	struct ln_pdag *const __restrict__ endNode)
{
	ln_ctx ctx = npb->ctx;
	struct json_object *meta = NULL;
	struct json_object *meta_rule = NULL;
	struct json_object *value;

	if(ctx->opts & LN_CTXOPT_ADD_RULE) { /* matching rule mockup */
		if(meta_rule == NULL)
			meta_rule = json_object_new_object();
		char *cstr = strrev(es_str2cstr(npb->rule, NULL));
		json_object_object_add(meta_rule, RULE_MOCKUP_KEY,
			json_object_new_string(cstr));
		free(cstr);
	}

	if(ctx->opts & LN_CTXOPT_ADD_RULE_LOCATION) {
		if(meta_rule == NULL)
			meta_rule = json_object_new_object();
		struct json_object *const location = json_object_new_object();
		value = json_object_new_string(endNode->rb_file);
		json_object_object_add(location, "file", value);
		value = json_object_new_int((int)endNode->rb_lineno);
		json_object_object_add(location, "line", value);
		json_object_object_add(meta_rule, RULE_LOCATION_KEY, location);
	}

	if(meta_rule != NULL) {
		if(meta == NULL)
			meta = json_object_new_object();
		json_object_object_add(meta, META_RULE_KEY, meta_rule);
	}

#ifdef	ADVANCED_STATS
	/* complete execution path */
	if(ctx->opts & LN_CTXOPT_ADD_EXEC_PATH) {
		if(meta == NULL)
			meta = json_object_new_object();
		char hdr[128];
		const size_t lenhdr
		  = snprintf(hdr, sizeof(hdr), "[PATHLEN:%d, PARSER CALLS gen:%d, literal:%d]",
			     npb->astats.pathlen, npb->astats.parser_calls,
			     npb->astats.lit_parser_calls);
		es_addBuf(&npb->astats.exec_path, hdr, lenhdr);
		char * cstr = es_str2cstr(npb->astats.exec_path, NULL);
		value = json_object_new_string(cstr);
		if (value != NULL) {
			json_object_object_add(meta, EXEC_PATH_KEY, value);
		}
		free(cstr);
	}
#endif

	if(meta != NULL)
		json_object_object_add(json, META_KEY, meta);
}


/**
 * add unparsed string to event.
 */
static inline int
addUnparsedField(const char *str, const size_t strLen, const size_t offs, struct json_object *json)
{
	int r = 1;
	struct json_object *value;

	CHKR(addOriginalMsg(str, strLen, json));
	
	value = json_object_new_string(str + offs);
	if (value == NULL) {
		goto done;
	}
	json_object_object_add(json, UNPARSED_DATA_KEY, value);

	r = 0;
done:
	return r;
}


/* Do some fixup to the json that we cannot do on a lower layer */
static int
fixJSON(struct ln_pdag *dag,
	struct json_object **value,
	struct json_object *json,
	const ln_parser_t *const prs)

{
	int r = LN_WRONGPARSER;

	if(prs->name ==  NULL) {
		if (*value != NULL) {
			/* Free the unneeded value */
			json_object_put(*value);
		}
	} else if(prs->name[0] == '.' && prs->name[1] == '\0') {
		if(json_object_get_type(*value) == json_type_object) {
			struct json_object_iterator it = json_object_iter_begin(*value);
			struct json_object_iterator itEnd = json_object_iter_end(*value);
			while (!json_object_iter_equal(&it, &itEnd)) {
				struct json_object *const val = json_object_iter_peek_value(&it);
				json_object_get(val);
				json_object_object_add(json, json_object_iter_peek_name(&it), val);
				json_object_iter_next(&it);
			}
			json_object_put(*value);
		} else {
			LN_DBGPRINTF(dag->ctx, "field name is '.', but json type is %s",
				json_type_to_name(json_object_get_type(*value)));
			json_object_object_add_ex(json, prs->name, *value,
				JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
		}
	} else {
		int isDotDot = 0;
		struct json_object *valDotDot = NULL;
		if(json_object_get_type(*value) == json_type_object) {
			/* TODO: this needs to be speeded up by just checking the first
			 * member and ensuring there is only one member. This requires
			 * extensions to libfastjson.
			 */
			int nSubobj = 0;
			struct json_object_iterator it = json_object_iter_begin(*value);
			struct json_object_iterator itEnd = json_object_iter_end(*value);
			while (!json_object_iter_equal(&it, &itEnd)) {
				++nSubobj;
				const char *key = json_object_iter_peek_name(&it);
				if(key[0] == '.' && key[1] == '.' && key[2] == '\0') {
					isDotDot = 1;
					valDotDot = json_object_iter_peek_value(&it);
				} else {
					isDotDot = 0;
				}
				json_object_iter_next(&it);
			}
			if(nSubobj != 1)
				isDotDot = 0;
		}
		if(isDotDot) {
			LN_DBGPRINTF(dag->ctx, "subordinate field name is '..', combining");
			json_object_get(valDotDot);
			json_object_put(*value);
			json_object_object_add_ex(json, prs->name, valDotDot,
				JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
		} else {
			json_object_object_add_ex(json, prs->name, *value,
				JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
		}
	}
	r = 0;
	return r;
}

// TODO: streamline prototype when done with changes

static int
tryParser(npb_t *const __restrict__ npb,
	struct ln_pdag *dag,
	size_t *offs,
	size_t *const __restrict__ pParsed,
	struct json_object **value,
	const ln_parser_t *const prs
	)
{
	int r;
	struct ln_pdag *endNode = NULL;
	size_t parsedTo = npb->parsedTo;
#	ifdef	ADVANCED_STATS
	char hdr[16];
	const size_t lenhdr
	  = snprintf(hdr, sizeof(hdr), "%d:", npb->astats.recursion_level);
	es_addBuf(&npb->astats.exec_path, hdr, lenhdr);
	if(prs->prsid == PRS_LITERAL) {
		es_addChar(&npb->astats.exec_path, '\'');
		es_addBuf(&npb->astats.exec_path,
			  ln_DataForDisplayLiteral(dag->ctx,
				prs->parser_data),
			  strlen(ln_DataForDisplayLiteral(dag->ctx,
				prs->parser_data))
			 );
		es_addChar(&npb->astats.exec_path, '\'');
	} else if(parser_lookup_table[prs->prsid].parser
			== ln_v2_parseCharTo) {
		es_addBuf(&npb->astats.exec_path,
			  ln_DataForDisplayCharTo(dag->ctx,
				prs->parser_data),
			  strlen(ln_DataForDisplayCharTo(dag->ctx,
				prs->parser_data))
			 );
	} else {
		es_addBuf(&npb->astats.exec_path,
			parserName(prs->prsid),
			strlen(parserName(prs->prsid)) );
	}
	es_addChar(&npb->astats.exec_path, ',');
#	endif

	if(prs->prsid == PRS_CUSTOM_TYPE) {
		if(*value == NULL)
			*value = json_object_new_object();
		LN_DBGPRINTF(dag->ctx, "calling custom parser '%s'", prs->custType->name);
		r = ln_normalizeRec(npb, prs->custType->pdag, *offs, 1, *value, &endNode);
		LN_DBGPRINTF(dag->ctx, "called CUSTOM PARSER '%s', result %d, "
			"offs %zd, *pParsed %zd", prs->custType->name, r, *offs, *pParsed);
		*pParsed = npb->parsedTo - *offs;
		#ifdef	ADVANCED_STATS
		es_addBuf(&npb->astats.exec_path, hdr, lenhdr);
		es_addBuf(&npb->astats.exec_path, "[R:USR],", 8);
		#endif
	} else {
		r = parser_lookup_table[prs->prsid].parser(npb,
			offs, prs->parser_data, pParsed, (prs->name == NULL) ? NULL : value);
	}
	LN_DBGPRINTF(npb->ctx, "parser lookup returns %d, pParsed %zu", r, *pParsed);
	npb->parsedTo = parsedTo;

#ifdef	ADVANCED_STATS
	++advstats_parsers_called;
	++npb->astats.parser_calls;
	if(prs->prsid == PRS_LITERAL)
		++npb->astats.lit_parser_calls;
	if(r == 0)
		++advstats_parsers_success;
	if(prs->prsid != PRS_CUSTOM_TYPE) {
		++parser_lookup_table[prs->prsid].called;
		if(r == 0)
			++parser_lookup_table[prs->prsid].success;
	}
#endif
	return r;
}


static void
add_str_reversed(npb_t *const __restrict__ npb,
	const char *const __restrict__ str,
	const size_t len)
{
	ssize_t i;
	for(i = len - 1 ; i >= 0 ; --i) {
		es_addChar(&npb->rule, str[i]);
	}
}


/* Add the current parser to the mockup rule.
 * Note: we add reversed strings, because we can call this
 * function effectively only when walking upwards the tree.
 * This means deepest entries come first. We solve this somewhat
 * elegantly by reversion strings, and then reversion the string
 * once more when we emit it, so that we get the right order.
 */
static inline void
add_rule_to_mockup(npb_t *const __restrict__ npb,
	const ln_parser_t *const __restrict__ prs)
{
	if(prs->prsid == PRS_LITERAL) {
		const char *const val =
			  ln_DataForDisplayLiteral(npb->ctx,
				prs->parser_data);
		add_str_reversed(npb, val, strlen(val));
	} else {
		/* note: name/value order must also be reversed! */
		es_addChar(&npb->rule, '%');
		add_str_reversed(npb,
			parserName(prs->prsid),
			strlen(parserName(prs->prsid)) );
		es_addChar(&npb->rule, ':');
		if(prs->name == NULL) {
			es_addChar(&npb->rule, '-');
		} else {
			add_str_reversed(npb, prs->name, strlen(prs->name));
		}
		es_addChar(&npb->rule, '%');
	}
}

/**
 * Recursive step of the normalizer. It walks the parse dag and calls itself
 * recursively when this is appropriate. It also implements backtracking in
 * those (hopefully rare) cases where it is required.
 *
 * @param[in] dag current tree to process
 * @param[in] string string to be matched against (the to-be-normalized data)
 * @param[in] strLen length of the to-be-matched string
 * @param[in] offs start position in input data
 * @param[out] pPrasedTo ptr to position up to which the the parsing succed in max
 * @param[in/out] json ... that is being created during normalization
 * @param[out] endNode if a match was found, this is the matching node (undefined otherwise)
 *
 * @return regular liblognorm error code (0->OK, something else->error)
 * TODO: can we use parameter block to prevent pushing params to the stack?
 */
int
ln_normalizeRec(npb_t *const __restrict__ npb,
	struct ln_pdag *dag,
	const size_t offs,
	const int bPartialMatch,
	struct json_object *json,
	struct ln_pdag **endNode
	)
{
	int r = LN_WRONGPARSER;
	int localR;
	size_t i;
	size_t iprs;
	size_t parsedTo = npb->parsedTo;
	size_t parsed = 0;
	struct json_object *value;
	
LN_DBGPRINTF(dag->ctx, "%zu: enter parser, dag node %p, json %p", offs, dag, json);

	++dag->stats.called;
#ifdef	ADVANCED_STATS
	++npb->astats.pathlen;
	++npb->astats.recursion_level;
#endif

	/* now try the parsers */
	for(iprs = 0 ; iprs < dag->nparsers && r != 0 ; ++iprs) {
		const ln_parser_t *const prs = dag->parsers + iprs;
		if(dag->ctx->debug) {
			LN_DBGPRINTF(dag->ctx, "%zu/%d:trying '%s' parser for field '%s', "
				     "data '%s'",
					offs, bPartialMatch, parserName(prs->prsid), prs->name,
					(prs->prsid == PRS_LITERAL)
					 ? ln_DataForDisplayLiteral(dag->ctx, prs->parser_data)
				 	 : "UNKNOWN");
		}
		i = offs;
		value = NULL;
		localR = tryParser(npb, dag, &i, &parsed, &value, prs);
		if(localR == 0) {
			parsedTo = i + parsed;
			/* potential hit, need to verify */
			LN_DBGPRINTF(dag->ctx, "%zu: potential hit, trying subtree %p",
				offs, prs->node);
			r = ln_normalizeRec(npb, prs->node, parsedTo,
					    bPartialMatch, json, endNode);
			LN_DBGPRINTF(dag->ctx, "%zu: subtree returns %d, parsedTo %zu", offs, r, parsedTo);
			if(r == 0) {
				LN_DBGPRINTF(dag->ctx, "%zu: parser matches at %zu", offs, i);
				CHKR(fixJSON(dag, &value, json, prs));
				if(npb->ctx->opts & LN_CTXOPT_ADD_RULE) {
					add_rule_to_mockup(npb, prs);
				}
			} else {
				++dag->stats.backtracked;
				#ifdef	ADVANCED_STATS
					++npb->astats.backtracked;
					es_addBuf(&npb->astats.exec_path, "[B]", 3);
				#endif
				LN_DBGPRINTF(dag->ctx, "%zu nonmatch, backtracking required, parsed to=%zu",
						offs, parsedTo);
				if (value != NULL) { /* Free the value if it was created */
					json_object_put(value);
				}
			}
		}
		/* did we have a longer parser --> then update */
		if(parsedTo > npb->parsedTo)
			npb->parsedTo = parsedTo;
		LN_DBGPRINTF(dag->ctx, "parsedTo %zu, *pParsedTo %zu", parsedTo, npb->parsedTo);
	}

LN_DBGPRINTF(dag->ctx, "offs %zu, strLen %zu, isTerm %d", offs, npb->strLen, dag->flags.isTerminal);
	if(dag->flags.isTerminal && (offs == npb->strLen || bPartialMatch)) {
		*endNode = dag;
		r = 0;
		goto done;
	}

done:
	LN_DBGPRINTF(dag->ctx, "%zu returns %d, pParsedTo %zu, parsedTo %zu",
		offs, r, npb->parsedTo, parsedTo);
#	ifdef	ADVANCED_STATS
	--npb->astats.recursion_level;
#	endif
	return r;
}

int
ln_normalize(ln_ctx ctx, const char *str, const size_t strLen, struct json_object **json_p)
{
	int r;
	struct ln_pdag *endNode = NULL;
	/* old cruft */
	if(ctx->version == 1) {
		r = ln_v1_normalize(ctx, str, strLen, json_p);
		goto done;
	}
	/* end old cruft */

	npb_t npb;
	memset(&npb, 0, sizeof(npb));
	npb.ctx = ctx;
	npb.str = str;
	npb.strLen = strLen;
	if(ctx->opts & LN_CTXOPT_ADD_RULE) {
		npb.rule = es_newStr(1024);
	}
#	ifdef ADVANCED_STATS
	npb.astats.exec_path = es_newStr(1024);
#	endif

	if(*json_p == NULL) {
		CHKN(*json_p = json_object_new_object());
	}

	r = ln_normalizeRec(&npb, ctx->pdag, 0, 0, *json_p, &endNode);

	if(ctx->debug) {
		if(r == 0) {
			LN_DBGPRINTF(ctx, "final result for normalizer: parsedTo %zu, endNode %p, "
				     "isTerminal %d, tagbucket %p",
				     npb.parsedTo, endNode, endNode->flags.isTerminal, endNode->tags);
		} else {
			LN_DBGPRINTF(ctx, "final result for normalizer: parsedTo %zu, endNode %p",
				     npb.parsedTo, endNode);
		}
	}
	LN_DBGPRINTF(ctx, "DONE, final return is %d", r);
	if(r == 0 && endNode->flags.isTerminal) {
		/* success, finalize event */
		if(endNode->tags != NULL) {
			/* add tags to an event */
			json_object_get(endNode->tags);
			json_object_object_add(*json_p, "event.tags", endNode->tags);
			CHKR(ln_annotate(ctx, *json_p, endNode->tags));
		}
		if(ctx->opts & LN_CTXOPT_ADD_ORIGINALMSG) {
			/* originalmsg must be kept outside of metadata for
			 * backward compatibility reasons.
			 */
			json_object_object_add(*json_p, ORIGINAL_MSG_KEY,
				json_object_new_string_len(str, strLen));
		}
		addRuleMetadata(&npb, *json_p, endNode);
		r = 0;
	} else {
		addUnparsedField(str, strLen, npb.parsedTo, *json_p);
	}

	if(ctx->opts & LN_CTXOPT_ADD_RULE) {
		es_deleteStr(npb.rule);
	}

#ifdef	ADVANCED_STATS
	if(r != 0)
		es_addBuf(&npb.astats.exec_path, "[FAILED]", 8);
	else if(!endNode->flags.isTerminal)
		es_addBuf(&npb.astats.exec_path, "[FAILED:NON-TERMINAL]", 21);
	if(npb.astats.pathlen < ADVSTATS_MAX_ENTITIES)
		advstats_pathlens[npb.astats.pathlen]++;
	if(npb.astats.pathlen > advstats_max_pathlen) {
		advstats_max_pathlen = npb.astats.pathlen;
	}
	if(npb.astats.backtracked < ADVSTATS_MAX_ENTITIES)
		advstats_backtracks[npb.astats.backtracked]++;
	if(npb.astats.backtracked > advstats_max_backtracked) {
		advstats_max_backtracked = npb.astats.backtracked;
	}

	/* parser calls */
	if(npb.astats.parser_calls < ADVSTATS_MAX_ENTITIES)
		advstats_parser_calls[npb.astats.parser_calls]++;
	if(npb.astats.parser_calls > advstats_max_parser_calls) {
		advstats_max_parser_calls = npb.astats.parser_calls;
	}
	if(npb.astats.lit_parser_calls < ADVSTATS_MAX_ENTITIES)
		advstats_lit_parser_calls[npb.astats.lit_parser_calls]++;
	if(npb.astats.lit_parser_calls > advstats_max_lit_parser_calls) {
		advstats_max_lit_parser_calls = npb.astats.lit_parser_calls;
	}

	es_deleteStr(npb.astats.exec_path);
#endif
done:	return r;
}
