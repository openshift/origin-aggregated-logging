'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Deprecations = exports.getTransform = exports.createTransform = undefined;

var _create_transform = require('./create_transform');

Object.defineProperty(exports, 'createTransform', {
  enumerable: true,
  get: function () {
    return _create_transform.createTransform;
  }
});

var _get_transform = require('./get_transform');

Object.defineProperty(exports, 'getTransform', {
  enumerable: true,
  get: function () {
    return _get_transform.getTransform;
  }
});

var _deprecations = require('./deprecations');

const Deprecations = exports.Deprecations = { rename: _deprecations.rename, unused: _deprecations.unused };