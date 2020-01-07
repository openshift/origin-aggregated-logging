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
exports.URI = 'Const';
/**
 * @data
 * @constructor Const
 * @since 1.0.0
 */
var Const = /** @class */ (function () {
    function Const(value) {
        this.value = value;
    }
    Const.prototype.map = function (f) {
        return this;
    };
    Const.prototype.contramap = function (f) {
        return this;
    };
    Const.prototype.fold = function (f) {
        return f(this.value);
    };
    Const.prototype.inspect = function () {
        return this.toString();
    };
    Const.prototype.toString = function () {
        return "new Const(" + function_1.toString(this.value) + ")";
    };
    return Const;
}());
exports.Const = Const;
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (S) {
    return {
        equals: function (x, y) { return S.equals(x.value, y.value); }
    };
};
var map = function (fa, f) {
    return fa.map(f);
};
var contramap = function (fa, f) {
    return fa.contramap(f);
};
var ap = function (S) { return function (fab, fa) {
    return new Const(S.concat(fab.value, fa.value));
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
    return new Const(M.empty);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getApplicative = function (M) {
    return __assign({}, exports.getApply(M), { of: of(M) });
};
/**
 * @instance
 * @since 1.0.0
 */
exports.const_ = {
    URI: exports.URI,
    map: map,
    contramap: contramap
};
