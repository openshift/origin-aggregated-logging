(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global.vegaSpecInjector = factory());
}(this, (function () { 'use strict';

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var _class = function () {
  function _class(onWarning) {
    _classCallCheck(this, _class);

    this.onWarning = onWarning || (console ? console.log : function () {});
  }

  /**
   * Add values like signals to a vega spec, or ignore if the they are already defined.
   * @param {object} spec vega spec to modify and return
   * @param {string} field name of the vega spec branch, e.g. `signals`
   * @param {<object|string>[]} values to add
   * @return {object} returns the same spec object as passed in
   */


  _class.prototype.addToList = function addToList(spec, field, values) {
    var newSigs = new Map(values.map(function (v) {
      return typeof v === "string" ? [v, { name: v }] : [v.name, v];
    }));

    for (var _iterator = this.findUndefined(spec, field, newSigs.keys()), _isArray = Array.isArray(_iterator), _i = 0, _iterator = _isArray ? _iterator : _iterator[Symbol.iterator]();;) {
      var _ref;

      if (_isArray) {
        if (_i >= _iterator.length) break;
        _ref = _iterator[_i++];
      } else {
        _i = _iterator.next();
        if (_i.done) break;
        _ref = _i.value;
      }

      var sig = _ref;

      spec[field].push(newSigs.get(sig));
    }

    return spec;
  };

  /**
   * Set a spec field, and warn if overriding an existing value in that field
   * @param {object} spec vega spec to modify and return
   * @param {string} field
   * @param {*} value
   * @return {object} returns the same spec object as passed in
   */


  _class.prototype.overrideField = function overrideField(spec, field, value) {
    if (spec[field] && spec[field] !== value) {
      this.onWarning("Overriding " + field + ": " + spec[field] + " \uD800\uDCD8 " + value);
    }
    spec[field] = value;
    return spec;
  };

  /**
   * Find all names that are not defined in the spec's section. Creates section if missing.
   * @param {object} spec
   * @param {string} section
   * @param {Iterable.<string>} names
   * @return {Iterable.<string>}
   */


  _class.prototype.findUndefined = function findUndefined(spec, section, names) {
    if (!spec.hasOwnProperty(section)) {
      spec[section] = [];
      return names;
    } else if (!Array.isArray(spec[section])) {
      throw new Error("spec." + section + " must be an array");
    }

    var nameStrings = new Set(names);
    for (var _iterator2 = spec[section], _isArray2 = Array.isArray(_iterator2), _i2 = 0, _iterator2 = _isArray2 ? _iterator2 : _iterator2[Symbol.iterator]();;) {
      var _ref2;

      if (_isArray2) {
        if (_i2 >= _iterator2.length) break;
        _ref2 = _iterator2[_i2++];
      } else {
        _i2 = _iterator2.next();
        if (_i2.done) break;
        _ref2 = _i2.value;
      }

      var obj = _ref2;

      // If obj has a name field, delete that name from the names
      // Set will silently ignore delete() for undefined names
      if (obj.name) nameStrings.delete(obj.name);
    }

    return nameStrings;
  };

  return _class;
}();

return _class;

})));
