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
var Monoid_1 = require("./Monoid");
var Option_1 = require("./Option");
/**
 * Calculate the number of key/value pairs in a dictionary
 * @function
 * @since 1.10.0
 */
exports.size = function (d) {
    return Object.keys(d).length;
};
/**
 * Test whether a dictionary is empty
 * @function
 * @since 1.10.0
 */
exports.isEmpty = function (d) {
    return Object.keys(d).length === 0;
};
/**
 * @function
 * @since 1.10.0
 */
exports.collect = function (d, f) {
    var out = [];
    var keys = Object.keys(d).sort();
    for (var _i = 0, keys_1 = keys; _i < keys_1.length; _i++) {
        var key = keys_1[_i];
        out.push(f(key, d[key]));
    }
    return out;
};
/**
 * @function
 * @since 1.10.0
 */
exports.toArray = function (d) {
    return exports.collect(d, function (k, a) { return function_1.tuple(k, a); });
};
/**
 * Unfolds a dictionary into a list of key/value pairs
 * @function
 * @since 1.10.0
 */
exports.toUnfoldable = function (unfoldable) { return function (d) {
    var arr = exports.toArray(d);
    var len = arr.length;
    return unfoldable.unfoldr(0, function (b) { return (b < len ? Option_1.some(function_1.tuple(arr[b], b + 1)) : Option_1.none); });
}; };
/**
 * Insert or replace a key/value pair in a map
 * @function
 * @since 1.10.0
 */
exports.insert = function (k, a, d) {
    var r = Object.assign({}, d);
    r[k] = a;
    return r;
};
/**
 * Delete a key and value from a map
 * @function
 * @since 1.10.0
 */
exports.remove = function (k, d) {
    var r = Object.assign({}, d);
    delete r[k];
    return r;
};
/**
 * Delete a key and value from a map, returning the value as well as the subsequent map
 * @function
 * @since 1.10.0
 */
exports.pop = function (k, d) {
    var a = exports.lookup(k, d);
    return a.isNone() ? Option_1.none : Option_1.some(function_1.tuple(a.value, exports.remove(k, d)));
};
/**
 * Test whether one dictionary contains all of the keys and values contained in another dictionary
 * @function
 * @since 1.10.0
 */
exports.isSubdictionary = function (S) { return function (d1, d2) {
    for (var k in d1) {
        if (!d2.hasOwnProperty(k) || !S.equals(d1[k], d2[k])) {
            return false;
        }
    }
    return true;
}; };
/**
 * @function
 * @since 1.10.0
 */
exports.getSetoid = function (S) {
    var isSubdictionaryS = exports.isSubdictionary(S);
    return {
        equals: function (x, y) { return isSubdictionaryS(x, y) && isSubdictionaryS(y, x); }
    };
};
/**
 * @function
 * @since 1.10.0
 */
exports.getMonoid = Monoid_1.getDictionaryMonoid;
/**
 * Lookup the value for a key in a dictionary
 * @since 1.10.0
 */
exports.lookup = function (key, fa) {
    return fa.hasOwnProperty(key) ? Option_1.some(fa[key]) : Option_1.none;
};
function filter(fa, p) {
    return exports.filterWithIndex(fa, function (_, a) { return p(a); });
}
exports.filter = filter;
function fromFoldable(F) {
    return function (ta, f) {
        return F.reduce(ta, {}, function (b, _a) {
            var k = _a[0], a = _a[1];
            b[k] = b.hasOwnProperty(k) ? f(b[k], a) : a;
            return b;
        });
    };
}
exports.fromFoldable = fromFoldable;
/**
 * @constant
 * @since 1.10.0
 */
exports.empty = {};
/**
 * @function
 * @since 1.10.0
 */
exports.mapWithKey = function (fa, f) {
    var r = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_2 = keys; _i < keys_2.length; _i++) {
        var key = keys_2[_i];
        r[key] = f(key, fa[key]);
    }
    return r;
};
/**
 * @function
 * @since 1.10.0
 */
exports.map = function (fa, f) {
    return exports.mapWithKey(fa, function (_, a) { return f(a); });
};
/**
 * @function
 * @since 1.10.0
 */
exports.reduce = function (fa, b, f) {
    return exports.reduceWithKey(fa, b, function (_, b, a) { return f(b, a); });
};
/**
 * @function
 * @since 1.10.0
 */
exports.foldMap = function (M) {
    var foldMapWithKeyM = exports.foldMapWithKey(M);
    return function (fa, f) { return foldMapWithKeyM(fa, function (_, a) { return f(a); }); };
};
/**
 * @function
 * @since 1.10.0
 */
exports.foldr = function (fa, b, f) {
    return exports.foldrWithKey(fa, b, function (_, a, b) { return f(a, b); });
};
/**
 * @function
 * @since 1.12.0
 */
exports.reduceWithKey = function (fa, b, f) {
    var out = b;
    var keys = Object.keys(fa).sort();
    var len = keys.length;
    for (var i = 0; i < len; i++) {
        var k = keys[i];
        out = f(k, out, fa[k]);
    }
    return out;
};
/**
 * @function
 * @since 1.12.0
 */
exports.foldMapWithKey = function (M) { return function (fa, f) {
    var out = M.empty;
    var keys = Object.keys(fa).sort();
    var len = keys.length;
    for (var i = 0; i < len; i++) {
        var k = keys[i];
        out = M.concat(out, f(k, fa[k]));
    }
    return out;
}; };
/**
 * @function
 * @since 1.12.0
 */
exports.foldrWithKey = function (fa, b, f) {
    var out = b;
    var keys = Object.keys(fa).sort();
    var len = keys.length;
    for (var i = len - 1; i >= 0; i--) {
        var k = keys[i];
        out = f(k, fa[k], out);
    }
    return out;
};
/**
 * Create a dictionary with one key/value pair
 * @function
 * @since 1.10.0
 */
exports.singleton = function (k, a) {
    var _a;
    return _a = {}, _a[k] = a, _a;
};
function traverseWithKey(F) {
    return function (ta, f) {
        var fr = F.of(exports.empty);
        var keys = Object.keys(ta);
        var _loop_1 = function (key) {
            fr = F.ap(F.map(fr, function (r) { return function (b) {
                var _a;
                return (__assign({}, r, (_a = {}, _a[key] = b, _a)));
            }; }), f(key, ta[key]));
        };
        for (var _i = 0, keys_3 = keys; _i < keys_3.length; _i++) {
            var key = keys_3[_i];
            _loop_1(key);
        }
        return fr;
    };
}
exports.traverseWithKey = traverseWithKey;
function traverse(F) {
    var traverseWithKeyF = traverseWithKey(F);
    return function (ta, f) { return traverseWithKeyF(ta, function (_, a) { return f(a); }); };
}
exports.traverse = traverse;
function sequence(F) {
    var traverseWithKeyF = traverseWithKey(F);
    return function (ta) { return traverseWithKeyF(ta, function (_, a) { return a; }); };
}
exports.sequence = sequence;
/**
 * @function
 * @since 1.10.0
 */
exports.compact = function (fa) {
    var r = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_4 = keys; _i < keys_4.length; _i++) {
        var key = keys_4[_i];
        var optionA = fa[key];
        if (optionA.isSome()) {
            r[key] = optionA.value;
        }
    }
    return r;
};
/**
 * @function
 * @since 1.10.0
 */
exports.partitionMap = function (fa, f) {
    return exports.partitionMapWithIndex(fa, function (_, a) { return f(a); });
};
/**
 * @function
 * @since 1.10.0
 */
exports.partition = function (fa, p) {
    return exports.partitionWithIndex(fa, function (_, a) { return p(a); });
};
/**
 * @function
 * @since 1.10.0
 */
exports.separate = function (fa) {
    var left = {};
    var right = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_5 = keys; _i < keys_5.length; _i++) {
        var key = keys_5[_i];
        var e = fa[key];
        if (e.isLeft()) {
            left[key] = e.value;
        }
        else {
            right[key] = e.value;
        }
    }
    return {
        left: left,
        right: right
    };
};
function wither(F) {
    var traverseF = traverse(F);
    return function (wa, f) { return F.map(traverseF(wa, f), exports.compact); };
}
exports.wither = wither;
function wilt(F) {
    var traverseF = traverse(F);
    return function (wa, f) { return F.map(traverseF(wa, f), exports.separate); };
}
exports.wilt = wilt;
/**
 * @function
 * @since 1.10.0
 */
exports.filterMap = function (fa, f) {
    return exports.filterMapWithIndex(fa, function (_, a) { return f(a); });
};
/**
 * @function
 * @since 1.12.0
 */
exports.partitionMapWithIndex = function (fa, f) {
    var left = {};
    var right = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_6 = keys; _i < keys_6.length; _i++) {
        var key = keys_6[_i];
        var e = f(key, fa[key]);
        if (e.isLeft()) {
            left[key] = e.value;
        }
        else {
            right[key] = e.value;
        }
    }
    return {
        left: left,
        right: right
    };
};
/**
 * @function
 * @since 1.12.0
 */
exports.partitionWithIndex = function (fa, p) {
    var left = {};
    var right = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_7 = keys; _i < keys_7.length; _i++) {
        var key = keys_7[_i];
        var a = fa[key];
        if (p(key, a)) {
            right[key] = a;
        }
        else {
            left[key] = a;
        }
    }
    return {
        left: left,
        right: right
    };
};
/**
 * @function
 * @since 1.12.0
 */
exports.filterMapWithIndex = function (fa, f) {
    var r = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_8 = keys; _i < keys_8.length; _i++) {
        var key = keys_8[_i];
        var optionB = f(key, fa[key]);
        if (optionB.isSome()) {
            r[key] = optionB.value;
        }
    }
    return r;
};
/**
 * @function
 * @since 1.12.0
 */
exports.filterWithIndex = function (fa, p) {
    var r = {};
    var keys = Object.keys(fa);
    for (var _i = 0, keys_9 = keys; _i < keys_9.length; _i++) {
        var key = keys_9[_i];
        var a = fa[key];
        if (p(key, a)) {
            r[key] = a;
        }
    }
    return r;
};
