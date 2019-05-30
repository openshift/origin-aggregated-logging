adler32
========
> adler32 is not cryptographically strong, and is only used to sanity check that
> markup generated on the server matches the markup generated on the client.
> This implementation (a modified version of the SheetJS version) has been optimized
> for our use case, at the expense of conforming to the adler32 specification
> for non-ascii inputs.