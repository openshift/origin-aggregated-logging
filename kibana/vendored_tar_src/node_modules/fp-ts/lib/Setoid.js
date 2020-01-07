"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
/**
 * @function
 * @since 1.0.0
 */
exports.strictEqual = function (a, b) {
    return a === b;
};
var setoidStrict = { equals: exports.strictEqual };
/**
 * @instance
 * @since 1.0.0
 */
exports.setoidString = setoidStrict;
/**
 * @instance
 * @since 1.0.0
 */
exports.setoidNumber = setoidStrict;
/**
 * @instance
 * @since 1.0.0
 */
exports.setoidBoolean = setoidStrict;
/**
 * @function
 * @since 1.0.0
 */
exports.getArraySetoid = function (S) {
    return {
        equals: function (xs, ys) { return xs.length === ys.length && xs.every(function (x, i) { return S.equals(x, ys[i]); }); }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getRecordSetoid = function (setoids) {
    return {
        equals: function (x, y) {
            for (var k in setoids) {
                if (!setoids[k].equals(x[k], y[k])) {
                    return false;
                }
            }
            return true;
        }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getProductSetoid = function (SA, SB) {
    return {
        equals: function (_a, _b) {
            var xa = _a[0], xb = _a[1];
            var ya = _b[0], yb = _b[1];
            return SA.equals(xa, ya) && SB.equals(xb, yb);
        }
    };
};
/**
 * Returns the `Setoid` corresponding to the partitions of `B` induced by `f`
 * @function
 * @since 1.2.0
 */
exports.contramap = function (f, fa) {
    return {
        equals: function_1.on(fa.equals)(f)
    };
};
/**
 * @instance
 * @since 1.4.0
 */
exports.setoidDate = exports.contramap(function (date) { return date.valueOf(); }, exports.setoidNumber);
