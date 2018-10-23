#!/bin/bash

set -euxo pipefail

# due to the patch for the closures, we have to
# rename ClosurePool.c to Closure.c and rename
# ClosurePool.h to Closure.h - they look like this:
# ... "ext/ffi_c/ClosurePool.c".freeze, "ext/ffi_c/ClosurePool.h".freeze,
sed -e 's@ext/ffi_c/ClosurePool.c@ext/ffi_c/Closure.c@' \
    -e 's@ext/ffi_c/ClosurePool.h@ext/ffi_c/Closure.h@' \
    -i $1
