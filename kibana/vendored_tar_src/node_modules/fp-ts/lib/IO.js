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
exports.URI = 'IO';
/**
 * `IO<A>` represents a synchronous computation that yields a value of type `A` and **never fails**.
 * If you want to represent a synchronous computation that may fail, please see {@link IOEither}.
 * @data
 * @constructor IO
 * @since 1.0.0
 */
var IO = /** @class */ (function () {
    function IO(run) {
        this.run = run;
    }
    IO.prototype.map = function (f) {
        var _this = this;
        return new IO(function () { return f(_this.run()); });
    };
    IO.prototype.ap = function (fab) {
        var _this = this;
        return new IO(function () { return fab.run()(_this.run()); });
    };
    /**
     * Flipped version of {@link ap}
     */
    IO.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two effectful actions, keeping only the result of the first
     * @since 1.6.0
     */
    IO.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two effectful actions, keeping only the result of the second
     * @since 1.5.0
     */
    IO.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    IO.prototype.chain = function (f) {
        var _this = this;
        return new IO(function () { return f(_this.run()).run(); });
    };
    IO.prototype.inspect = function () {
        return this.toString();
    };
    IO.prototype.toString = function () {
        return "new IO(" + function_1.toString(this.run) + ")";
    };
    return IO;
}());
exports.IO = IO;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new IO(function () { return a; });
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
/**
 * @function
 * @since 1.0.0
 */
exports.getSemigroup = function (S) {
    return {
        concat: function (x, y) {
            return new IO(function () {
                var xr = x.run();
                var yr = y.run();
                return S.concat(xr, yr);
            });
        }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getMonoid = function (M) {
    return __assign({}, exports.getSemigroup(M), { empty: of(M.empty) });
};
var fromIO = function_1.identity;
/**
 * @instance
 * @since 1.0.0
 */
exports.io = {
    URI: exports.URI,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    fromIO: fromIO
};
