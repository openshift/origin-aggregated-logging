# node-crypto
Easy (yet strong) encryption and decryption facilities for Node.js

This node module that can be used for easily encrypting and decrypting serializable objects. The ease-of-use comes from the fact that this module is opinionated in its (strong) choice of cryptographic algorithms, lengths, and iterations that cannot be overriden by its users.

Warning: if you encrypt a value with major version X of this library, it will only be properly decrypted by the same major version X of this library. If you upgrade to major version X+n of the library, values encrypted with major version X will decrypt to garbage with version X+n.

## Maintainers Notes

If you change encryption parameters so that the encrypted result is different from what the current latest release of this library would produce, make sure to bump up the major version of the library before releasing it.
