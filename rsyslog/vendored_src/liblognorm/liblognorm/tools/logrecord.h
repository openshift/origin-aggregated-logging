/* The (in-memory) format of a log record.
 *
 * A log record is sequence of nodes of different syntaxes. A log
 * record is described by a pointer to its root node.
 * The most important node type is literal text, which is always
 * assumed if no other syntax is detected. A full list of syntaxes
 * can be found below.
 *
 * Copyright 2015 Rainer Gerhards
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef LOGRECORD_H_INCLUDED
#define LOGRECORD_H_INCLUDED

#include <stdint.h>
/* log record node syntaxes
 * This "enumeration" starts at 0 and increments for each new
 * syntax. Note that we do not use an enum type so that we can
 * streamline the in-memory representation. For large sets of
 * log records to be held in main memory, this is important.
 */
#define LRN_SYNTAX_LITERAL_TEXT		0
#define LRN_SYNTAX_IPV4			1
#define LRN_SYNTAX_INT_POSITIVE		2
#define LRN_SYNTAX_DATE_RFC3164		3

struct logrec_node {
	struct logrec_node *next; /* NULL: end of record */
	int8_t ntype;
	union {
		char *ltext; /* the literal text */
		int64_t number; /* all integer types */
	} val;
};
typedef struct logrec_node logrecord_t;
#endif  /* ifndef LOGRECORD_H_INCLUDED */
