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
var Semigroup_1 = require("./Semigroup");
/**
 * @function
 * @since 1.0.0
 */
exports.fold = function (M) {
    return Semigroup_1.fold(M)(M.empty);
};
/**
 * @function
 * @since 1.0.0
 */
exports.getProductMonoid = function (MA, MB) {
    return __assign({}, Semigroup_1.getProductSemigroup(MA, MB), { empty: [MA.empty, MB.empty] });
};
/**
 * @function
 * @since 1.0.0
 */
exports.getDualMonoid = function (M) {
    return __assign({}, Semigroup_1.getDualSemigroup(M), { empty: M.empty });
};
/**
 * Boolean monoid under conjunction
 * @instance
 * @since 1.0.0
 */
exports.monoidAll = __assign({}, Semigroup_1.semigroupAll, { empty: true });
/**
 * Boolean monoid under disjunction
 * @instance
 * @since 1.0.0
 */
exports.monoidAny = __assign({}, Semigroup_1.semigroupAny, { empty: false });
var emptyArray = [];
/**
 * @instance
 * @since 1.0.0
 */
exports.unsafeMonoidArray = __assign({}, Semigroup_1.getArraySemigroup(), { empty: emptyArray });
/**
 * Monoid under array concatenation (`Array<any>`)
 * @function
 * @since 1.0.0
 */
exports.getArrayMonoid = function () {
    return exports.unsafeMonoidArray;
};
var emptyObject = {};
/**
 * Gets {@link Monoid} instance for dictionaries given {@link Semigroup} instance for their values
 *
 * @example
 * import { getDictionaryMonoid, fold } from 'fp-ts/lib/Monoid'
 * import { semigroupSum } from 'fp-ts/lib/Semigroup'
 *
 * const M = getDictionaryMonoid(semigroupSum)
 * assert.deepEqual(fold(M)([{ foo: 123 }, { foo: 456 }]), { foo: 579 })
 *
 * @function
 * @since 1.4.0
 */
exports.getDictionaryMonoid = function (S) {
    return __assign({}, Semigroup_1.getDictionarySemigroup(S), { empty: emptyObject });
};
/**
 * Number monoid under addition
 * @instance
 * @since 1.0.0
 */
exports.monoidSum = __assign({}, Semigroup_1.semigroupSum, { empty: 0 });
/**
 * Number monoid under multiplication
 * @instance
 * @since 1.0.0
 */
exports.monoidProduct = __assign({}, Semigroup_1.semigroupProduct, { empty: 1 });
/**
 * @instance
 * @since 1.0.0
 */
exports.monoidString = __assign({}, Semigroup_1.semigroupString, { empty: '' });
/**
 * @instance
 * @since 1.0.0
 */
exports.monoidVoid = __assign({}, Semigroup_1.semigroupVoid, { empty: undefined });
/**
 * @function
 * @since 1.0.0
 */
exports.getFunctionMonoid = function (M) { return function () {
    return __assign({}, Semigroup_1.getFunctionSemigroup(M)(), { empty: function () { return M.empty; } });
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getEndomorphismMonoid = function () {
    return {
        concat: function_1.compose,
        empty: function_1.identity
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getRecordMonoid = function (monoids) {
    var empty = {};
    var keys = Object.keys(monoids);
    for (var _i = 0, keys_1 = keys; _i < keys_1.length; _i++) {
        var key = keys_1[_i];
        empty[key] = monoids[key].empty;
    }
    return __assign({}, Semigroup_1.getRecordSemigroup(monoids), { empty: empty });
};
/**
 * @function
 * @since 1.9.0
 */
exports.getMeetMonoid = function (B) {
    return __assign({}, Semigroup_1.getMeetSemigroup(B), { empty: B.top });
};
/**
 * @function
 * @since 1.9.0
 */
exports.getJoinMonoid = function (B) {
    return __assign({}, Semigroup_1.getJoinSemigroup(B), { empty: B.bottom });
};
