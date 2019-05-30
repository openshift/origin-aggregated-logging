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
var Monoid_1 = require("./Monoid");
exports.URI = 'Option';
var None = /** @class */ (function () {
    function None() {
        this._tag = 'None';
    }
    /**
     * Takes a function `f` and an `Option` of `A`. Maps `f` either on `None` or `Some`, Option's data constructors. If it
     * maps on `Some` then it will apply the `f` on `Some`'s value, if it maps on `None` it will return `None`.
     *
     * @example
     * import { some } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(some(1).map(n => n * 2), some(2))
     */
    None.prototype.map = function (f) {
        return exports.none;
    };
    /**
     * Maps `f` over this `Option`'s value. If the value returned from `f` is null or undefined, returns `None`
     *
     * @example
     * import { none, some } from 'fp-ts/lib/Option'
     *
     * interface Foo {
     *   bar?: {
     *     baz?: string
     *   }
     * }
     *
     * assert.deepEqual(
     *   some<Foo>({ bar: { baz: 'quux' } })
     *     .mapNullable(foo => foo.bar)
     *     .mapNullable(bar => bar.baz),
     *   some('quux')
     * )
     * assert.deepEqual(
     *   some<Foo>({ bar: {} })
     *     .mapNullable(foo => foo.bar)
     *     .mapNullable(bar => bar.baz),
     *   none
     * )
     * assert.deepEqual(
     *   some<Foo>({})
     *     .mapNullable(foo => foo.bar)
     *     .mapNullable(bar => bar.baz),
     *   none
     * )
     */
    None.prototype.mapNullable = function (f) {
        return exports.none;
    };
    /**
     * `ap`, some may also call it "apply". Takes a function `fab` that is in the context of `Option`, and applies that
     * function to this `Option`'s value. If the `Option` calling `ap` is `none` it will return `none`.
     *
     * @example
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(some(2).ap(some((x: number) => x + 1)), some(3))
     * assert.deepEqual(none.ap(some((x: number) => x + 1)), none)
     */
    None.prototype.ap = function (fab) {
        return exports.none;
    };
    /**
     * Flipped version of {@link ap}
     *
     * @example
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(some((x: number) => x + 1).ap_(some(2)), some(3))
     * assert.deepEqual(none.ap_(some(2)), none)
     */
    None.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Returns the result of applying f to this `Option`'s value if this `Option` is nonempty. Returns `None` if this
     * `Option` is empty. Slightly different from `map` in that `f` is expected to return an `Option` (which could be
     * `None`)
     */
    None.prototype.chain = function (f) {
        return exports.none;
    };
    None.prototype.reduce = function (b, f) {
        return b;
    };
    /**
     * `alt` short for alternative, takes another `Option`. If this `Option` is a `Some` type then it will be returned, if
     * it is a `None` then it will return the next `Some` if it exist. If both are `None` then it will return `none`.
     *
     * @example
     * import { Option, some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(some(2).alt(some(4)), some(2))
     * const fa: Option<number> = none
     * assert.deepEqual(fa.alt(some(4)), some(4))
     */
    None.prototype.alt = function (fa) {
        return fa;
    };
    /**
     * Lazy version of {@link alt}
     *
     * @example
     * import { some } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(some(1).orElse(() => some(2)), some(1))
     *
     * @since 1.6.0
     */
    None.prototype.orElse = function (fa) {
        return fa();
    };
    None.prototype.extend = function (f) {
        return exports.none;
    };
    /**
     * Applies a function to each case in the data structure
     *
     * @example
     * import { none, some } from 'fp-ts/lib/Option'
     *
     * assert.strictEqual(some(1).fold('none', a => `some: ${a}`), 'some: 1')
     * assert.strictEqual(none.fold('none', a => `some: ${a}`), 'none')
     */
    None.prototype.fold = function (b, whenSome) {
        return b;
    };
    /** Lazy version of {@link fold} */
    None.prototype.foldL = function (whenNone, whenSome) {
        return whenNone();
    };
    /**
     * Returns the value from this `Some` or the given argument if this is a `None`
     *
     * @example
     * import { Option, none, some } from 'fp-ts/lib/Option'
     *
     * assert.strictEqual(some(1).getOrElse(0), 1)
     * const fa: Option<number> = none
     * assert.strictEqual(fa.getOrElse(0), 0)
     */
    None.prototype.getOrElse = function (a) {
        return a;
    };
    /** Lazy version of {@link getOrElse} */
    None.prototype.getOrElseL = function (f) {
        return f();
    };
    /** Returns the value from this `Some` or `null` if this is a `None` */
    None.prototype.toNullable = function () {
        return null;
    };
    /** Returns the value from this `Some` or `undefined` if this is a `None` */
    None.prototype.toUndefined = function () {
        return undefined;
    };
    None.prototype.inspect = function () {
        return this.toString();
    };
    None.prototype.toString = function () {
        return 'none';
    };
    /** Returns `true` if the option has an element that is equal (as determined by `S`) to `a`, `false` otherwise */
    None.prototype.contains = function (S, a) {
        return false;
    };
    /** Returns `true` if the option is `None`, `false` otherwise */
    None.prototype.isNone = function () {
        return true;
    };
    /** Returns `true` if the option is an instance of `Some`, `false` otherwise */
    None.prototype.isSome = function () {
        return false;
    };
    /**
     * Returns `true` if this option is non empty and the predicate `p` returns `true` when applied to this Option's value
     */
    None.prototype.exists = function (p) {
        return false;
    };
    None.prototype.filter = function (p) {
        return exports.none;
    };
    /**
     * Use {@link filter} instead.
     * Returns this option refined as `Option<B>` if it is non empty and the `refinement` returns `true` when applied to
     * this Option's value. Otherwise returns `None`
     * @since 1.3.0
     * @deprecated
     */
    None.prototype.refine = function (refinement) {
        return exports.none;
    };
    None.value = new None();
    return None;
}());
exports.None = None;
/**
 * @constant
 * @since 1.0.0
 */
exports.none = None.value;
var Some = /** @class */ (function () {
    function Some(value) {
        this.value = value;
        this._tag = 'Some';
    }
    Some.prototype.map = function (f) {
        return new Some(f(this.value));
    };
    Some.prototype.mapNullable = function (f) {
        return exports.fromNullable(f(this.value));
    };
    Some.prototype.ap = function (fab) {
        return fab.isNone() ? exports.none : new Some(fab.value(this.value));
    };
    Some.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    Some.prototype.chain = function (f) {
        return f(this.value);
    };
    Some.prototype.reduce = function (b, f) {
        return f(b, this.value);
    };
    Some.prototype.alt = function (fa) {
        return this;
    };
    Some.prototype.orElse = function (fa) {
        return this;
    };
    Some.prototype.extend = function (f) {
        return new Some(f(this));
    };
    Some.prototype.fold = function (b, whenSome) {
        return whenSome(this.value);
    };
    Some.prototype.foldL = function (whenNone, whenSome) {
        return whenSome(this.value);
    };
    Some.prototype.getOrElse = function (a) {
        return this.value;
    };
    Some.prototype.getOrElseL = function (f) {
        return this.value;
    };
    Some.prototype.toNullable = function () {
        return this.value;
    };
    Some.prototype.toUndefined = function () {
        return this.value;
    };
    Some.prototype.inspect = function () {
        return this.toString();
    };
    Some.prototype.toString = function () {
        return "some(" + function_1.toString(this.value) + ")";
    };
    Some.prototype.contains = function (S, a) {
        return S.equals(this.value, a);
    };
    Some.prototype.isNone = function () {
        return false;
    };
    Some.prototype.isSome = function () {
        return true;
    };
    Some.prototype.exists = function (p) {
        return p(this.value);
    };
    Some.prototype.filter = function (p) {
        return this.exists(p) ? this : exports.none;
    };
    Some.prototype.refine = function (refinement) {
        return this.filter(refinement);
    };
    return Some;
}());
exports.Some = Some;
/**
 *
 * @example
 * import { none, some, getSetoid } from 'fp-ts/lib/Option'
 * import { setoidNumber } from 'fp-ts/lib/Setoid'
 *
 * const S = getSetoid(setoidNumber)
 * assert.strictEqual(S.equals(none, none), true)
 * assert.strictEqual(S.equals(none, some(1)), false)
 * assert.strictEqual(S.equals(some(1), none), false)
 * assert.strictEqual(S.equals(some(1), some(2)), false)
 * assert.strictEqual(S.equals(some(1), some(1)), true)
 *
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (S) {
    return {
        equals: function (x, y) { return (x.isNone() ? y.isNone() : y.isNone() ? false : S.equals(x.value, y.value)); }
    };
};
/**
 * The `Ord` instance allows `Option` values to be compared with
 * `compare`, whenever there is an `Ord` instance for
 * the type the `Option` contains.
 *
 * `None` is considered to be less than any `Some` value.
 *
 *
 * @example
 * import { none, some, getOrd } from 'fp-ts/lib/Option'
 * import { ordNumber } from 'fp-ts/lib/Ord'
 *
 * const O = getOrd(ordNumber)
 * assert.strictEqual(O.compare(none, none), 0)
 * assert.strictEqual(O.compare(none, some(1)), -1)
 * assert.strictEqual(O.compare(some(1), none), 1)
 * assert.strictEqual(O.compare(some(1), some(2)), -1)
 * assert.strictEqual(O.compare(some(1), some(1)), 0)
 *
 * @function
 * @since 1.2.0
 */
exports.getOrd = function (O) {
    return __assign({}, exports.getSetoid(O), { compare: function (x, y) { return (x.isSome() ? (y.isSome() ? O.compare(x.value, y.value) : 1) : y.isSome() ? -1 : 0); } });
};
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new Some(a);
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
    return fa.isNone() ? M.empty : f(fa.value);
}; };
var foldr = function (fa, b, f) {
    return fa.isNone() ? b : f(fa.value, b);
};
var traverse = function (F) { return function (ta, f) {
    return ta.isNone() ? F.of(exports.none) : F.map(f(ta.value), exports.some);
}; };
var sequence = function (F) { return function (ta) {
    return ta.isNone() ? F.of(exports.none) : F.map(ta.value, exports.some);
}; };
var alt = function (fx, fy) {
    return fx.alt(fy);
};
var extend = function (ea, f) {
    return ea.extend(f);
};
var zero = function () {
    return exports.none;
};
/**
 * {@link Apply} semigroup
 *
 * | x       | y       | concat(x, y)       |
 * | ------- | ------- | ------------------ |
 * | none    | none    | none               |
 * | some(a) | none    | none               |
 * | none    | some(a) | none               |
 * | some(a) | some(b) | some(concat(a, b)) |
 *
 * @example
 * import { getApplySemigroup, some, none } from 'fp-ts/lib/Option'
 * import { semigroupSum } from 'fp-ts/lib/Semigroup'
 *
 * const S = getApplySemigroup(semigroupSum)
 * assert.deepEqual(S.concat(none, none), none)
 * assert.deepEqual(S.concat(some(1), none), none)
 * assert.deepEqual(S.concat(none, some(1)), none)
 * assert.deepEqual(S.concat(some(1), some(2)), some(3))
 *
 * @function
 * @since 1.7.0
 */
exports.getApplySemigroup = function (S) {
    return {
        concat: function (x, y) { return (x.isSome() && y.isSome() ? exports.some(S.concat(x.value, y.value)) : exports.none); }
    };
};
/**
 * @function
 * @since 1.7.0
 */
exports.getApplyMonoid = function (M) {
    return __assign({}, exports.getApplySemigroup(M), { empty: exports.some(M.empty) });
};
/**
 * Monoid returning the left-most non-`None` value
 *
 * | x       | y       | concat(x, y) |
 * | ------- | ------- | ------------ |
 * | none    | none    | none         |
 * | some(a) | none    | some(a)      |
 * | none    | some(a) | some(a)      |
 * | some(a) | some(b) | some(a)      |
 *
 * @example
 * import { getFirstMonoid, some, none } from 'fp-ts/lib/Option'
 *
 * const M = getFirstMonoid<number>()
 * assert.deepEqual(M.concat(none, none), none)
 * assert.deepEqual(M.concat(some(1), none), some(1))
 * assert.deepEqual(M.concat(none, some(1)), some(1))
 * assert.deepEqual(M.concat(some(1), some(2)), some(1))
 *
 * @function
 * @since 1.0.0
 */
exports.getFirstMonoid = function () {
    return {
        concat: alt,
        empty: exports.none
    };
};
/**
 * Monoid returning the right-most non-`None` value
 *
 * | x       | y       | concat(x, y) |
 * | ------- | ------- | ------------ |
 * | none    | none    | none         |
 * | some(a) | none    | some(a)      |
 * | none    | some(a) | some(a)      |
 * | some(a) | some(b) | some(b)      |
 *
 * @example
 * import { getLastMonoid, some, none } from 'fp-ts/lib/Option'
 *
 * const M = getLastMonoid<number>()
 * assert.deepEqual(M.concat(none, none), none)
 * assert.deepEqual(M.concat(some(1), none), some(1))
 * assert.deepEqual(M.concat(none, some(1)), some(1))
 * assert.deepEqual(M.concat(some(1), some(2)), some(2))
 *
 * @function
 * @since 1.0.0
 */
exports.getLastMonoid = function () {
    return Monoid_1.getDualMonoid(exports.getFirstMonoid());
};
/**
 * Monoid returning the left-most non-`None` value. If both operands are `Some`s then the inner values are
 * appended using the provided `Semigroup`
 *
 * | x       | y       | concat(x, y)       |
 * | ------- | ------- | ------------------ |
 * | none    | none    | none               |
 * | some(a) | none    | some(a)            |
 * | none    | some(a) | some(a)            |
 * | some(a) | some(b) | some(concat(a, b)) |
 *
 * @example
 * import { getMonoid, some, none } from 'fp-ts/lib/Option'
 * import { semigroupSum } from 'fp-ts/lib/Semigroup'
 *
 * const M = getMonoid(semigroupSum)
 * assert.deepEqual(M.concat(none, none), none)
 * assert.deepEqual(M.concat(some(1), none), some(1))
 * assert.deepEqual(M.concat(none, some(1)), some(1))
 * assert.deepEqual(M.concat(some(1), some(2)), some(3))
 *
 * @function
 * @since 1.0.0
 */
exports.getMonoid = function (S) {
    return {
        concat: function (x, y) { return (x.isNone() ? y : y.isNone() ? x : exports.some(S.concat(x.value, y.value))); },
        empty: exports.none
    };
};
/**
 * Constructs a new `Option` from a nullable type. If the value is `null` or `undefined`, returns `None`, otherwise
 * returns the value wrapped in a `Some`
 *
 * @example
 * import { none, some, fromNullable } from 'fp-ts/lib/Option'
 *
 * assert.deepEqual(fromNullable(undefined), none)
 * assert.deepEqual(fromNullable(null), none)
 * assert.deepEqual(fromNullable(1), some(1))
 *
 * @function
 * @since 1.0.0
 */
exports.fromNullable = function (a) {
    return a == null ? exports.none : new Some(a);
};
/**
 * @function
 * @since 1.0.0
 * @alias of
 */
exports.some = of;
function fromPredicate(predicate) {
    return function (a) { return (predicate(a) ? exports.some(a) : exports.none); };
}
exports.fromPredicate = fromPredicate;
/**
 * Transforms an exception into an `Option`. If `f` throws, returns `None`, otherwise returns the output wrapped in
 * `Some`
 *
 * @example
 * import { none, some, tryCatch } from 'fp-ts/lib/Option'
 *
 * assert.deepEqual(
 *   tryCatch(() => {
 *     throw new Error()
 *   }),
 *   none
 * )
 * assert.deepEqual(tryCatch(() => 1), some(1))
 *
 * @function
 * @since 1.0.0
 */
exports.tryCatch = function (f) {
    try {
        return exports.some(f());
    }
    catch (e) {
        return exports.none;
    }
};
/**
 * Constructs a new `Option` from a `Either`. If the value is a `Left`, returns `None`, otherwise returns the inner
 * value wrapped in a `Some`
 *
 * @example
 * import { none, some, fromEither } from 'fp-ts/lib/Option'
 * import { left, right } from 'fp-ts/lib/Either'
 *
 * assert.deepEqual(fromEither(left(1)), none)
 * assert.deepEqual(fromEither(right(1)), some(1))
 *
 * @function
 * @since 1.0.0
 */
exports.fromEither = function (fa) {
    return fa.isLeft() ? exports.none : exports.some(fa.value);
};
/**
 * Returns `true` if the option is an instance of `Some`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isSome = function (fa) {
    return fa.isSome();
};
/**
 * Returns `true` if the option is `None`, `false` otherwise
 * @function
 * @since 1.0.0
 */
exports.isNone = function (fa) {
    return fa.isNone();
};
/**
 * Use {@link fromPredicate} instead.
 * Refinement version of {@link fromPredicate}
 * @function
 * @since 1.3.0
 * @deprecated
 */
exports.fromRefinement = function (refinement) { return function (a) {
    return refinement(a) ? exports.some(a) : exports.none;
}; };
/**
 * Returns a refinement from a prism.
 * This function ensures that a custom type guard definition is type-safe.
 *
 * ```ts
 * import { some, none, getRefinement } from 'fp-ts/lib/Option'
 *
 * type A = { type: 'A' }
 * type B = { type: 'B' }
 * type C = A | B
 *
 * const isA = (c: C): c is A => c.type === 'B' // <= typo but typescript doesn't complain
 * const isA = getRefinement<C, A>(c => (c.type === 'B' ? some(c) : none)) // static error: Type '"B"' is not assignable to type '"A"'
 * ```
 *
 * @function
 * @since 1.7.0
 */
exports.getRefinement = function (getOption) {
    return function (a) { return getOption(a).isSome(); };
};
var compact = function (fa) { return fa.chain(function_1.identity); };
var separate = function (fa) {
    if (fa.isNone()) {
        return {
            left: exports.none,
            right: exports.none
        };
    }
    var e = fa.value;
    if (e.isLeft()) {
        return {
            left: exports.some(e.value),
            right: exports.none
        };
    }
    return {
        left: exports.none,
        right: exports.some(e.value)
    };
};
var filter = function (fa, p) { return fa.filter(p); };
var filterMap = chain;
var partitionMap = function (fa, f) {
    return separate(fa.map(f));
};
var partition = function (fa, p) { return ({
    left: fa.filter(function_1.not(p)),
    right: fa.filter(p)
}); };
var wither = function (F) { return function (fa, f) {
    return fa.isNone() ? F.of(fa) : f(fa.value);
}; };
var wilt = function (F) { return function (fa, f) {
    if (fa.isNone()) {
        return F.of({
            left: exports.none,
            right: exports.none
        });
    }
    return F.map(f(fa.value), function (e) {
        if (e.isLeft()) {
            return {
                left: exports.some(e.value),
                right: exports.none
            };
        }
        return {
            left: exports.none,
            right: exports.some(e.value)
        };
    });
}; };
/**
 * @instance
 * @since 1.0.0
 */
exports.option = {
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
    zero: zero,
    alt: alt,
    extend: extend,
    compact: compact,
    separate: separate,
    filter: filter,
    filterMap: filterMap,
    partition: partition,
    partitionMap: partitionMap,
    wither: wither,
    wilt: wilt
};
