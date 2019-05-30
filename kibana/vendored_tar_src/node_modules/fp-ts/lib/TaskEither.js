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
var eitherT = require("./EitherT");
var function_1 = require("./function");
var Task_1 = require("./Task");
var eitherTTask = eitherT.getEitherT(Task_1.task);
exports.URI = 'TaskEither';
var eitherTfold = eitherT.fold(Task_1.task);
var eitherTmapLeft = eitherT.mapLeft(Task_1.task);
var eitherTbimap = eitherT.bimap(Task_1.task);
/**
 * `TaskEither<L, A>` represents an asynchronous computation that either yields a value of type `A` or fails yielding an
 * error of type `L`. If you want to represent an asynchronous computation that never fails, please see {@link Task}.
 * @data
 * @constructor TaskEither
 * @since 1.0.0
 */
var TaskEither = /** @class */ (function () {
    function TaskEither(value) {
        this.value = value;
    }
    /** Runs the inner `Task` */
    TaskEither.prototype.run = function () {
        return this.value.run();
    };
    TaskEither.prototype.map = function (f) {
        return new TaskEither(eitherTTask.map(this.value, f));
    };
    TaskEither.prototype.ap = function (fab) {
        return new TaskEither(eitherTTask.ap(fab.value, this.value));
    };
    /**
     * Flipped version of {@link ap}
     */
    TaskEither.prototype.ap_ = function (fb) {
        return fb.ap(this);
    };
    /**
     * Combine two (parallel) effectful actions, keeping only the result of the first
     * @since 1.6.0
     */
    TaskEither.prototype.applyFirst = function (fb) {
        return fb.ap(this.map(function_1.constant));
    };
    /**
     * Combine two (parallel) effectful actions, keeping only the result of the second
     * @since 1.5.0
     */
    TaskEither.prototype.applySecond = function (fb) {
        return fb.ap(this.map(function_1.constIdentity));
    };
    /**
     * Combine two (sequential) effectful actions, keeping only the result of the first
     * @since 1.12.0
     */
    TaskEither.prototype.chainFirst = function (fb) {
        return this.chain(function (a) { return fb.map(function () { return a; }); });
    };
    /**
     * Combine two (sequential) effectful actions, keeping only the result of the second
     * @since 1.12.0
     */
    TaskEither.prototype.chainSecond = function (fb) {
        return this.chain(function () { return fb; });
    };
    TaskEither.prototype.chain = function (f) {
        return new TaskEither(eitherTTask.chain(function (a) { return f(a).value; }, this.value));
    };
    TaskEither.prototype.fold = function (whenLeft, whenRight) {
        return eitherTfold(whenLeft, whenRight, this.value);
    };
    /**
     * Similar to {@link fold}, but the result is flattened.
     * @since 1.10.0
     */
    TaskEither.prototype.foldTask = function (whenLeft, whenRight) {
        return this.value.chain(function (e) { return e.fold(whenLeft, whenRight); });
    };
    /**
     * Similar to {@link fold}, but the result is flattened.
     * @since 1.10.0
     */
    TaskEither.prototype.foldTaskEither = function (whenLeft, whenRight) {
        return new TaskEither(this.value.chain(function (e) { return e.fold(whenLeft, whenRight).value; }));
    };
    TaskEither.prototype.mapLeft = function (f) {
        return new TaskEither(eitherTmapLeft(f)(this.value));
    };
    /**
     * Transforms the failure value of the `TaskEither` into a new `TaskEither`
     */
    TaskEither.prototype.orElse = function (f) {
        return new TaskEither(this.value.chain(function (e) { return e.fold(function (l) { return f(l).value; }, eitherTTask.of); }));
    };
    /**
     * @since 1.6.0
     */
    TaskEither.prototype.alt = function (fy) {
        return this.orElse(function () { return fy; });
    };
    /**
     * @since 1.2.0
     */
    TaskEither.prototype.bimap = function (f, g) {
        return new TaskEither(eitherTbimap(this.value, f, g));
    };
    /**
     * Return `Right` if the given action succeeds, `Left` if it throws
     * @since 1.10.0
     */
    TaskEither.prototype.attempt = function () {
        return new TaskEither(this.value.map(Either_1.right));
    };
    TaskEither.prototype.filterOrElse = function (p, zero) {
        return new TaskEither(this.value.map(function (e) { return e.filterOrElse(p, zero); }));
    };
    TaskEither.prototype.filterOrElseL = function (p, zero) {
        return new TaskEither(this.value.map(function (e) { return e.filterOrElseL(p, zero); }));
    };
    return TaskEither;
}());
exports.TaskEither = TaskEither;
var map = function (fa, f) {
    return fa.map(f);
};
var of = function (a) {
    return new TaskEither(eitherTTask.of(a));
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
var eitherTright = eitherT.right(Task_1.task);
/**
 * @function
 * @since 1.0.0
 */
exports.right = function (fa) {
    return new TaskEither(eitherTright(fa));
};
var eitherTleft = eitherT.left(Task_1.task);
/**
 * @function
 * @since 1.0.0
 */
exports.left = function (fa) {
    return new TaskEither(eitherTleft(fa));
};
var eitherTfromEither = eitherT.fromEither(Task_1.task);
/**
 * @function
 * @since 1.0.0
 */
exports.fromEither = function (fa) {
    return new TaskEither(eitherTfromEither(fa));
};
/**
 * @function
 * @since 1.5.0
 */
exports.fromIO = function (fa) {
    return exports.right(Task_1.fromIO(fa));
};
/**
 * @function
 * @since 1.3.0
 */
exports.fromLeft = function (l) {
    return exports.fromEither(Either_1.left(l));
};
/**
 * @function
 * @since 1.6.0
 */
exports.fromIOEither = function (fa) {
    return new TaskEither(Task_1.fromIO(fa.value));
};
function fromPredicate(predicate, whenFalse) {
    var f = Either_1.fromPredicate(predicate, whenFalse);
    return function (a) { return exports.fromEither(f(a)); };
}
exports.fromPredicate = fromPredicate;
/**
 * @function
 * @since 1.9.0
 */
exports.getSemigroup = function (S) {
    var S2 = Task_1.getSemigroup(Either_1.getSemigroup(S));
    return {
        concat: function (x, y) { return new TaskEither(S2.concat(x.value, y.value)); }
    };
};
/**
 * @function
 * @since 1.9.0
 */
exports.getApplySemigroup = function (S) {
    var S2 = Task_1.getSemigroup(Either_1.getApplySemigroup(S));
    return {
        concat: function (x, y) { return new TaskEither(S2.concat(x.value, y.value)); }
    };
};
/**
 * @function
 * @since 1.9.0
 */
exports.getApplyMonoid = function (M) {
    return __assign({}, exports.getApplySemigroup(M), { empty: of(M.empty) });
};
/**
 * Transforms a `Promise` into a `TaskEither`, catching the possible error.
 *
 * @example
 * import { createHash } from 'crypto'
 * import { TaskEither, tryCatch } from 'fp-ts/lib/TaskEither'
 * import { createReadStream } from 'fs'
 * import { left } from 'fp-ts/lib/Either'
 *
 * const md5 = (path: string): TaskEither<string, string> => {
 *   const mkHash = (p: string) =>
 *     new Promise<string>((resolve, reject) => {
 *       const hash = createHash('md5')
 *       const rs = createReadStream(p)
 *       rs.on('error', (error: Error) => reject(error.message))
 *       rs.on('data', (chunk: string) => hash.update(chunk))
 *       rs.on('end', () => {
 *         return resolve(hash.digest('hex'))
 *       })
 *     })
 *   return tryCatch(() => mkHash(path), message => `cannot create md5 hash: ${String(message)}`)
 * }
 *
 * md5('foo')
 *   .run()
 *   .then(x => {
 *     assert.deepEqual(x, left(`cannot create md5 hash: ENOENT: no such file or directory, open 'foo'`))
 *   })
 *
 * @function
 * @since 1.0.0
 */
exports.tryCatch = function (f, onrejected) {
    return new TaskEither(Task_1.tryCatch(f, onrejected));
};
function taskify(f) {
    return function () {
        var args = Array.prototype.slice.call(arguments);
        return new TaskEither(new Task_1.Task(function () {
            return new Promise(function (resolve) {
                var cbResolver = function (e, r) {
                    return e != null ? resolve(Either_1.left(e)) : resolve(Either_1.right(r));
                };
                f.apply(null, args.concat(cbResolver));
            });
        }));
    };
}
exports.taskify = taskify;
var fromTask = exports.right;
/**
 * Make sure that a resource is cleaned up in the event of an exception. The
 * release action is called regardless of whether the body action throws or
 * returns.
 * @function
 * @since 1.10.0
 */
exports.bracket = function (acquire, use, release) {
    return acquire.chain(function (a) {
        return use(a)
            .attempt()
            .chain(function (e) { return release(a, e).chain(function () { return e.fold(exports.fromLeft, exports.taskEither.of); }); });
    });
};
/**
 * @instance
 * @since 1.0.0
 */
exports.taskEither = {
    URI: exports.URI,
    bimap: bimap,
    map: map,
    of: of,
    ap: ap,
    chain: chain,
    alt: alt,
    fromIO: exports.fromIO,
    fromTask: fromTask
};
/**
 * Like {@link taskEither} but `ap` is sequential
 * @instance
 * @since 1.10.0
 */
exports.taskEitherSeq = __assign({}, exports.taskEither, { ap: function (fab, fa) { return fab.chain(function (f) { return fa.map(f); }); } });
