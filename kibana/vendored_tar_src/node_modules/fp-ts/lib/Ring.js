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
var Semiring_1 = require("./Semiring");
/**
 * @function
 * @since 1.0.0
 */
exports.getFunctionRing = function (ring) {
    return __assign({}, Semiring_1.getFunctionSemiring(ring), { sub: function (f, g) { return function (x) { return ring.sub(f(x), g(x)); }; } });
};
/**
 * `negate x` can be used as a shorthand for `zero - x`
 * @function
 * @since 1.0.0
 */
exports.negate = function (ring) { return function (a) {
    return ring.sub(ring.zero, a);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getProductRing = function (RA, RB) {
    return {
        add: function (_a, _b) {
            var a1 = _a[0], b1 = _a[1];
            var a2 = _b[0], b2 = _b[1];
            return [RA.add(a1, a2), RB.add(b1, b2)];
        },
        zero: [RA.zero, RB.zero],
        mul: function (_a, _b) {
            var a1 = _a[0], b1 = _a[1];
            var a2 = _b[0], b2 = _b[1];
            return [RA.mul(a1, a2), RB.mul(b1, b2)];
        },
        one: [RA.one, RB.one],
        sub: function (_a, _b) {
            var a1 = _a[0], b1 = _a[1];
            var a2 = _b[0], b2 = _b[1];
            return [RA.sub(a1, a2), RB.sub(b1, b2)];
        }
    };
};
