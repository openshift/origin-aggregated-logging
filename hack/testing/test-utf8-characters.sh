#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

exec ${OS_O_A_L_DIR}/test/utf8-characters.sh
