"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Either_1 = require("./Either");
var eitherT = require("./EitherT");
var IO_1 = require("./IO");
var function_1 = require("./function");
var eitherTIO = eitherT.getEitherT(IO_1.io);
exports.URI = 'IOEither';
var eitherTfold = eitherT.fold(IO_1.io);
var eitherTmapLeft = eitherT.mapLeft(IO_1.io);
var eitherTbimap = eitherT.bimap(IO_1.io);
/**
 * `IOEither<L, A>` represents a synchronous computation that either yields a value of type `A` or fails yielding an
 * error of type `L`. If you want to represent a synchronous computation that never fails, please see {@link IO}.
 * @data
 * @constructor IOEither
 * @since 1.6.0
 */
var IOEither = /** @class */ (function () {
    function IOEither(value) {
        this.value = value;
    }
    /**
     * Runs the inner io
     */
    IOEither.prototype.run = function () {
        return this.value.run();
    };
    IOEither.prototype.map = function (f) {
        return new IOEither(eitherTIO.map(this.value, f));
    };
    IOEither.prototype.ap = function (fab) {
        return new IOEither(eitherTIO.ap(fab.value, this.value));
    };
    /**
     * Flipped version of {@link ap}
     */
    IOEither.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two effectful actions, keeping only the result of the first
     */
    IOEither.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two effectful actions, keeping only the result of the second
     */
    IOEither.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    IOEither.prototype.chain = function (f) {
        return new IOEither(eitherTIO.chain(function (a) { return f(a).value; }, this.value));
    };
    IOEither.prototype.fold = function (left, right) {
        return eitherTfold(left, right, this.value);
    };
    IOEither.prototype.mapLeft = function (f) {
        return new IOEither(eitherTmapLeft(f)(this.value));
    };
    IOEither.prototype.orElse = function (f) {
        return new IOEither(this.value.chain(function (e) { return e.fold(function (l) { return f(l).value; }, function (a) { return eitherTIO.of(a); }); }));
    };
    IOEither.prototype.alt = function (fy) {
        return this.orElse(function () { return fy; });
    };
    IOEither.prototype.bimap = function (f, g) {
        return new IOEither(eitherTbimap(this.value, f, g));
    };
    return IOEither;
}());
exports.IOEither = IOEither;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new IOEither(eitherTIO.of(a));
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
var alt = function (fx, fy) {
    return fx.alt(fy);
};
var bimap = function (fa, f, g) {
    return fa.bimap(f, g);
};
var eitherTright = eitherT.right(IO_1.io);
/**
 * @function
 * @since 1.6.0
 */
exports.right = function (fa) {
    return new IOEither(eitherTright(fa));
};
var eitherTleft = eitherT.left(IO_1.io);
/**
 * @function
 * @since 1.6.0
 */
exports.left = function (fa) {
    return new IOEither(eitherTleft(fa));
};
var eitherTfromEither = eitherT.fromEither(IO_1.io);
/**
 * @function
 * @since 1.6.0
 */
exports.fromEither = function (fa) {
    return new IOEither(eitherTfromEither(fa));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromLeft = function (l) {
    return exports.fromEither(Either_1.left(l));
};
/**
 * Use {@link tryCatch2v}
 * @function
 * @since 1.6.0
 * @deprecated
 */
exports.tryCatch = function (f, onerror) {
    if (onerror === void 0) { onerror = Either_1.toError; }
    return exports.tryCatch2v(f, onerror);
};
/**
 * @function
 * @since 1.11.0
 */
exports.tryCatch2v = function (f, onerror) {
    return new IOEither(new IO_1.IO(function () { return Either_1.tryCatch2v(f, onerror); }));
};
/**
 * @instance
 * @since 1.6.0
 */
exports.ioEither = {
    URI: exports.URI,
    bimap: bimap,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    alt: alt
};
