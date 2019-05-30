"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
function lift(F) {
    return function (f) { return function (fa) { return F.map(fa, f); }; };
}
exports.lift = lift;
function voidRight(F) {
    return function (a, fb) { return F.map(fb, function_1.constant(a)); };
}
exports.voidRight = voidRight;
function voidLeft(F) {
    return function (fa, b) { return F.map(fa, function_1.constant(b)); };
}
exports.voidLeft = voidLeft;
function flap(functor) {
    return function (a, ff) { return functor.map(ff, function (f) { return f(a); }); };
}
exports.flap = flap;
function getFunctorComposition(F, G) {
    return {
        map: function (fa, f) { return F.map(fa, function (ga) { return G.map(ga, f); }); }
    };
}
exports.getFunctorComposition = getFunctorComposition;
