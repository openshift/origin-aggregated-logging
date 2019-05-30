"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
var Ord_1 = require("./Ord");
exports.URI = 'Tuple';
/**
 * @data
 * @constructor Tuple
 * @since 1.0.0
 */
var Tuple = /** @class */ (function () {
    function Tuple(fst, snd) {
        this.fst = fst;
        this.snd = snd;
    }
    Tuple.prototype.compose = function (ab) {
        return new Tuple(this.fst, ab.snd);
    };
    Tuple.prototype.map = function (f) {
        return new Tuple(this.fst, f(this.snd));
    };
    Tuple.prototype.bimap = function (f, g) {
        return new Tuple(f(this.fst), g(this.snd));
    };
    Tuple.prototype.extract = function () {
        return this.snd;
    };
    Tuple.prototype.extend = function (f) {
        return new Tuple(this.fst, f(this));
    };
    Tuple.prototype.reduce = function (b, f) {
        return f(b, this.snd);
    };
    /** Exchange the first and second components of a tuple */
    Tuple.prototype.swap = function () {
        return new Tuple(this.snd, this.fst);
    };
    Tuple.prototype.inspect = function () {
        return this.toString();
    };
    Tuple.prototype.toString = function () {
        return "new Tuple(" + function_1.toString(this.fst) + ", " + function_1.toString(this.snd) + ")";
    };
    Tuple.prototype.toTuple = function () {
        return [this.fst, this.snd];
    };
    return Tuple;
}());
exports.Tuple = Tuple;
var fst = function (fa) {
    return fa.fst;
};
var snd = function (fa) {
    return fa.snd;
};
var compose = function (bc, fa) {
    return fa.compose(bc);
};
var map = function (fa, f) {
    return fa.map(f);
};
var bimap = function (fla, f, g) {
    return fla.bimap(f, g);
};
var extract = snd;
var extend = function (fa, f) {
    return fa.extend(f);
};
var reduce = function (fa, b, f) {
    return fa.reduce(b, f);
};
var foldMap = function (M) { return function (fa, f) {
    return f(fa.snd);
}; };
var foldr = function (fa, b, f) {
    return f(fa.snd, b);
};
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (SA, SB) {
    return {
        equals: function (x, y) { return SA.equals(x.fst, y.fst) && SB.equals(x.snd, y.snd); }
    };
};
/**
 * To obtain the result, the `fst`s are `compare`d, and if they are `EQ`ual, the
 * `snd`s are `compare`d.
 * @function
 * @since 1.0.0
 */
exports.getOrd = function (OL, OA) {
    return Ord_1.getSemigroup().concat(Ord_1.contramap(fst, OL), Ord_1.contramap(snd, OA));
};
/**
 * @function
 * @since 1.0.0
 */
exports.getSemigroup = function (SL, SA) {
    return {
        concat: function (x, y) { return new Tuple(SL.concat(x.fst, y.fst), SA.concat(x.snd, y.snd)); }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getMonoid = function (ML, MA) {
    return __assign({}, exports.getSemigroup(ML, MA), { empty: new Tuple(ML.empty, MA.empty) });
};
var ap = function (S) { return function (fab, fa) {
    return new Tuple(S.concat(fab.fst, fa.fst), fab.snd(fa.snd));
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getApply = function (S) {
    return {
        URI: exports.URI,
        _L: function_1.phantom,
        map: map,
        ap: ap(S)
    };
};
var of = function (M) { return function (a) {
    return new Tuple(M.empty, a);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getApplicative = function (M) {
    return __assign({}, exports.getApply(M), { of: of(M) });
};
var chain = function (S) { return function (fa, f) {
    var _a = f(fa.snd), fst = _a.fst, snd = _a.snd;
    return new Tuple(S.concat(fa.fst, fst), snd);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getChain = function (S) {
    return __assign({}, exports.getApply(S), { chain: chain(S) });
};
/**
 * @function
 * @since 1.0.0
 */
exports.getMonad = function (M) {
    return __assign({}, exports.getChain(M), { of: of(M) });
};
var chainRec = function (M) { return function (a, f) {
    var result = f(a);
    var acc = M.empty;
    while (result.snd.isLeft()) {
        acc = M.concat(acc, result.fst);
        result = f(result.snd.value);
    }
    return new Tuple(M.concat(acc, result.fst), result.snd.value);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getChainRec = function (M) {
    return __assign({}, exports.getChain(M), { chainRec: chainRec(M) });
};
var traverse = function (F) { return function (ta, f) {
    return F.map(f(ta.snd), function (b) { return new Tuple(ta.fst, b); });
}; };
var sequence = function (F) { return function (ta) {
    return F.map(ta.snd, function (b) { return new Tuple(ta.fst, b); });
}; };
/**
 * @instance
 * @since 1.0.0
 */
exports.tuple = {
    URI: exports.URI,
    compose: compose,
    map: map,
    bimap: bimap,
    extract: extract,
    extend: extend,
    reduce: reduce,
    foldMap: foldMap,
    foldr: foldr,
    traverse: traverse,
    sequence: sequence
};
