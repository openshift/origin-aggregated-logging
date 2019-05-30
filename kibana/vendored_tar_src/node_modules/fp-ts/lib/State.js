"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
exports.URI = 'State';
/**
 * @data
 * @constructor State
 * @since 1.0.0
 */
var State = /** @class */ (function () {
    function State(run) {
        this.run = run;
    }
    State.prototype.eval = function (s) {
        return this.run(s)[0];
    };
    State.prototype.exec = function (s) {
        return this.run(s)[1];
    };
    State.prototype.map = function (f) {
        var _this = this;
        return new State(function (s) {
            var _a = _this.run(s), a = _a[0], s1 = _a[1];
            return [f(a), s1];
        });
    };
    State.prototype.ap = function (fab) {
        var _this = this;
        return fab.chain(function (f) { return _this.map(f); }); // <= derived
    };
    /**
     * Flipped version of {@link ap}
     */
    State.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two effectful actions, keeping only the result of the first
     * @since 1.7.0
     */
    State.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two effectful actions, keeping only the result of the second
     * @since 1.7.0
     */
    State.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    State.prototype.chain = function (f) {
        var _this = this;
        return new State(function (s) {
            var _a = _this.run(s), a = _a[0], s1 = _a[1];
            return f(a).run(s1);
        });
    };
    return State;
}());
exports.State = State;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new State(function (s) { return [a, s]; });
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
/**
 * Get the current state
 * @function
 * @since 1.0.0
 */
exports.get = function () {
    return new State(function (s) { return [s, s]; });
};
/**
 * Set the state
 * @function
 * @since 1.0.0
 */
exports.put = function (s) {
    return new State(function () { return [undefined, s]; });
};
/**
 * Modify the state by applying a function to the current state
 * @function
 * @since 1.0.0
 */
exports.modify = function (f) {
    return new State(function (s) { return [undefined, f(s)]; });
};
/**
 * Get a value which depends on the current state
 * @function
 * @since 1.0.0
 */
exports.gets = function (f) {
    return new State(function (s) { return [f(s), s]; });
};
/**
 * @instance
 * @since 1.0.0
 */
exports.state = {
    URI: exports.URI,
    map: map,
    of: of,
    ap: ap,
    chain: chain
};
