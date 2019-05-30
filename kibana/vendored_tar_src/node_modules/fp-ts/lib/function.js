"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * @function
 * @since 1.0.0
 */
exports.identity = function (a) {
    return a;
};
/**
 * @constant
 * @since 1.0.0
 */
exports.unsafeCoerce = exports.identity;
/**
 * @function
 * @since 1.0.0
 */
exports.not = function (predicate) {
    return function (a) { return !predicate(a); };
};
function or(p1, p2) {
    return function (a) { return p1(a) || p2(a); };
}
exports.or = or;
/**
 * @function
 * @since 1.0.0
 */
exports.and = function (p1, p2) {
    return function (a) { return p1(a) && p2(a); };
};
/**
 * @function
 * @since 1.0.0
 */
exports.constant = function (a) {
    return function () { return a; };
};
/**
 * A thunk that returns always `true`
 * @function
 * @since 1.0.0
 */
exports.constTrue = function () {
    return true;
};
/**
 * A thunk that returns always `false`
 * @function
 * @since 1.0.0
 */
exports.constFalse = function () {
    return false;
};
/**
 * A thunk that returns always `null`
 * @function
 * @since 1.0.0
 */
exports.constNull = function () {
    return null;
};
/**
 * A thunk that returns always `undefined`
 * @function
 * @since 1.0.0
 */
exports.constUndefined = function () {
    return;
};
/**
 * Flips the order of the arguments to a function of two arguments.
 * @function
 * @since 1.0.0
 */
exports.flip = function (f) {
    return function (b) { return function (a) { return f(a)(b); }; };
};
/**
 * The `on` function is used to change the domain of a binary operator.
 * @function
 * @since 1.0.0
 */
exports.on = function (op) { return function (f) {
    return function (x, y) { return op(f(x), f(y)); };
}; };
function compose() {
    var fns = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        fns[_i] = arguments[_i];
    }
    var len = fns.length - 1;
    return function (x) {
        var y = x;
        for (var i = len; i > -1; i--) {
            y = fns[i].call(this, y);
        }
        return y;
    };
}
exports.compose = compose;
function pipe() {
    var fns = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        fns[_i] = arguments[_i];
    }
    var len = fns.length - 1;
    return function (x) {
        var y = x;
        for (var i = 0; i <= len; i++) {
            y = fns[i].call(this, y);
        }
        return y;
    };
}
exports.pipe = pipe;
/**
 * @function
 * @since 1.0.0
 */
exports.concat = function (x, y) {
    var lenx = x.length;
    var leny = y.length;
    var r = Array(lenx + leny);
    for (var i = 0; i < lenx; i++) {
        r[i] = x[i];
    }
    for (var i = 0; i < leny; i++) {
        r[i + lenx] = y[i];
    }
    return r;
};
function curried(f, n, acc) {
    return function (x) {
        var combined = exports.concat(acc, [x]);
        return n === 0 ? f.apply(this, combined) : curried(f, n - 1, combined);
    };
}
exports.curried = curried;
function curry(f) {
    return curried(f, f.length - 1, []);
}
exports.curry = curry;
/* tslint:disable-next-line */
var getFunctionName = function (f) { return f.displayName || f.name || "<function" + f.length + ">"; };
/**
 * @function
 * @since 1.0.0
 */
exports.toString = function (x) {
    if (typeof x === 'string') {
        return JSON.stringify(x);
    }
    if (x instanceof Date) {
        return "new Date('" + x.toISOString() + "')";
    }
    if (Array.isArray(x)) {
        return "[" + x.map(exports.toString).join(', ') + "]";
    }
    if (typeof x === 'function') {
        return getFunctionName(x);
    }
    if (x == null) {
        return String(x);
    }
    if (typeof x.toString === 'function' && x.toString !== Object.prototype.toString) {
        return x.toString();
    }
    try {
        return JSON.stringify(x, null, 2);
    }
    catch (e) {
        return String(x);
    }
};
/**
 * @function
 * @since 1.0.0
 */
exports.tuple = function (a, b) {
    return [a, b];
};
/**
 * @function
 * @since 1.0.0
 */
exports.tupleCurried = function (a) { return function (b) {
    return [a, b];
}; };
/**
 * Applies a function to an argument ($)
 * @function
 * @since 1.0.0
 */
exports.apply = function (f) { return function (a) {
    return f(a);
}; };
/**
 * Applies an argument to a function (#)
 * @function
 * @since 1.0.0
 */
exports.applyFlipped = function (a) { return function (f) {
    return f(a);
}; };
/** For use with phantom fields */
exports.phantom = undefined;
/**
 * A thunk that returns always the `identity` function.
 * For use with `applySecond` methods.
 * @function
 * @since 1.5.0
 */
exports.constIdentity = function () {
    return exports.identity;
};
/**
 * @function
 * @since 1.9.0
 */
exports.increment = function (n) {
    return n + 1;
};
/**
 * @function
 * @since 1.9.0
 */
exports.decrement = function (n) {
    return n - 1;
};
