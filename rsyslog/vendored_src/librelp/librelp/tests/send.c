/* A minimal RELP sender using librelp
 *
 * Copyright 2014 Mathias Nyman
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <unistd.h>
#include <getopt.h>
#include <string.h>
#include "librelp.h"

#define TRY(f) if(f != RELP_RET_OK) { printf("failure in: %s\n", #f); return 1; }

static relpEngine_t *pRelpEngine;

static void __attribute__((format(printf, 1, 2)))
dbgprintf(char *fmt, ...)
{
	va_list ap;
	char pszWriteBuf[32*1024+1];

	va_start(ap, fmt);
	vsnprintf(pszWriteBuf, sizeof(pszWriteBuf), fmt, ap);
	va_end(ap);
	fprintf(stderr, "send.c: %s", pszWriteBuf);
}



void print_usage(void)
{
	printf("Usage: send -t <SERVER> -p <PORTNUM> -m <MESSAGE>\n");
}

static void
onErr( __attribute__((unused)) void *pUsr, char *objinfo, char* errmesg, __attribute__((unused)) relpRetVal errcode)
{
	printf("send: error '%s', object '%s'\n", errmesg, objinfo);
}

static void
onGenericErr(char *objinfo, char* errmesg, __attribute__((unused)) relpRetVal errcode)
{
	printf("send: librelp error '%s', object '%s'\n", errmesg, objinfo);
}

static void
onAuthErr( __attribute__((unused)) void *pUsr, char *authinfo,
	char* errmesg, __attribute__((unused)) relpRetVal errcode)
{
	printf("send: authentication error '%s', object '%s'\n", errmesg, authinfo);
}

int main(int argc, char *argv[]) {

	int c;
	int option_index = 0;
	unsigned char *port = NULL;
	unsigned char *target = NULL;
	const char *pMsg = NULL;
	size_t lenMsg = 0;
	unsigned timeout = 90;
	int verbose = 0;
	int protFamily = 2; /* IPv4=2, IPv6=10 */
	relpClt_t *pRelpClt = NULL;
	int bEnableTLS = 0;
	char *caCertFile = NULL;
	char *myCertFile = NULL;
	char *myPrivKeyFile = NULL;
	char *permittedPeer = NULL;
	char *authMode = NULL;
	size_t msgDataLen = 0;
	int len = 0;
	char *msgData = NULL;;

	static struct option long_options[] =
	{
		{"ca", required_argument, 0, 'x'},
		{"cert", required_argument, 0, 'y'},
		{"key", required_argument, 0, 'z'},
		{"peer", required_argument, 0, 'P'},
		{"authmode", required_argument, 0, 'a'},
		{0, 0, 0, 0}
	};

	while((c = getopt_long(argc, argv, "a:d:m:P:p:Tt:vx:y:z:", long_options, &option_index)) != -1) {
		switch(c) {
		case 'a':
			authMode = optarg;
			break;
		case 'd':
			len = atoi(optarg);
			if(len < 128) {
				fprintf(stderr, "send.c: messageSize has invalid "
					"value: %d - must be at least 128\n", len);
				exit(1);
			} else {
				msgDataLen = len;
			}
			break;
		case 'v':
			verbose = 1;
			break;
		case 'm':
			pMsg = (const char*)optarg;
			lenMsg = strlen(pMsg);
			break;
		case 'P':
			permittedPeer = optarg;
			break;
		case 'p':
			port = (unsigned char*)optarg;
			break;
		case 'T':
			bEnableTLS = 1;
			break;
		case 't':
			target = (unsigned char*)optarg;
			break;
		case 'x':
			caCertFile = optarg;
			break;
		case 'y':
			myCertFile = optarg;
			break;
		case 'z':
			myPrivKeyFile = optarg;
			break;
		default:
			print_usage();
			exit(1);
		}
	}


	if(msgDataLen != 0 && msgDataLen < lenMsg) {
		fprintf(stderr, "send.c: message is larger than configured message size!\n");
		exit(1);
	}

	if (target == NULL || port == NULL || pMsg == NULL) {
		printf("Missing parameter\n");
		print_usage();
		exit(1);
	}

	if(authMode != NULL) {
		if(permittedPeer == NULL || caCertFile == NULL || myCertFile == NULL
		|| myPrivKeyFile == NULL) {
			printf("send: parameter missing; certificates and permittedPeer required\n");
			exit(1);
		}
	}

	if(caCertFile != NULL || myCertFile != NULL || myPrivKeyFile != NULL) {
		if(bEnableTLS == 0) {
			printf("send: Certificates were specified, but TLS was "
			       "not enabled! Will continue without TLS. To enable "
			       "it use parameter \"-T\"\n");
			exit(1);
		}
	}



	TRY(relpEngineConstruct(&pRelpEngine));
	TRY(relpEngineSetDbgprint(pRelpEngine, verbose ? dbgprintf : NULL));

	TRY(relpEngineSetOnErr(pRelpEngine, onErr));
	TRY(relpEngineSetOnGenericErr(pRelpEngine, onGenericErr));
	TRY(relpEngineSetOnAuthErr(pRelpEngine, onAuthErr));

	TRY(relpEngineSetEnableCmd(pRelpEngine, (unsigned char*)"syslog", eRelpCmdState_Required));
	TRY(relpEngineCltConstruct(pRelpEngine, &pRelpClt));
	TRY(relpCltSetTimeout(pRelpClt, timeout));

	if(bEnableTLS) {
		TRY(relpCltEnableTLS(pRelpClt));
		if(authMode != NULL) {
			TRY(relpCltSetAuthMode(pRelpClt, authMode));
			TRY(relpCltSetCACert(pRelpClt, caCertFile));
			TRY(relpCltSetOwnCert(pRelpClt, myCertFile));
			TRY(relpCltSetPrivKey(pRelpClt, myPrivKeyFile));
			TRY(relpCltAddPermittedPeer(pRelpClt, permittedPeer));
		}
	}

	TRY(relpCltConnect(pRelpClt, protFamily, port, target));

	if(msgDataLen != 0) {

		msgData = malloc(msgDataLen+1);
		strcpy(msgData, pMsg);

		size_t i;
		for(i=0; i < (msgDataLen-lenMsg); i++) {
			*(msgData+lenMsg+i) = i%10 + '0';
		}

		msgData[msgDataLen] = '\0';
		pMsg = msgData;
		lenMsg = msgDataLen;
	}

	TRY(relpCltSendSyslog(pRelpClt, (unsigned char *)pMsg, lenMsg));

	if(msgDataLen != 0) {
		free((char *)pMsg);
	}
	TRY(relpEngineCltDestruct(pRelpEngine, &pRelpClt));
	TRY(relpEngineDestruct(&pRelpEngine));

	return 0;
}
