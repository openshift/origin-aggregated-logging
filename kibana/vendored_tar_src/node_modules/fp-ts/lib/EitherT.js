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
var Either_1 = require("./Either");
function chain(F) {
    return function (f, fa) { return F.chain(fa, function (e) { return (e.isLeft() ? F.of(Either_1.left(e.value)) : f(e.value)); }); };
}
exports.chain = chain;
function right(F) {
    return function (ma) { return F.map(ma, function (a) { return Either_1.right(a); }); };
}
exports.right = right;
function left(F) {
    return function (ml) { return F.map(ml, function (l) { return Either_1.left(l); }); };
}
exports.left = left;
function fromEither(F) {
    return function (oa) { return F.of(oa); };
}
exports.fromEither = fromEither;
function fold(F) {
    return function (left, right, fa) { return F.map(fa, function (e) { return (e.isLeft() ? left(e.value) : right(e.value)); }); };
}
exports.fold = fold;
function mapLeft(F) {
    return function (f) { return function (fa) { return F.map(fa, function (e) { return e.mapLeft(f); }); }; };
}
exports.mapLeft = mapLeft;
function bimap(F) {
    return function (fa, f, g) { return F.map(fa, function (e) { return e.bimap(f, g); }); };
}
exports.bimap = bimap;
function getEitherT(M) {
    var applicativeComposition = Applicative_1.getApplicativeComposition(M, Either_1.either);
    return __assign({}, applicativeComposition, { chain: chain(M) });
}
exports.getEitherT = getEitherT;
