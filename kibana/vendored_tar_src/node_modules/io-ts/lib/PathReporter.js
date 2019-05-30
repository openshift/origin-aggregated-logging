"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var index_1 = require("./index");
function stringify(v) {
    return typeof v === 'function' ? index_1.getFunctionName(v) : JSON.stringify(v);
}
function getContextPath(context) {
    return context.map(function (_a) {
        var key = _a.key, type = _a.type;
        return key + ": " + type.name;
    }).join('/');
}
function getMessage(v, context) {
    return "Invalid value " + stringify(v) + " supplied to " + getContextPath(context);
}
function failure(es) {
    return es.map(function (e) { return getMessage(e.value, e.context); });
}
exports.failure = failure;
function success() {
    return ['No errors!'];
}
exports.success = success;
exports.PathReporter = {
    report: function (validation) { return validation.fold(failure, success); }
};
