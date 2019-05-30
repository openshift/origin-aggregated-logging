"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
function applyFirst(F) {
    return function (fa, fb) { return F.ap(F.map(fa, function_1.constant), fb); };
}
exports.applyFirst = applyFirst;
function applySecond(F) {
    return function (fa, fb) { return F.ap(F.map(fa, function () { return function (b) { return b; }; }), fb); };
}
exports.applySecond = applySecond;
function liftA2(F) {
    return function (f) { return function (fa) { return function (fb) { return F.ap(F.map(fa, f), fb); }; }; };
}
exports.liftA2 = liftA2;
function liftA3(F) {
    return function (f) { return function (fa) { return function (fb) { return function (fc) { return F.ap(F.ap(F.map(fa, f), fb), fc); }; }; }; };
}
exports.liftA3 = liftA3;
function liftA4(F) {
    return function (f) { return function (fa) { return function (fb) { return function (fc) { return function (fd) { return F.ap(F.ap(F.ap(F.map(fa, f), fb), fc), fd); }; }; }; }; };
}
exports.liftA4 = liftA4;
function getSemigroup(F, S) {
    var concatLifted = liftA2(F)(function (a) { return function (b) { return S.concat(a, b); }; });
    return function () { return ({
        concat: function (x, y) { return concatLifted(x)(y); }
    }); };
}
exports.getSemigroup = getSemigroup;
var tupleConstructors = {};
function sequenceT(F) {
    return function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        var len = args.length;
        var f = tupleConstructors[len];
        if (!Boolean(f)) {
            f = tupleConstructors[len] = function_1.curried(function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                return args;
            }, len - 1, []);
        }
        var r = F.map(args[0], f);
        for (var i = 1; i < len; i++) {
            r = F.ap(r, args[i]);
        }
        return r;
    };
}
exports.sequenceT = sequenceT;
