#!/bin/bash
# added 2013-12-10 by Rgerhards
# This file is part of the rsyslog project, released under ASL 2.0
echo ===============================================================================
echo \[sndrcv_relp_tls.sh\]: testing sending and receiving via relp with TLS enabled
. $srcdir/sndrcv_drvr.sh sndrcv_relp_tls 50000
