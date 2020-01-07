"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var ChainRec_1 = require("./ChainRec");
var function_1 = require("./function");
exports.URI = 'Identity';
/**
 * @data
 * @constructor Identity
 * @since 1.0.0
 */
var Identity = /** @class */ (function () {
    function Identity(value) {
        this.value = value;
    }
    Identity.prototype.map = function (f) {
        return new Identity(f(this.value));
    };
    Identity.prototype.ap = function (fab) {
        return this.map(fab.value);
    };
    /**
     * Flipped version of {@link ap}
     */
    Identity.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    Identity.prototype.chain = function (f) {
        return f(this.value);
    };
    Identity.prototype.reduce = function (b, f) {
        return f(b, this.value);
    };
    Identity.prototype.alt = function (fx) {
        return this;
    };
    /**
     * Lazy version of {@link alt}
     *
     * @example
     * import { Identity } from 'fp-ts/lib/Identity'
     *
     * const a = new Identity(1)
     * assert.deepEqual(a.orElse(() => new Identity(2)), a)
     *
     * @since 1.6.0
     */
    Identity.prototype.orElse = function (fx) {
        return this;
    };
    Identity.prototype.extract = function () {
        return this.value;
    };
    Identity.prototype.extend = function (f) {
        return of(f(this));
    };
    Identity.prototype.fold = function (f) {
        return f(this.value);
    };
    Identity.prototype.inspect = function () {
        return this.toString();
    };
    Identity.prototype.toString = function () {
        return "new Identity(" + function_1.toString(this.value) + ")";
    };
    return Identity;
}());
exports.Identity = Identity;
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (setoid) {
    return {
        equals: function (x, y) { return setoid.equals(x.value, y.value); }
    };
};
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new Identity(a);
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
var reduce = function (fa, b, f) {
    return fa.reduce(b, f);
};
var foldMap = function (M) { return function (fa, f) {
    return f(fa.value);
}; };
var foldr = function (fa, b, f) {
    return f(fa.value, b);
};
var alt = function (fx, fy) {
    return fx.alt(fy);
};
var extend = function (ea, f) {
    return ea.extend(f);
};
var extract = function (fa) {
    return fa.value;
};
var chainRec = function (a, f) {
    return new Identity(ChainRec_1.tailRec(function (a) { return f(a).value; }, a));
};
var traverse = function (F) { return function (ta, f) {
    return F.map(f(ta.value), of);
}; };
var sequence = function (F) { return function (ta) {
    return F.map(ta.value, of);
}; };
/**
 * @instance
 * @since 1.0.0
 */
exports.identity = {
    URI: exports.URI,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    reduce: reduce,
    foldMap: foldMap,
    foldr: foldr,
    traverse: traverse,
    sequence: sequence,
    alt: alt,
    extract: extract,
    extend: extend,
    chainRec: chainRec
};
