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
var ChainRec_1 = require("./ChainRec");
var function_1 = require("./function");
exports.URI = 'Either';
/**
 * Left side of {@link Either}
 */
var Left = /** @class */ (function () {
    function Left(value) {
        this.value = value;
        this._tag = 'Left';
    }
    /** The given function is applied if this is a `Right` */
    Left.prototype.map = function (f) {
        return this;
    };
    Left.prototype.ap = function (fab) {
        return (fab.isLeft() ? fab : this);
    };
    /**
     * Flipped version of {@link ap}
     */
    Left.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /** Binds the given function across `Right` */
    Left.prototype.chain = function (f) {
        return this;
    };
    Left.prototype.bimap = function (f, g) {
        return new Left(f(this.value));
    };
    Left.prototype.alt = function (fy) {
        return fy;
    };
    /**
     * Lazy version of {@link alt}
     *
     * @example
     * import { right } from 'fp-ts/lib/Either'
     *
     * assert.deepEqual(right(1).orElse(() => right(2)), right(1))
     *
     * @since 1.6.0
     */
    Left.prototype.orElse = function (fy) {
        return fy(this.value);
    };
    Left.prototype.extend = function (f) {
        return this;
    };
    Left.prototype.reduce = function (b, f) {
        return b;
    };
    /** Applies a function to each case in the data structure */
    Left.prototype.fold = function (whenLeft, whenRight) {
        return whenLeft(this.value);
    };
    /** Returns the value from this `Right` or the given argument if this is a `Left` */
    Left.prototype.getOrElse = function (a) {
        return a;
    };
    /** Returns the value from this `Right` or the result of given argument if this is a `Left` */
    Left.prototype.getOrElseL = function (f) {
        return f(this.value);
    };
    /** Maps the left side of the disjunction */
    Left.prototype.mapLeft = function (f) {
        return new Left(f(this.value));
    };
    Left.prototype.inspect = function () {
        return this.toString();
    };
    Left.prototype.toString = function () {
        return "left(" + function_1.toString(this.value) + ")";
    };
    /** Returns `true` if the either is an instance of `Left`, `false` otherwise */
    Left.prototype.isLeft = function () {
        return true;
    };
    /** Returns `true` if the either is an instance of `Right`, `false` otherwise */
    Left.prototype.isRight = function () {
        return false;
    };
    /** Swaps the disjunction values */
    Left.prototype.swap = function () {
        return new Right(this.value);
    };
    Left.prototype.filterOrElse = function (_, zero) {
        return this;
    };
    Left.prototype.filterOrElseL = function (_, zero) {
        return this;
    };
    /**
     * Use {@link filterOrElse} instead
     * @since 1.6.0
     * @deprecated
     */
    Left.prototype.refineOrElse = function (p, zero) {
        return this;
    };
    /**
     * Lazy version of {@link refineOrElse}
     * Use {@link filterOrElseL} instead
     * @since 1.6.0
     * @deprecated
     */
    Left.prototype.refineOrElseL = function (p, zero) {
        return this;
    };
    return Left;
}());
exports.Left = Left;
/**
 * Right side of {@link Either}
 */
var Right = /** @class */ (function () {
    function Right(value) {
        this.value = value;
        this._tag = 'Right';
    }
    Right.prototype.map = function (f) {
        return new Right(f(this.value));
    };
    Right.prototype.ap = function (fab) {
        return fab.isRight() ? this.map(fab.value) : exports.left(fab.value);
    };
    Right.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    Right.prototype.chain = function (f) {
        return f(this.value);
    };
    Right.prototype.bimap = function (f, g) {
        return new Right(g(this.value));
    };
    Right.prototype.alt = function (fy) {
        return this;
    };
    Right.prototype.orElse = function (fy) {
        return this;
    };
    Right.prototype.extend = function (f) {
        return new Right(f(this));
    };
    Right.prototype.reduce = function (b, f) {
        return f(b, this.value);
    };
    Right.prototype.fold = function (whenLeft, whenRight) {
        return whenRight(this.value);
    };
    Right.prototype.getOrElse = function (a) {
        return this.value;
    };
    Right.prototype.getOrElseL = function (f) {
        return this.value;
    };
    Right.prototype.mapLeft = function (f) {
        return new Right(this.value);
    };
    Right.prototype.inspect = function () {
        return this.toString();
    };
    Right.prototype.toString = function () {
        return "right(" + function_1.toString(this.value) + ")";
    };
    Right.prototype.isLeft = function () {
        return false;
    };
    Right.prototype.isRight = function () {
        return true;
    };
    Right.prototype.swap = function () {
        return new Left(this.value);
    };
    Right.prototype.filterOrElse = function (p, zero) {
        return p(this.value) ? this : exports.left(zero);
    };
    Right.prototype.filterOrElseL = function (p, zero) {
        return p(this.value) ? this : exports.left(zero(this.value));
    };
    Right.prototype.refineOrElse = function (p, zero) {
        return p(this.value) ? this : exports.left(zero);
    };
    Right.prototype.refineOrElseL = function (p, zero) {
        return p(this.value) ? this : exports.left(zero(this.value));
    };
    return Right;
}());
exports.Right = Right;
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (SL, SA) {
    return {
        equals: function (x, y) {
            return x.isLeft() ? y.isLeft() && SL.equals(x.value, y.value) : y.isRight() && SA.equals(x.value, y.value);
        }
    };
};
/**
 * Semigroup returning the left-most non-`Left` value. If both operands are `Right`s then the inner values are
 * appended using the provided `Semigroup`
 *
 * @example
 * import { getSemigroup, left, right } from 'fp-ts/lib/Either'
 * import { semigroupSum } from 'fp-ts/lib/Semigroup'
 *
 * const S = getSemigroup<string, number>(semigroupSum)
 * assert.deepEqual(S.concat(left('a'), left('b')), left('a'))
 * assert.deepEqual(S.concat(left('a'), right(2)), right(2))
 * assert.deepEqual(S.concat(right(1), left('b')), right(1))
 * assert.deepEqual(S.concat(right(1), right(2)), right(3))
 *
 * @function
 * @since 1.7.0
 */
exports.getSemigroup = function (S) {
    return {
        concat: function (x, y) { return (y.isLeft() ? x : x.isLeft() ? y : exports.right(S.concat(x.value, y.value))); }
    };
};
/**
 * {@link Apply} semigroup
 *
 * @example
 * import { getApplySemigroup, left, right } from 'fp-ts/lib/Either'
 * import { semigroupSum } from 'fp-ts/lib/Semigroup'
 *
 * const S = getApplySemigroup<string, number>(semigroupSum)
 * assert.deepEqual(S.concat(left('a'), left('b')), left('a'))
 * assert.deepEqual(S.concat(left('a'), right(2)), left('a'))
 * assert.deepEqual(S.concat(right(1), left('b')), left('b'))
 * assert.deepEqual(S.concat(right(1), right(2)), right(3))
 *
 * @function
 * @since 1.7.0
 */
exports.getApplySemigroup = function (S) {
    return {
        concat: function (x, y) { return (x.isLeft() ? x : y.isLeft() ? y : exports.right(S.concat(x.value, y.value))); }
    };
};
/**
 * @function
 * @since 1.7.0
 */
exports.getApplyMonoid = function (M) {
    return __assign({}, exports.getApplySemigroup(M), { empty: exports.right(M.empty) });
};
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new Right(a);
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
var bimap = function (fla, f, g) {
    return fla.bimap(f, g);
};
var alt = function (fx, fy) {
    return fx.alt(fy);
};
var extend = function (ea, f) {
    return ea.extend(f);
};
var reduce = function (fa, b, f) {
    return fa.reduce(b, f);
};
var foldMap = function (M) { return function (fa, f) {
    return fa.isLeft() ? M.empty : f(fa.value);
}; };
var foldr = function (fa, b, f) {
    return fa.isLeft() ? b : f(fa.value, b);
};
var traverse = function (F) { return function (ta, f) {
    return ta.isLeft() ? F.of(exports.left(ta.value)) : F.map(f(ta.value), of);
}; };
var sequence = function (F) { return function (ta) {
    return ta.isLeft() ? F.of(exports.left(ta.value)) : F.map(ta.value, exports.right);
}; };
var chainRec = function (a, f) {
    return ChainRec_1.tailRec(function (e) {
        if (e.isLeft()) {
            return exports.right(exports.left(e.value));
        }
        else {
            var r = e.value;
            return r.isLeft() ? exports.left(f(r.value)) : exports.right(exports.right(r.value));
        }
    }, f(a));
};
/**
 * Constructs a new `Either` holding a `Left` value. This usually represents a failure, due to the right-bias of this
 * structure
 * @function
 * @since 1.0.0
 */
exports.left = function (l) {
    return new Left(l);
};
/**
 * Constructs a new `Either` holding a `Right` value. This usually represents a successful value due to the right bias
 * of this structure
 * @function
 * @since 1.0.0
 * @alias of
 */
exports.right = of;
function fromPredicate(predicate, whenFalse) {
    return function (a) { return (predicate(a) ? exports.right(a) : exports.left(whenFalse(a))); };
}
exports.fromPredicate = fromPredicate;
/**
 * Use {@link fromPredicate} instead
 * @function
 * @since 1.6.0
 * @deprecated
 */
exports.fromRefinement = function (refinement, whenFalse) { return function (a) {
    return refinement(a) ? exports.right(a) : exports.left(whenFalse(a));
}; };
/**
 * Takes a default and a `Option` value, if the value is a `Some`, turn it into a `Right`, if the value is a `None` use
 * the provided default as a `Left`
 * @function
 * @since 1.0.0
 */
exports.fromOption = function (defaultValue) { return function (fa) {
    return fa.isNone() ? exports.left(defaultValue) : exports.right(fa.value);
}; };
/**
 * Lazy version of {@link fromOption}
 * @function
 * @since 1.3.0
 */
exports.fromOptionL = function (defaultValue) { return function (fa) {
    return fa.isNone() ? exports.left(defaultValue()) : exports.right(fa.value);
}; };
/**
 * Takes a default and a nullable value, if the value is not nully, turn it into a `Right`, if the value is nully use
 * the provided default as a `Left`
 * @function
 * @since 1.0.0
 */
exports.fromNullable = function (defaultValue) { return function (a) {
    return a == null ? exports.left(defaultValue) : exports.right(a);
}; };
/**
 * Default value for the optional `onerror` argument of `tryCatch`
 * @function
 * @since 1.0.0
 */
exports.toError = function (e) {
    if (e instanceof Error) {
        return e;
    }
    else {
        return new Error(String(e));
    }
};
/**
 * Use {@link tryCatch2v}
 * @function
 * @since 1.0.0
 * @deprecated
 */
exports.tryCatch = function (f, onerror) {
    if (onerror === void 0) { onerror = exports.toError; }
    return exports.tryCatch2v(f, onerror);
};
/**
 * @function
 * @since 1.11.0
 */
exports.tryCatch2v = function (f, onerror) {
    try {
        return exports.right(f());
    }
    catch (e) {
        return exports.left(onerror(e));
    }
};
/**
 * @function
 * @since 1.0.0
 */
exports.fromValidation = function (fa) {
    return fa.isFailure() ? exports.left(fa.value) : exports.right(fa.value);
};
/**
 * Returns `true` if the either is an instance of `Left`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isLeft = function (fa) {
    return fa.isLeft();
};
/**
 * Returns `true` if the either is an instance of `Right`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isRight = function (fa) {
    return fa.isRight();
};
/**
 * Builds {@link Compactable} instance for {@link Either} given {@link Monoid} for the left side
 * @function
 * @since 1.7.0
 */
function getCompactable(ML) {
    var compact = function (fa) {
        if (fa.isLeft()) {
            return fa;
        }
        if (fa.value.isNone()) {
            return exports.left(ML.empty);
        }
        return exports.right(fa.value.value);
    };
    var separate = function (fa) {
        if (fa.isLeft()) {
            return {
                left: fa,
                right: fa
            };
        }
        if (fa.value.isLeft()) {
            return {
                left: exports.right(fa.value.value),
                right: exports.left(ML.empty)
            };
        }
        return {
            left: exports.left(ML.empty),
            right: exports.right(fa.value.value)
        };
    };
    return {
        URI: exports.URI,
        _L: function_1.phantom,
        compact: compact,
        separate: separate
    };
}
exports.getCompactable = getCompactable;
/**
 * Builds {@link Filterable} instance for {@link Either} given {@link Monoid} for the left side
 * @function
 * @since 1.7.0
 */
function getFilterable(ML) {
    var C = getCompactable(ML);
    var partitionMap = function (fa, f) {
        if (fa.isLeft()) {
            return {
                left: fa,
                right: fa
            };
        }
        var e = f(fa.value);
        if (e.isLeft()) {
            return {
                left: exports.right(e.value),
                right: exports.left(ML.empty)
            };
        }
        return {
            left: exports.left(ML.empty),
            right: exports.right(e.value)
        };
    };
    var partition = function (fa, p) {
        if (fa.isLeft()) {
            return {
                left: fa,
                right: fa
            };
        }
        if (p(fa.value)) {
            return {
                left: exports.left(ML.empty),
                right: exports.right(fa.value)
            };
        }
        return {
            left: exports.right(fa.value),
            right: exports.left(ML.empty)
        };
    };
    var filterMap = function (fa, f) {
        if (fa.isLeft()) {
            return fa;
        }
        var optionB = f(fa.value);
        if (optionB.isSome()) {
            return exports.right(optionB.value);
        }
        return exports.left(ML.empty);
    };
    var filter = function (fa, p) { return fa.filterOrElse(p, ML.empty); };
    return __assign({}, C, { map: map,
        partitionMap: partitionMap,
        filterMap: filterMap,
        partition: partition,
        filter: filter });
}
exports.getFilterable = getFilterable;
/**
 * Builds {@link Witherable} instance for {@link Either} given {@link Monoid} for the left side
 * @function
 * @since 1.7.0
 */
function getWitherable(ML) {
    var filterableEither = getFilterable(ML);
    var wither = function (F) {
        var traverseF = traverse(F);
        return function (wa, f) { return F.map(traverseF(wa, f), filterableEither.compact); };
    };
    var wilt = function (F) {
        var traverseF = traverse(F);
        return function (wa, f) { return F.map(traverseF(wa, f), filterableEither.separate); };
    };
    return __assign({}, filterableEither, { traverse: traverse,
        reduce: reduce,
        wither: wither,
        wilt: wilt });
}
exports.getWitherable = getWitherable;
/**
 * @instance
 * @since 1.0.0
 */
exports.either = {
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
    bimap: bimap,
    alt: alt,
    extend: extend,
    chainRec: chainRec
};
