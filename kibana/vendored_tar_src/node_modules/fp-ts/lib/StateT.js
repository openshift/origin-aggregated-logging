"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
function map(F) {
    return function (f, fa) { return function (s) { return F.map(fa(s), function (_a) {
        var a = _a[0], s1 = _a[1];
        return function_1.tuple(f(a), s1);
    }); }; };
}
exports.map = map;
function of(F) {
    return function (a) { return function (s) { return F.of(function_1.tuple(a, s)); }; };
}
exports.of = of;
function ap(F) {
    var mapF = map(F);
    var chainF = chain(F);
    return function (fab, fa) { return chainF(function (f) { return mapF(f, fa); }, fab); }; // <- derived
}
exports.ap = ap;
function chain(F) {
    return function (f, fa) { return function (s) { return F.chain(fa(s), function (_a) {
        var a = _a[0], s1 = _a[1];
        return f(a)(s1);
    }); }; };
}
exports.chain = chain;
function get(F) {
    return function () { return function (s) { return F.of(function_1.tuple(s, s)); }; };
}
exports.get = get;
function put(F) {
    return function (s) { return function () { return F.of(function_1.tuple(undefined, s)); }; };
}
exports.put = put;
function modify(F) {
    return function (f) { return function (s) { return F.of(function_1.tuple(undefined, f(s))); }; };
}
exports.modify = modify;
function gets(F) {
    return function (f) { return function (s) { return F.of(function_1.tuple(f(s), s)); }; };
}
exports.gets = gets;
function fromState(F) {
    return function (fa) { return function (s) { return F.of(fa.run(s)); }; };
}
exports.fromState = fromState;
function liftF(F) {
    return function (fa) { return function (s) { return F.map(fa, function (a) { return function_1.tuple(a, s); }); }; };
}
exports.liftF = liftF;
function getStateT(M) {
    return {
        map: map(M),
        of: of(M),
        ap: ap(M),
        chain: chain(M)
    };
}
exports.getStateT = getStateT;
