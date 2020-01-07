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
var Reader_1 = require("./Reader");
var readerT = require("./ReaderT");
var taskEither = require("./TaskEither");
var readerTTaskEither = readerT.getReaderT(taskEither.taskEither);
exports.URI = 'ReaderTaskEither';
/**
 * @data
 * @constructor ReaderTaskEither
 * @since 1.6.0
 */
var ReaderTaskEither = /** @class */ (function () {
    function ReaderTaskEither(value) {
        this.value = value;
    }
    /** Runs the inner `TaskEither` */
    ReaderTaskEither.prototype.run = function (e) {
        return this.value(e).run();
    };
    ReaderTaskEither.prototype.map = function (f) {
        return new ReaderTaskEither(readerTTaskEither.map(f, this.value));
    };
    ReaderTaskEither.prototype.ap = function (fab) {
        return new ReaderTaskEither(readerTTaskEither.ap(fab.value, this.value));
    };
    /**
     * Flipped version of {@link ap}
     */
    ReaderTaskEither.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two effectful actions, keeping only the result of the first
     */
    ReaderTaskEither.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two effectful actions, keeping only the result of the second
     */
    ReaderTaskEither.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    ReaderTaskEither.prototype.chain = function (f) {
        return new ReaderTaskEither(readerTTaskEither.chain(function (a) { return f(a).value; }, this.value));
    };
    ReaderTaskEither.prototype.fold = function (left, right) {
        var _this = this;
        return new Reader_1.Reader(function (e) { return _this.value(e).fold(left, right); });
    };
    ReaderTaskEither.prototype.mapLeft = function (f) {
        var _this = this;
        return new ReaderTaskEither(function (e) { return _this.value(e).mapLeft(f); });
    };
    /**
     * Transforms the failure value of the `ReaderTaskEither` into a new `ReaderTaskEither`
     */
    ReaderTaskEither.prototype.orElse = function (f) {
        var _this = this;
        return new ReaderTaskEither(function (e) { return _this.value(e).orElse(function (l) { return f(l).value(e); }); });
    };
    ReaderTaskEither.prototype.alt = function (fy) {
        return this.orElse(function () { return fy; });
    };
    ReaderTaskEither.prototype.bimap = function (f, g) {
        var _this = this;
        return new ReaderTaskEither(function (e) { return _this.value(e).bimap(f, g); });
    };
    /**
     * @since 1.6.1
     */
    ReaderTaskEither.prototype.local = function (f) {
        var _this = this;
        return new ReaderTaskEither(function (e) { return _this.value(f(e)); });
    };
    return ReaderTaskEither;
}());
exports.ReaderTaskEither = ReaderTaskEither;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new ReaderTaskEither(readerTTaskEither.of(a));
};
var ap = function (fab, fa) {
    return fa.ap(fab);
};
var chain = function (fa, f) {
    return fa.chain(f);
};
var alt = function (fx, fy) {
    return fx.alt(fy);
};
var bimap = function (fa, f, g) {
    return fa.bimap(f, g);
};
var readerTask = readerT.ask(taskEither.taskEither);
/**
 * @function
 * @since 1.6.0
 */
exports.ask = function () {
    return new ReaderTaskEither(readerTask());
};
var readerTasks = readerT.asks(taskEither.taskEither);
/**
 * @function
 * @since 1.6.0
 */
exports.asks = function (f) {
    return new ReaderTaskEither(readerTasks(f));
};
/**
 * @function
 * @since 1.6.0
 */
exports.local = function (f) { return function (fa) {
    return fa.local(f);
}; };
/**
 * @function
 * @since 1.6.0
 */
exports.right = function (fa) {
    return new ReaderTaskEither(function () { return taskEither.right(fa); });
};
/**
 * @function
 * @since 1.6.0
 */
exports.left = function (fa) {
    return new ReaderTaskEither(function () { return taskEither.left(fa); });
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromTaskEither = function (fa) {
    return new ReaderTaskEither(function () { return fa; });
};
var readerTfromReader = readerT.fromReader(taskEither.taskEither);
/**
 * @function
 * @since 1.6.0
 */
exports.fromReader = function (fa) {
    return new ReaderTaskEither(readerTfromReader(fa));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromEither = function (fa) {
    return exports.fromTaskEither(taskEither.fromEither(fa));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromIO = function (fa) {
    return exports.fromTaskEither(taskEither.fromIO(fa));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromLeft = function (l) {
    return exports.fromTaskEither(taskEither.fromLeft(l));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromIOEither = function (fa) {
    return exports.fromTaskEither(taskEither.fromIOEither(fa));
};
function fromPredicate(predicate, whenFalse) {
    var f = taskEither.fromPredicate(predicate, whenFalse);
    return function (a) { return exports.fromTaskEither(f(a)); };
}
exports.fromPredicate = fromPredicate;
/**
 * @function
 * @since 1.6.0
 */
exports.tryCatch = function (f, onrejected) {
    return new ReaderTaskEither(function (e) { return taskEither.tryCatch(function () { return f(e); }, function (reason) { return onrejected(reason, e); }); });
};
var fromTask = exports.right;
/**
 * @instance
 * @since 1.6.0
 */
exports.readerTaskEither = {
    URI: exports.URI,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    alt: alt,
    bimap: bimap,
    fromIO: exports.fromIO,
    fromTask: fromTask
};
/**
 * Like {@link readerTaskEither} but `ap` is sequential
 * @instance
 * @since 1.10.0
 */
exports.readerTaskEitherSeq = __assign({}, exports.readerTaskEither, { ap: function (fab, fa) { return fab.chain(function (f) { return fa.map(f); }); } });
