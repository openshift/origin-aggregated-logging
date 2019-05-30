"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Array_1 = require("./Array");
var function_1 = require("./function");
var Option_1 = require("./Option");
var Semigroup_1 = require("./Semigroup");
exports.URI = 'NonEmptyArray';
/**
 * Data structure which represents non-empty arrays
 * @data
 * @constructor NonEmptyArray
 * @since 1.0.0
 */
var NonEmptyArray = /** @class */ (function () {
    function NonEmptyArray(head, tail) {
        this.head = head;
        this.tail = tail;
    }
    /**
     * Converts this {@link NonEmptyArray} to plain {@link Array}
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).toArray(), [1, 2, 3])
     */
    NonEmptyArray.prototype.toArray = function () {
        return function_1.concat([this.head], this.tail);
    };
    /**
     * Concatenates this {@link NonEmptyArray} and passed {@link Array}
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * assert.deepEqual(new NonEmptyArray<number>(1, []).concatArray([2]), new NonEmptyArray(1, [2]))
     */
    NonEmptyArray.prototype.concatArray = function (as) {
        return new NonEmptyArray(this.head, function_1.concat(this.tail, as));
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const double = (n: number): number => n * 2
     * assert.deepEqual(new NonEmptyArray(1, [2]).map(double), new NonEmptyArray(2, [4]))
     */
    NonEmptyArray.prototype.map = function (f) {
        return new NonEmptyArray(f(this.head), this.tail.map(f));
    };
    NonEmptyArray.prototype.mapWithIndex = function (f) {
        return new NonEmptyArray(f(0, this.head), Array_1.array.mapWithIndex(this.tail, function (i, a) { return f(i + 1, a); }));
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const x = new NonEmptyArray(1, [2])
     * const double = (n: number): number => n * 2
     * assert.deepEqual(x.ap(new NonEmptyArray(double, [double])).toArray(), [2, 4, 2, 4])
     */
    NonEmptyArray.prototype.ap = function (fab) {
        var _this = this;
        return fab.chain(function (f) { return _this.map(f); }); // <= derived
    };
    /**
     * Flipped version of {@link ap}
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const x = new NonEmptyArray(1, [2])
     * const double = (n: number) => n * 2
     * assert.deepEqual(new NonEmptyArray(double, [double]).ap_(x).toArray(), [2, 4, 2, 4])
     */
    NonEmptyArray.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const x = new NonEmptyArray(1, [2])
     * const f = (a: number) => new NonEmptyArray(a, [4])
     * assert.deepEqual(x.chain(f).toArray(), [1, 4, 2, 4])
     */
    NonEmptyArray.prototype.chain = function (f) {
        return f(this.head).concatArray(Array_1.array.chain(this.tail, function (a) { return f(a).toArray(); }));
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const x = new NonEmptyArray(1, [2])
     * const y = new NonEmptyArray(3, [4])
     * assert.deepEqual(x.concat(y).toArray(), [1, 2, 3, 4])
     */
    NonEmptyArray.prototype.concat = function (y) {
        return this.concatArray(y.toArray());
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * const x = new NonEmptyArray('a', ['b'])
     * assert.strictEqual(x.reduce('', (b, a) => b + a), 'ab')
     */
    NonEmptyArray.prototype.reduce = function (b, f) {
        return Array_1.array.reduce(this.toArray(), b, f);
    };
    /**
     * @since 1.12.0
     */
    NonEmptyArray.prototype.reduceWithIndex = function (b, f) {
        return Array_1.array.reduceWithIndex(this.toArray(), b, f);
    };
    /**
     * @since 1.12.0
     */
    NonEmptyArray.prototype.foldr = function (b, f) {
        return this.foldrWithIndex(b, function (_, a, b) { return f(a, b); });
    };
    /**
     * @since 1.12.0
     */
    NonEmptyArray.prototype.foldrWithIndex = function (b, f) {
        return f(0, this.head, this.tail.reduceRight(function (acc, a, i) { return f(i + 1, a, acc); }, b));
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { fold, monoidSum } from 'fp-ts/lib/Monoid'
     *
     * const sum = (as: NonEmptyArray<number>) => fold(monoidSum)(as.toArray())
     * assert.deepEqual(new NonEmptyArray(1, [2, 3, 4]).extend(sum), new NonEmptyArray(10, [9, 7, 4]))
     */
    NonEmptyArray.prototype.extend = function (f) {
        return unsafeFromArray(Array_1.array.extend(this.toArray(), function (as) { return f(unsafeFromArray(as)); }));
    };
    /**
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * assert.strictEqual(new NonEmptyArray(1, [2, 3]).extract(), 1)
     */
    NonEmptyArray.prototype.extract = function () {
        return this.head;
    };
    /**
     * Same as {@link toString}
     */
    NonEmptyArray.prototype.inspect = function () {
        return this.toString();
    };
    /**
     * Return stringified representation of this {@link NonEmptyArray}
     */
    NonEmptyArray.prototype.toString = function () {
        return "new NonEmptyArray(" + function_1.toString(this.head) + ", " + function_1.toString(this.tail) + ")";
    };
    /**
     * Gets minimum of this {@link NonEmptyArray} using specified {@link Ord} instance
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { ordNumber } from 'fp-ts/lib/Ord'
     *
     * assert.strictEqual(new NonEmptyArray(1, [2, 3]).min(ordNumber), 1)
     *
     * @since 1.3.0
     */
    NonEmptyArray.prototype.min = function (ord) {
        return Semigroup_1.fold(Semigroup_1.getMeetSemigroup(ord))(this.head)(this.tail);
    };
    /**
     * Gets maximum of this {@link NonEmptyArray} using specified {@link Ord} instance
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { ordNumber } from 'fp-ts/lib/Ord'
     *
     * assert.strictEqual(new NonEmptyArray(1, [2, 3]).max(ordNumber), 3)
     *
     * @since 1.3.0
     */
    NonEmptyArray.prototype.max = function (ord) {
        return Semigroup_1.fold(Semigroup_1.getJoinSemigroup(ord))(this.head)(this.tail);
    };
    /**
     * Gets last element of this {@link NonEmptyArray}
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * assert.strictEqual(new NonEmptyArray(1, [2, 3]).last(), 3)
     * assert.strictEqual(new NonEmptyArray(1, []).last(), 1)
     *
     * @since 1.6.0
     */
    NonEmptyArray.prototype.last = function () {
        return Array_1.last(this.tail).getOrElse(this.head);
    };
    /**
     * Sorts this {@link NonEmptyArray} using specified {@link Ord} instance
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { ordNumber } from 'fp-ts/lib/Ord'
     *
     * assert.deepEqual(new NonEmptyArray(3, [2, 1]).sort(ordNumber), new NonEmptyArray(1, [2, 3]))
     *
     * @since 1.6.0
     */
    NonEmptyArray.prototype.sort = function (ord) {
        return unsafeFromArray(Array_1.sort(ord)(this.toArray()));
    };
    /**
     * Reverts this {@link NonEmptyArray}
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).reverse(), new NonEmptyArray(3, [2, 1]))
     *
     * @since 1.6.0
     */
    NonEmptyArray.prototype.reverse = function () {
        return unsafeFromArray(this.toArray().reverse());
    };
    /**
     * @since 1.10.0
     */
    NonEmptyArray.prototype.length = function () {
        return 1 + this.tail.length;
    };
    /**
     * This function provides a safe way to read a value at a particular index from an NonEmptyArray
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).index(1), some(2))
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).index(3), none)
     *
     * @function
     * @since 1.11.0
     */
    NonEmptyArray.prototype.index = function (i) {
        return i === 0 ? Option_1.some(this.head) : Array_1.index(i - 1, this.tail);
    };
    NonEmptyArray.prototype.findFirst = function (predicate) {
        return predicate(this.head) ? Option_1.some(this.head) : Array_1.findFirst(this.tail, predicate);
    };
    NonEmptyArray.prototype.findLast = function (predicate) {
        var a = Array_1.findLast(this.tail, predicate);
        return a.isSome() ? a : predicate(this.head) ? Option_1.some(this.head) : Option_1.none;
    };
    /**
     * Find the first index for which a predicate holds
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).findIndex(x => x === 2), some(1))
     * assert.deepEqual(new NonEmptyArray<number>(1, []).findIndex(x => x === 2), none)
     *
     * @function
     * @since 1.11.0
     */
    NonEmptyArray.prototype.findIndex = function (predicate) {
        if (predicate(this.head)) {
            return Option_1.some(0);
        }
        else {
            var i = Array_1.findIndex(this.tail, predicate);
            return i.isSome() ? Option_1.some(i.value + 1) : Option_1.none;
        }
    };
    /**
     * Returns the index of the last element of the list which matches the predicate
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * interface X {
     *   a: number
     *   b: number
     * }
     * const xs: NonEmptyArray<X> = new NonEmptyArray({ a: 1, b: 0 }, [{ a: 1, b: 1 }])
     * assert.deepEqual(xs.findLastIndex(x => x.a === 1), some(1))
     * assert.deepEqual(xs.findLastIndex(x => x.a === 4), none)
     *
     * @function
     * @since 1.11.0
     */
    NonEmptyArray.prototype.findLastIndex = function (predicate) {
        var i = Array_1.findLastIndex(this.tail, predicate);
        return i.isSome() ? Option_1.some(i.value + 1) : predicate(this.head) ? Option_1.some(0) : Option_1.none;
    };
    /**
     * Insert an element at the specified index, creating a new NonEmptyArray, or returning `None` if the index is out of bounds
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { some } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3, 4]).insertAt(2, 5), some(new NonEmptyArray(1, [2, 5, 3, 4])))
     *
     * @function
     * @since 1.11.0
     */
    NonEmptyArray.prototype.insertAt = function (i, a) {
        if (i === 0) {
            return Option_1.some(new NonEmptyArray(a, this.toArray()));
        }
        else {
            var t = Array_1.insertAt(i - 1, a, this.tail);
            return t.isSome() ? Option_1.some(new NonEmptyArray(this.head, t.value)) : Option_1.none;
        }
    };
    /**
     * Change the element at the specified index, creating a new NonEmptyArray, or returning `None` if the index is out of bounds
     *
     * @example
     * import { NonEmptyArray } from 'fp-ts/lib/NonEmptyArray'
     * import { some, none } from 'fp-ts/lib/Option'
     *
     * assert.deepEqual(new NonEmptyArray(1, [2, 3]).updateAt(1, 1), some(new NonEmptyArray(1, [1, 3])))
     * assert.deepEqual(new NonEmptyArray(1, []).updateAt(1, 1), none)
     *
     * @function
     * @since 1.11.0
     */
    NonEmptyArray.prototype.updateAt = function (i, a) {
        if (i === 0) {
            return Option_1.some(new NonEmptyArray(a, this.tail));
        }
        else {
            var t = Array_1.updateAt(i - 1, a, this.tail);
            return t.isSome() ? Option_1.some(new NonEmptyArray(this.head, t.value)) : Option_1.none;
        }
    };
    NonEmptyArray.prototype.filter = function (predicate) {
        return this.filterWithIndex(function (_, a) { return predicate(a); });
    };
    /**
     * @function
     * @since 1.12.0
     */
    NonEmptyArray.prototype.filterWithIndex = function (predicate) {
        var t = Array_1.array.filterWithIndex(this.tail, function (i, a) { return predicate(i + 1, a); });
        return predicate(0, this.head) ? Option_1.some(new NonEmptyArray(this.head, t)) : exports.fromArray(t);
    };
    return NonEmptyArray;
}());
exports.NonEmptyArray = NonEmptyArray;
var unsafeFromArray = function (as) {
    return new NonEmptyArray(as[0], as.slice(1));
};
/**
 * Builds {@link NonEmptyArray} from {@link Array} returning {@link Option#none} or {@link Option#some} depending on amount of values in passed array
 * @function
 * @since 1.0.0
 */
exports.fromArray = function (as) {
    return as.length > 0 ? Option_1.some(unsafeFromArray(as)) : Option_1.none;
};
var map = function (fa, f) {
    return fa.map(f);
};
var mapWithIndex = function (fa, f) {
    return fa.mapWithIndex(f);
};
var of = function (a) {
    return new NonEmptyArray(a, []);
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
var concat = function (fx, fy) {
    return fx.concat(fy);
};
/**
 * Builds {@link Semigroup} instance for {@link NonEmptyArray} of specified type arument
 * @function
 * @since 1.0.0
 */
exports.getSemigroup = function () {
    return { concat: concat };
};
/**
 * Group equal, consecutive elements of an array into non empty arrays.
 *
 * @example
 * import { NonEmptyArray, group } from 'fp-ts/lib/NonEmptyArray'
 * import { ordNumber } from 'fp-ts/lib/Ord'
 *
 * assert.deepEqual(group(ordNumber)([1, 2, 1, 1]), [
 *   new NonEmptyArray(1, []),
 *   new NonEmptyArray(2, []),
 *   new NonEmptyArray(1, [1])
 * ])
 *
 * @function
 * @since 1.7.0
 */
exports.group = function (S) { return function (as) {
    var r = [];
    var len = as.length;
    if (len === 0) {
        return r;
    }
    var head = as[0];
    var tail = [];
    for (var i = 1; i < len; i++) {
        var x = as[i];
        if (S.equals(x, head)) {
            tail.push(x);
        }
        else {
            r.push(new NonEmptyArray(head, tail));
            head = x;
            tail = [];
        }
    }
    r.push(new NonEmptyArray(head, tail));
    return r;
}; };
/**
 * Sort and then group the elements of an array into non empty arrays.
 *
 * @example
 * import { NonEmptyArray, groupSort } from 'fp-ts/lib/NonEmptyArray'
 * import { ordNumber } from 'fp-ts/lib/Ord'
 *
 * assert.deepEqual(groupSort(ordNumber)([1, 2, 1, 1]), [new NonEmptyArray(1, [1, 1]), new NonEmptyArray(2, [])])
 *
 * @function
 * @since 1.7.0
 */
exports.groupSort = function (O) {
    return function_1.compose(exports.group(O), Array_1.sort(O));
};
var reduce = function (fa, b, f) {
    return fa.reduce(b, f);
};
var foldMap = function (M) { return function (fa, f) {
    return fa.tail.reduce(function (acc, a) { return M.concat(acc, f(a)); }, f(fa.head));
}; };
var foldr = function (fa, b, f) {
    return fa.foldr(b, f);
};
var reduceWithIndex = function (fa, b, f) {
    return fa.reduceWithIndex(b, f);
};
var foldMapWithIndex = function (M) { return function (fa, f) {
    return fa.tail.reduce(function (acc, a, i) { return M.concat(acc, f(i + 1, a)); }, f(0, fa.head));
}; };
var foldrWithIndex = function (fa, b, f) {
    return fa.foldrWithIndex(b, f);
};
var extend = function (fa, f) {
    return fa.extend(f);
};
var extract = function (fa) {
    return fa.extract();
};
function traverse(F) {
    var traverseWithIndexF = traverseWithIndex(F);
    return function (ta, f) { return traverseWithIndexF(ta, function (_, a) { return f(a); }); };
}
function sequence(F) {
    var sequenceF = Array_1.array.sequence(F);
    return function (ta) {
        return F.ap(F.map(ta.head, function (a) { return function (as) { return new NonEmptyArray(a, as); }; }), sequenceF(ta.tail));
    };
}
/**
 * Splits an array into sub-non-empty-arrays stored in an object, based on the result of calling a `string`-returning
 * function on each element, and grouping the results according to values returned
 *
 * @example
 * import { NonEmptyArray, groupBy } from 'fp-ts/lib/NonEmptyArray'
 *
 * assert.deepEqual(groupBy(['foo', 'bar', 'foobar'], a => String(a.length)), {
 *   '3': new NonEmptyArray('foo', ['bar']),
 *   '6': new NonEmptyArray('foobar', [])
 * })
 *
 * @function
 * @since 1.10.0
 */
exports.groupBy = function (as, f) {
    var r = {};
    for (var _i = 0, as_1 = as; _i < as_1.length; _i++) {
        var a = as_1[_i];
        var k = f(a);
        if (r.hasOwnProperty(k)) {
            r[k].tail.push(a);
        }
        else {
            r[k] = new NonEmptyArray(a, []);
        }
    }
    return r;
};
var traverseWithIndex = function (F) {
    var traverseWithIndexF = Array_1.array.traverseWithIndex(F);
    return function (ta, f) {
        var fb = f(0, ta.head);
        var fbs = traverseWithIndexF(ta.tail, function (i, a) { return f(i + 1, a); });
        return F.ap(F.map(fb, function (b) { return function (bs) { return new NonEmptyArray(b, bs); }; }), fbs);
    };
};
/**
 * @instance
 * @since 1.0.0
 */
exports.nonEmptyArray = {
    URI: exports.URI,
    extend: extend,
    extract: extract,
    map: map,
    mapWithIndex: mapWithIndex,
    of: of,
    ap: ap,
    chain: chain,
    reduce: reduce,
    foldMap: foldMap,
    foldr: foldr,
    traverse: traverse,
    sequence: sequence,
    reduceWithIndex: reduceWithIndex,
    foldMapWithIndex: foldMapWithIndex,
    foldrWithIndex: foldrWithIndex,
    traverseWithIndex: traverseWithIndex
};
