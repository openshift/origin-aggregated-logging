"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
exports.URI = 'Writer';
/**
 * @data
 * @constructor Writer
 * @since 1.0.0
 */
var Writer = /** @class */ (function () {
    function Writer(run) {
        this.run = run;
    }
    Writer.prototype.eval = function () {
        return this.run()[0];
    };
    Writer.prototype.exec = function () {
        return this.run()[1];
    };
    Writer.prototype.map = function (f) {
        var _this = this;
        return new Writer(function () {
            var _a = _this.run(), a = _a[0], w = _a[1];
            return [f(a), w];
        });
    };
    return Writer;
}());
exports.Writer = Writer;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (M) { return function (a) {
    return new Writer(function () { return [a, M.empty]; });
}; };
var ap = function (S) { return function (fab, fa) {
    return new Writer(function () {
        var _a = fab.run(), f = _a[0], w1 = _a[1];
        var _b = fa.run(), a = _b[0], w2 = _b[1];
        return [f(a), S.concat(w1, w2)];
    });
}; };
var chain = function (S) { return function (fa, f) {
    return new Writer(function () {
        var _a = fa.run(), a = _a[0], w1 = _a[1];
        var _b = f(a).run(), b = _b[0], w2 = _b[1];
        return [b, S.concat(w1, w2)];
    });
}; };
/**
 * Appends a value to the accumulator
 * @function
 * @since 1.0.0
 */
exports.tell = function (w) {
    return new Writer(function () { return [undefined, w]; });
};
/**
 * Modifies the result to include the changes to the accumulator
 * @function
 * @since 1.3.0
 */
exports.listen = function (fa) {
    return new Writer(function () {
        var _a = fa.run(), a = _a[0], w = _a[1];
        return [function_1.tuple(a, w), w];
    });
};
/**
 * Applies the returned function to the accumulator
 * @function
 * @since 1.3.0
 */
exports.pass = function (fa) {
    return new Writer(function () {
        var _a = fa.run(), _b = _a[0], a = _b[0], f = _b[1], w = _a[1];
        return [a, f(w)];
    });
};
/**
 * Projects a value from modifications made to the accumulator during an action
 * @function
 * @since 1.3.0
 */
exports.listens = function (fa, f) {
    return new Writer(function () {
        var _a = fa.run(), a = _a[0], w = _a[1];
        return [function_1.tuple(a, f(w)), w];
    });
};
/**
 * Modify the final accumulator value by applying a function
 * @function
 * @since 1.3.0
 */
exports.censor = function (fa, f) {
    return new Writer(function () {
        var _a = fa.run(), a = _a[0], w = _a[1];
        return [a, f(w)];
    });
};
/**
 * @function
 * @since 1.0.0
 */
exports.getMonad = function (M) {
    return {
        URI: exports.URI,
        _L: function_1.phantom,
        map: map,
        of: of(M),
        ap: ap(M),
        chain: chain(M)
    };
};
/**
 * @instance
 * @since 1.0.0
 */
exports.writer = {
    URI: exports.URI,
    map: map
};
