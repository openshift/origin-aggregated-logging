/**
 * @file pdag.h
 * @brief The parse DAG object.
 * @class ln_pdag pdag.h
 *//*
 * Copyright 2015 by Rainer Gerhards and Adiscon GmbH.
 *
 * Released under ASL 2.0.
 */
#ifndef LIBLOGNORM_PDAG_H_INCLUDED
#define	LIBLOGNORM_PDAG_H_INCLUDED
#include <stdio.h>
#include <libestr.h>
#include <stdint.h>

#define META_KEY "metadata"
#define ORIGINAL_MSG_KEY "originalmsg"
#define UNPARSED_DATA_KEY "unparsed-data"
#define EXEC_PATH_KEY "exec-path"
#define META_RULE_KEY "rule"
#define RULE_MOCKUP_KEY "mockup"
#define RULE_LOCATION_KEY "location"

typedef struct ln_pdag ln_pdag; /**< the parse DAG object */
typedef struct ln_parser_s ln_parser_t;
typedef struct npb npb_t;
typedef uint8_t prsid_t;

struct ln_type_pdag;

/**
 * parser IDs.
 *
 * These identfy a parser. VERY IMPORTANT: they must start at zero
 * and continously increment. They must exactly match the index
 * of the respective parser inside the parser lookup table.
 */
#define PRS_LITERAL			0
#define PRS_REPEAT			1
#if 0
#define PRS_DATE_RFC3164		1
#define PRS_DATE_RFC5424		2
#define PRS_NUMBER			3
#define PRS_FLOAT			4
#define PRS_HEXNUMBER			5
#define PRS_KERNEL_TIMESTAMP		6
#define PRS_WHITESPACE			7
#define PRS_IPV4			8
#define PRS_IPV6			9
#define PRS_WORD			10
#define PRS_ALPHA			11
#define PRS_REST			12
#define PRS_OP_QUOTED_STRING		13
#define PRS_QUOTED_STRING		14
#define PRS_DATE_ISO			15
#define PRS_TIME_24HR			16
#define PRS_TIME_12HR			17
#define PRS_DURATION			18
#define PRS_CISCO_INTERFACE_SPEC	19
#define PRS_NAME_VALUE_LIST		20
#define PRS_JSON			21
#define PRS_CEE_SYSLOG			22
#define PRS_MAC48			23
#define PRS_CEF				24
#define PRS_CHECKPOINT_LEA		25
#define PRS_v2_IPTABLES			26
#define PRS_STRING_TO			27
#define PRS_CHAR_TO			28
#define PRS_CHAR_SEP			29
#endif

#define PRS_CUSTOM_TYPE			254
#define PRS_INVALID			255
/* NOTE: current max limit on parser ID is 255, because we use uint8_t
 * for the prsid_t type (which gains cache performance). If more parsers
 * come up, the type must be modified.
 */
/**
 * object describing a specific parser instance.
 */
struct ln_parser_s {
	prsid_t prsid;		/**< parser ID (for lookup table) */
	ln_pdag *node;		/**< node to branch to if parser succeeded */
	void *parser_data;	/**< opaque data that the field-parser understands */
	struct ln_type_pdag *custType;	/**< points to custom type, if such is used */
	int prio;		/**< priority (combination of user- and parser-specific parts) */
	const char *name;	/**< field name */
	const char *conf;	/**< configuration as printable json for comparison reasons */
};

struct ln_parser_info {
	const char *name;	/**< parser name as used in rule base */
	int prio;		/**< parser specific prio in range 0..255 */
	int (*construct)(ln_ctx ctx, json_object *const json, void **);
	int (*parser)(npb_t *npb, size_t*, void *const,
				  size_t*, struct json_object **); /**< parser to use */
	void (*destruct)(ln_ctx, void *const); /* note: destructor is only needed if parser data exists */
#ifdef ADVANCED_STATS
	uint64_t called;
	uint64_t success;
#endif
};


/* parse DAG object
 */
struct ln_pdag {
	ln_ctx ctx;			/**< our context */ // TODO: why do we need it?
	ln_parser_t *parsers;		/* array of parsers to try */
	prsid_t nparsers;		/**< current table size (prsid_t slighly abused) */
	struct {
		unsigned isTerminal:1;	/**< designates this node a terminal sequence */
		unsigned visited:1;	/**< work var for recursive procedures */
	} flags;
	struct json_object *tags;	/**< tags to assign to events of this type */
	int refcnt;			/**< reference count for deleting tracking */
	struct {
		unsigned called;
		unsigned backtracked;	/**< incremented when backtracking was initiated */
		unsigned terminated;
	} stats;	/**< usage statistics */
	const char *rb_id;		/**< human-readable rulebase identifier, for stats etc */
	
	// experimental, move outside later
	const char *rb_file;
	unsigned int rb_lineno;
};

#ifdef ADVANCED_STATS
struct advstats {
	int pathlen;
	int parser_calls;		/**< parser calls in general during path */
	int lit_parser_calls;		/**< same just for the literal parser */
	int backtracked;
	int recursion_level;
	es_str_t *exec_path;
};
#define ADVSTATS_MAX_ENTITIES 100
extern int advstats_max_pathlen;
extern int advstats_pathlens[ADVSTATS_MAX_ENTITIES];
extern int advstats_max_backtracked;
extern int advstats_backtracks[ADVSTATS_MAX_ENTITIES];
#endif

/** the "normalization paramater block" (npb)
 * This structure is passed to all normalization routines including
 * parsers. It contains data that commonly needs to be passed,
 * like the to be parsed string and its length, as well as read/write
 * data which is used to track information over the general
 * normalization process (like the execution path, if requested).
 * The main purpose is to save stack writes by eliminating the
 * need for using multiple function parameters. Note that it
 * must be carefully considered which items to add to the
 * npb - those that change from recursion level to recursion
 * level are NOT to be placed here.
 */
struct npb {
	ln_ctx ctx;
	const char *str;		/**< to-be-normalized message */
	size_t strLen;			/**< length of it */
	size_t parsedTo;		/**< up to which byte could this be parsed? */
	es_str_t *rule;			/**< a mock-up of the rule used to parse */
	es_str_t *exec_path;
#ifdef ADVANCED_STATS
	int pathlen;
	int backtracked;
	int recursion_level;
	struct advstats astats;
#endif
};

/* Methods */

/**
 * Allocates and initializes a new parse DAG node.
 * @memberof ln_pdag
 *
 * @param[in] ctx current library context. This MUST match the
 * 		context of the parent.
 * @param[in] parent pointer to the new node inside the parent
 *
 * @return pointer to new node or NULL on error
 */
struct ln_pdag* ln_newPDAG(ln_ctx ctx);


/**
 * Free a parse DAG and destruct all members.
 * @memberof ln_pdag
 *
 * @param[in] DAG pointer to pdag to free
 */
void ln_pdagDelete(struct ln_pdag *DAG);


/**
 * Add parser to dag node.
 * Works on unoptimzed dag.
 *
 * @param[in] pdag pointer to pdag to modify
 * @param[in] parser parser definition
 * @returns 0 on success, something else otherwise
 */
int ln_pdagAddParser(ln_ctx ctx, struct ln_pdag **pdag, json_object *);


/**
 * Display the content of a pdag (debug function).
 * This is a debug aid that spits out a textual representation
 * of the provided pdag via multiple calls of the debug callback.
 *
 * @param DAG pdag to display
 */
void ln_displayPDAG(ln_ctx ctx);


/**
 * Generate a DOT graph.
 * Well, actually it does not generate the graph itself, but a
 * control file that is suitable for the GNU DOT tool. Such a file
 * can be very useful to understand complex sample databases
 * (not to mention that it is probably fun for those creating
 * samples).
 * The dot commands are appended to the provided string.
 *
 * @param[in] DAG pdag to display
 * @param[out] str string which receives the DOT commands.
 */
void ln_genDotPDAGGraph(struct ln_pdag *DAG, es_str_t **str);


/**
 * Build a pdag based on the provided string, but only if necessary.
 * The passed-in DAG is searched and traversed for str. If a node exactly
 * matching str is found, that node is returned. If no exact match is found,
 * a new node is added. Existing nodes may be split, if a so-far common
 * prefix needs to be split in order to add the new node.
 *
 * @param[in] DAG root of the current DAG
 * @param[in] str string to be added
 * @param[in] offs offset into str where match needs to start
 *             (this is required for recursive calls to handle
 *             common prefixes)
 * @return NULL on error, otherwise the pdag leaf that
 *         corresponds to the parameters passed.
 */
struct ln_pdag * ln_buildPDAG(struct ln_pdag *DAG, es_str_t *str, size_t offs);


prsid_t ln_parserName2ID(const char *const __restrict__ name);
int ln_pdagOptimize(ln_ctx ctx);
void ln_fullPdagStats(ln_ctx ctx, FILE *const fp, const int);
ln_parser_t * ln_newLiteralParser(ln_ctx ctx, char lit);
ln_parser_t* ln_newParser(ln_ctx ctx, json_object *const prscnf);
struct ln_type_pdag * ln_pdagFindType(ln_ctx ctx, const char *const __restrict__ name, const int bAdd);
void ln_fullPDagStatsDOT(ln_ctx ctx, FILE *const fp);

/* friends */
int
ln_normalizeRec(npb_t *const __restrict__ npb,
	struct ln_pdag *dag,
	const size_t offs,
	const int bPartialMatch,
	struct json_object *json,
	struct ln_pdag **endNode
);

#endif /* #ifndef LOGNORM_PDAG_H_INCLUDED */
