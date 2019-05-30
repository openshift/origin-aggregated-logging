"use strict";
// adapted from https://github.com/purescript/purescript-prelude/blob/master/src/Data/Semiring.purs
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * @function
 * @since 1.0.0
 */
exports.getFunctionSemiring = function (S) {
    return {
        add: function (f, g) { return function (x) { return S.add(f(x), g(x)); }; },
        zero: function () { return S.zero; },
        mul: function (f, g) { return function (x) { return S.mul(f(x), g(x)); }; },
        one: function () { return S.one; }
    };
};
