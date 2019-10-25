#!/bin/bash

set -euxo pipefail

# there is no way to disable signing using
# a flag to gem build or gem install - so just
# remove the problematic settings from the gemspec
sed -e '/^[ 	][ 	]*s[.]cert_chain[ 	=]/d' \
    -e '/^[     ][      ]*s[.]signing_key[       =]/d' \
    -i $1
