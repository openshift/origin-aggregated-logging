[![npm version](https://badge.fury.io/js/unbzip2-stream.svg)](http://badge.fury.io/js/unbzip2-stream)

unbzip2-stream
===
streaming bzip2 compresser in pure JS for Node and browserify.

Buffers
---
When browserified, the stream emits instances of [feross/buffer](https://github.com/feross/buffer) instead of raw Uint8Arrays to have a consistant API across browsers and Node.

Usage
---
``` js
var bz2 = require('unbzip2-stream');
var fs = require('fs');

// decompress test.bz2 and output the result
fs.createReadStream('./test.bz2').pipe(bz2()).pipe(process.stdout);
```

Also see [test/browser/download.js](https://github.com/regular/unbzip2-stream/blob/master/test/browser/download.js) for an example of decompressing a file while downloading.

Tests
---
To run tests in Node:

    npm run test

To run tests in PhantomJS

    npm run browser-test

To run a test in chrome (if installed) that downloads and decompresses a linux kernel
(open the browser's console to see the output)

    curl http://s-macke.github.io/jor1k/bin/vmlinux.bin.bz2 > test/fixtures/vmlinux.bin.bz2
    bzip2 -d < test/fixtures/vmlinux.bin.bz2 > test/fixtures/vmlinux.bin
    npm run download-test
