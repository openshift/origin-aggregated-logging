"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
/**
 * @function
 * @since 1.0.0
 */
exports.toArray = function (O) { return function (x) {
    var r = [];
    x.forEach(function (e) { return r.push(e); });
    return r.sort(O.compare);
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.getSetoid = function (S) {
    var subsetS = exports.subset(S);
    return {
        equals: function (x, y) { return subsetS(x, y) && subsetS(y, x); }
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.some = function (x, predicate) {
    var values = x.values();
    var e;
    var found = false;
    // tslint:disable:no-conditional-assignment
    while (!found && !(e = values.next()).done) {
        found = predicate(e.value);
    }
    return found;
};
/**
 * Projects a Set through a function
 * @function
 * @since 1.2.0
 */
exports.map = function (bset) { return function (x, f) {
    var r = new Set();
    var ismember = exports.member(bset)(r);
    x.forEach(function (e) {
        var v = f(e);
        if (!ismember(v)) {
            r.add(v);
        }
    });
    return r;
}; };
/**
 * @function
 * @since 1.0.0
 */
exports.every = function (x, predicate) {
    return !exports.some(x, function_1.not(predicate));
};
/**
 * @function
 * @since 1.2.0
 */
exports.chain = function (bset) { return function (x, f) {
    var r = new Set();
    var rhas = exports.member(bset)(r);
    x.forEach(function (e) {
        f(e).forEach(function (e) {
            if (!rhas(e)) {
                r.add(e);
            }
        });
    });
    return r;
}; };
/**
 * `true` if and only if every element in the first set is an element of the second set
 * @function
 * @since 1.0.0
 */
exports.subset = function (S) { return function (x, y) {
    return exports.every(x, exports.member(S)(y));
}; };
function filter(x, predicate) {
    var values = x.values();
    var e;
    var r = new Set();
    // tslint:disable:no-conditional-assignment
    while (!(e = values.next()).done) {
        var value = e.value;
        if (predicate(value)) {
            r.add(value);
        }
    }
    return r;
}
exports.filter = filter;
function partition(x, predicate) {
    var values = x.values();
    var e;
    var right = new Set();
    var left = new Set();
    // tslint:disable:no-conditional-assignment
    while (!(e = values.next()).done) {
        var value = e.value;
        if (predicate(value)) {
            right.add(value);
        }
        else {
            left.add(value);
        }
    }
    return { left: left, right: right };
}
exports.partition = partition;
/**
 * Test if a value is a member of a set
 * @function
 * @since 1.0.0
 */
exports.member = function (S) { return function (x) { return function (a) {
    return exports.some(x, function (ax) { return S.equals(a, ax); });
}; }; };
/**
 * Form the union of two sets
 * @function
 * @since 1.0.0
 */
exports.union = function (S) {
    var memberS = exports.member(S);
    return function (x, y) {
        var xhas = memberS(x);
        var r = new Set(x);
        y.forEach(function (e) {
            if (!xhas(e)) {
                r.add(e);
            }
        });
        return r;
    };
};
/**
 * The set of elements which are in both the first and second set
 * @function
 * @since 1.0.0
 */
exports.intersection = function (S) {
    var memberS = exports.member(S);
    return function (x, y) {
        var yhas = memberS(y);
        var r = new Set();
        x.forEach(function (e) {
            if (yhas(e)) {
                r.add(e);
            }
        });
        return r;
    };
};
/**
 * @function
 * @since 1.2.0
 */
exports.partitionMap = function (SL, SR) { return function (x, f) {
    var values = x.values();
    var e;
    var left = new Set();
    var right = new Set();
    var isMemberL = exports.member(SL)(left);
    var isMemberR = exports.member(SR)(right);
    // tslint:disable:no-conditional-assignment
    while (!(e = values.next()).done) {
        var v = f(e.value);
        if (v.isLeft()) {
            if (!isMemberL(v.value)) {
                left.add(v.value);
            }
        }
        else {
            if (!isMemberR(v.value)) {
                right.add(v.value);
            }
        }
    }
    return { left: left, right: right };
}; };
/**
 * Use {@link difference2v} instead
 * @function
 * @since 1.0.0
 * @deprecated
 */
exports.difference = function (S) {
    var d = exports.difference2v(S);
    return function (x, y) { return d(y, x); };
};
/**
 * Form the set difference (`x` - `y`)
 *
 * @example
 * import { difference2v } from 'fp-ts/lib/Set'
 * import { setoidNumber } from 'fp-ts/lib/Setoid'
 *
 * assert.deepEqual(difference2v(setoidNumber)(new Set([1, 2]), new Set([1, 3])), new Set([2]))
 *
 * @function
 * @since 1.12.0
 */
exports.difference2v = function (S) {
    var has = exports.member(S);
    return function (x, y) { return filter(x, function_1.not(has(y))); };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getUnionMonoid = function (S) {
    return {
        concat: exports.union(S),
        empty: new Set()
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.getIntersectionSemigroup = function (S) {
    return {
        concat: exports.intersection(S)
    };
};
/**
 * @function
 * @since 1.0.0
 */
exports.reduce = function (O) {
    var toArrayO = exports.toArray(O);
    return function (fa, b, f) { return toArrayO(fa).reduce(f, b); };
};
/**
 * Create a set with one element
 * @function
 * @since 1.0.0
 */
exports.singleton = function (a) {
    return new Set([a]);
};
/**
 * Insert a value into a set
 * @function
 * @since 1.0.0
 */
exports.insert = function (S) {
    var memberS = exports.member(S);
    return function (a, x) {
        if (!memberS(x)(a)) {
            var r = new Set(x);
            r.add(a);
            return r;
        }
        else {
            return x;
        }
    };
};
/**
 * Delete a value from a set
 * @function
 * @since 1.0.0
 */
exports.remove = function (S) { return function (a, x) {
    return filter(x, function (ax) { return !S.equals(a, ax); });
}; };
/**
 * Create a set from an array
 * @function
 * @since 1.2.0
 */
exports.fromArray = function (S) { return function (as) {
    var len = as.length;
    var r = new Set();
    var isMember = exports.member(S)(r);
    for (var i = 0; i < len; i++) {
        var a = as[i];
        if (!isMember(a)) {
            r.add(a);
        }
    }
    return r;
}; };
/**
 * @function
 * @since 1.12.0
 */
exports.compact = function (S) {
    var filterMapS = exports.filterMap(S);
    return function (fa) { return filterMapS(fa, function_1.identity); };
};
/**
 * @function
 * @since 1.12.0
 */
exports.separate = function (SL, SR) { return function (fa) {
    var memberSL = exports.member(SL);
    var memberSR = exports.member(SR);
    var left = new Set();
    var right = new Set();
    var isMemberL = memberSL(left);
    var isMemberR = memberSR(right);
    fa.forEach(function (e) {
        if (e.isLeft()) {
            if (!isMemberL(e.value)) {
                left.add(e.value);
            }
        }
        else {
            if (!isMemberR(e.value)) {
                right.add(e.value);
            }
        }
    });
    return { left: left, right: right };
}; };
/**
 * @function
 * @since 1.12.0
 */
exports.filterMap = function (S) {
    var memberS = exports.member(S);
    return function (fa, f) {
        var r = new Set();
        var isMember = memberS(r);
        fa.forEach(function (a) {
            var ob = f(a);
            if (ob.isSome() && !isMember(ob.value)) {
                r.add(ob.value);
            }
        });
        return r;
    };
};
