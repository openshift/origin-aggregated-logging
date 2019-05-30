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
var Applicative_1 = require("./Applicative");
var Option_1 = require("./Option");
function chain(F) {
    return function (f, fa) { return F.chain(fa, function (o) { return (o.isNone() ? F.of(Option_1.none) : f(o.value)); }); };
}
exports.chain = chain;
function some(F) {
    return function (a) { return F.of(Option_1.some(a)); };
}
exports.some = some;
function none(F) {
    return function () { return F.of(Option_1.none); };
}
exports.none = none;
function fromOption(F) {
    return function (oa) { return F.of(oa); };
}
exports.fromOption = fromOption;
function liftF(F) {
    return function (fa) { return F.map(fa, function (a) { return Option_1.some(a); }); };
}
exports.liftF = liftF;
function fold(F) {
    return function (r, some, fa) { return F.map(fa, function (o) { return (o.isNone() ? r : some(o.value)); }); };
}
exports.fold = fold;
function getOrElse(F) {
    return function (a) { return function (fa) { return F.map(fa, function (o) { return o.getOrElse(a); }); }; };
}
exports.getOrElse = getOrElse;
function getOptionT(M) {
    var applicativeComposition = Applicative_1.getApplicativeComposition(M, Option_1.option);
    return __assign({}, applicativeComposition, { chain: chain(M) });
}
exports.getOptionT = getOptionT;
