"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
var Option_1 = require("./Option");
exports.URI = 'These';
var This = /** @class */ (function () {
    function This(value) {
        this.value = value;
        this._tag = 'This';
    }
    This.prototype.map = function (f) {
        return this;
    };
    This.prototype.bimap = function (f, g) {
        return new This(f(this.value));
    };
    This.prototype.reduce = function (b, f) {
        return b;
    };
    /** Applies a function to each case in the data structure */
    This.prototype.fold = function (this_, that, both) {
        return this_(this.value);
    };
    This.prototype.inspect = function () {
        return this.toString();
    };
    This.prototype.toString = function () {
        return "this_(" + function_1.toString(this.value) + ")";
    };
    /** Returns `true` if the these is `This`, `false` otherwise */
    This.prototype.isThis = function () {
        return true;
    };
    /** Returns `true` if the these is `That`, `false` otherwise */
    This.prototype.isThat = function () {
        return false;
    };
    /** Returns `true` if the these is `Both`, `false` otherwise */
    This.prototype.isBoth = function () {
        return false;
    };
    return This;
}());
exports.This = This;
var That = /** @class */ (function () {
    function That(value) {
        this.value = value;
        this._tag = 'That';
    }
    That.prototype.map = function (f) {
        return new That(f(this.value));
    };
    That.prototype.bimap = function (f, g) {
        return new That(g(this.value));
    };
    That.prototype.reduce = function (b, f) {
        return f(b, this.value);
    };
    That.prototype.fold = function (this_, that, both) {
        return that(this.value);
    };
    That.prototype.inspect = function () {
        return this.toString();
    };
    That.prototype.toString = function () {
        return "that(" + function_1.toString(this.value) + ")";
    };
    That.prototype.isThis = function () {
        return false;
    };
    That.prototype.isThat = function () {
        return true;
    };
    That.prototype.isBoth = function () {
        return false;
    };
    return That;
}());
exports.That = That;
var Both = /** @class */ (function () {
    function Both(l, a) {
        this.l = l;
        this.a = a;
        this._tag = 'Both';
    }
    Both.prototype.map = function (f) {
        return new Both(this.l, f(this.a));
    };
    Both.prototype.bimap = function (f, g) {
        return new Both(f(this.l), g(this.a));
    };
    Both.prototype.reduce = function (b, f) {
        return f(b, this.a);
    };
    Both.prototype.fold = function (this_, that, both) {
        return both(this.l, this.a);
    };
    Both.prototype.inspect = function () {
        return this.toString();
    };
    Both.prototype.toString = function () {
        return "both(" + function_1.toString(this.l) + ", " + function_1.toString(this.a) + ")";
    };
    Both.prototype.isThis = function () {
        return false;
    };
    Both.prototype.isThat = function () {
        return false;
    };
    Both.prototype.isBoth = function () {
        return true;
    };
    return Both;
}());
exports.Both = Both;
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (SL, SA) {
    return {
        equals: function (x, y) {
            return x.isThis()
                ? y.isThis() && SL.equals(x.value, y.value)
                : x.isThat()
                    ? y.isThat() && SA.equals(x.value, y.value)
                    : y.isBoth() && SL.equals(x.l, y.l) && SA.equals(x.a, y.a);
        }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getSemigroup = function (SL, SA) {
    return {
        concat: function (x, y) {
            return x.isThis()
                ? y.isThis()
                    ? exports.this_(SL.concat(x.value, y.value))
                    : y.isThat()
                        ? exports.both(x.value, y.value)
                        : exports.both(SL.concat(x.value, y.l), y.a)
                : x.isThat()
                    ? y.isThis()
                        ? exports.both(y.value, x.value)
                        : y.isThat()
                            ? exports.that(SA.concat(x.value, y.value))
                            : exports.both(y.l, SA.concat(x.value, y.a))
                    : y.isThis()
                        ? exports.both(SL.concat(x.l, y.value), x.a)
                        : y.isThat()
                            ? exports.both(x.l, SA.concat(x.a, y.value))
                            : exports.both(SL.concat(x.l, y.l), SA.concat(x.a, y.a));
        }
    };
};
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new That(a);
};
var ap = function (S) { return function (fab, fa) {
    return chain(S)(fab, function (f) { return map(fa, f); });
}; };
var chain = function (S) { return function (fa, f) {
    if (fa.isThis()) {
        return exports.this_(fa.value);
    }
    else if (fa.isThat()) {
        return f(fa.value);
    }
    else {
        var fb = f(fa.a);
        return fb.isThis()
            ? exports.this_(S.concat(fa.l, fb.value))
            : fb.isThat()
                ? exports.both(fa.l, fb.value)
                : exports.both(S.concat(fa.l, fb.l), fb.a);
    }
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getMonad = function (S) {
    return {
        URI: exports.URI,
        _L: function_1.phantom,
        map: map,
        of: of,
        ap: ap(S),
        chain: chain(S)
    };
};
var bimap = function (fla, f, g) {
    return fla.bimap(f, g);
};
var reduce = function (fa, b, f) {
    return fa.reduce(b, f);
};
var foldMap = function (M) { return function (fa, f) {
    return fa.isThis() ? M.empty : fa.isThat() ? f(fa.value) : f(fa.a);
}; };
var foldr = function (fa, b, f) {
    return fa.isThis() ? b : fa.isThat() ? f(fa.value, b) : f(fa.a, b);
};
var traverse = function (F) { return function (ta, f) {
    return ta.isThis()
        ? F.of(exports.this_(ta.value))
        : ta.isThat()
            ? F.map(f(ta.value), exports.that)
            : F.map(f(ta.a), function (b) { return exports.both(ta.l, b); });
}; };
var sequence = function (F) { return function (ta) {
    return ta.isThis()
        ? F.of(exports.this_(ta.value))
        : ta.isThat()
            ? F.map(ta.value, exports.that)
            : F.map(ta.a, function (b) { return exports.both(ta.l, b); });
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.this_ = function (l) {
    return new This(l);
};
/**
 * @function
 * @since 1.0.0
 * @alias of
 */
exports.that = of;
/**
 * @function
 * @since 1.0.0
 */
exports.both = function (l, a) {
    return new Both(l, a);
};
/**
 * @function
 * @since 1.0.0
 */
exports.fromThese = function (defaultThis, defaultThat) { return function (fa) {
    return fa.isThis() ? [fa.value, defaultThat] : fa.isThat() ? [defaultThis, fa.value] : [fa.l, fa.a];
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.theseLeft = function (fa) {
    return fa.isThis() ? Option_1.some(fa.value) : fa.isThat() ? Option_1.none : Option_1.some(fa.l);
};
/**
 * @function
 * @since 1.0.0
 */
exports.theseRight = function (fa) {
    return fa.isThis() ? Option_1.none : fa.isThat() ? Option_1.some(fa.value) : Option_1.some(fa.a);
};
/**
 * Returns `true` if the these is an instance of `This`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isThis = function (fa) {
    return fa.isThis();
};
/**
 * Returns `true` if the these is an instance of `That`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isThat = function (fa) {
    return fa.isThat();
};
/**
 * Returns `true` if the these is an instance of `Both`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isBoth = function (fa) {
    return fa.isBoth();
};
/**
 * @instance
 * @since 1.0.0
 */
exports.these = {
    URI: exports.URI,
    map: map,
    bimap: bimap,
    reduce: reduce,
    foldMap: foldMap,
    foldr: foldr,
    traverse: traverse,
    sequence: sequence
};
