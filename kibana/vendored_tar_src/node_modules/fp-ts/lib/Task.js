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
var Either_1 = require("./Either");
var function_1 = require("./function");
exports.URI = 'Task';
/**
 * `Task<A>` represents an asynchronous computation that yields a value of type `A` and **never fails**.
 * If you want to represent an asynchronous computation that may fail, please see {@link TaskEither}.
 * @data
 * @constructor Task
 * @since 1.0.0
 */
var Task = /** @class */ (function () {
    function Task(run) {
        this.run = run;
    }
    Task.prototype.map = function (f) {
        var _this = this;
        return new Task(function () { return _this.run().then(f); });
    };
    Task.prototype.ap = function (fab) {
        var _this = this;
        return new Task(function () { return Promise.all([fab.run(), _this.run()]).then(function (_a) {
            var f = _a[0], a = _a[1];
            return f(a);
        }); });
    };
    /**
     * Flipped version of {@link ap}
     */
    Task.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two effectful actions, keeping only the result of the first
     * @since 1.6.0
     */
    Task.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two effectful actions, keeping only the result of the second
     * @since 1.5.0
     */
    Task.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    Task.prototype.chain = function (f) {
        var _this = this;
        return new Task(function () { return _this.run().then(function (a) { return f(a).run(); }); });
    };
    Task.prototype.inspect = function () {
        return this.toString();
    };
    Task.prototype.toString = function () {
        return "new Task(" + function_1.toString(this.run) + ")";
    };
    return Task;
}());
exports.Task = Task;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new Task(function () { return Promise.resolve(a); });
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
exports.getRaceMonoid = function () {
    return {
        concat: function (x, y) {
            return new Task(function () {
                return new Promise(function (resolve, reject) {
                    var running = true;
                    var resolveFirst = function (a) {
                        if (running) {
                            running = false;
                            resolve(a);
                        }
                    };
                    var rejectFirst = function (e) {
                        if (running) {
                            running = false;
                            reject(e);
                        }
                    };
                    x.run().then(resolveFirst, rejectFirst);
                    y.run().then(resolveFirst, rejectFirst);
                });
            });
        },
        empty: never
    };
};
var never = new Task(function () { return new Promise(function (_) { return undefined; }); });
/**
 * @function
 * @since 1.0.0
 */
exports.getSemigroup = function (S) {
    return {
        concat: function (x, y) { return new Task(function () { return x.run().then(function (rx) { return y.run().then(function (ry) { return S.concat(rx, ry); }); }); }); }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getMonoid = function (M) {
    return __assign({}, exports.getSemigroup(M), { empty: of(M.empty) });
};
/**
 * @function
 * @since 1.0.0
 */
exports.tryCatch = function (f, onrejected) {
    return new Task(function () { return f().then(function (a) { return Either_1.right(a); }, function (reason) { return Either_1.left(onrejected(reason)); }); });
};
/**
 * Lifts an IO action into a Task
 * @function
 * @since 1.0.0
 */
exports.fromIO = function (io) {
    return new Task(function () { return Promise.resolve(io.run()); });
};
/**
 * @function
 * @since 1.7.0
 */
exports.delay = function (millis, a) {
    return new Task(function () {
        return new Promise(function (resolve) {
            setTimeout(function () {
                resolve(a);
            }, millis);
        });
    });
};
var fromTask = function_1.identity;
/**
 * @instance
 * @since 1.0.0
 */
exports.task = {
    URI: exports.URI,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    fromIO: exports.fromIO,
    fromTask: fromTask
};
/**
 * Like {@link task} but `ap` is sequential
 * @instance
 * @since 1.10.0
 */
exports.taskSeq = __assign({}, exports.task, { ap: function (fab, fa) { return fab.chain(function (f) { return fa.map(f); }); } });
