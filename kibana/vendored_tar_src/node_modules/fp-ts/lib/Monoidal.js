"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Apply_1 = require("./Apply");
var function_1 = require("./function");
function fromApplicative(applicative) {
    return {
        URI: applicative.URI,
        map: applicative.map,
        unit: function () { return applicative.of(undefined); },
        mult: function (fa, fb) { return Apply_1.liftA2(applicative)(function_1.tupleCurried)(fa)(fb); }
    };
}
exports.fromApplicative = fromApplicative;
function toApplicative(monoidal) {
    return {
        URI: monoidal.URI,
        map: monoidal.map,
        of: function (a) { return monoidal.map(monoidal.unit(), function_1.constant(a)); },
        ap: function (fab, fa) { return monoidal.map(monoidal.mult(fab, fa), function (_a) {
            var f = _a[0], a = _a[1];
            return f(a);
        }); }
    };
}
exports.toApplicative = toApplicative;
