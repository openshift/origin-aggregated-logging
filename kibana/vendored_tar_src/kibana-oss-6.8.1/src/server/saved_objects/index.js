'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _saved_objects_mixin = require('./saved_objects_mixin');

Object.defineProperty(exports, 'savedObjectsMixin', {
  enumerable: true,
  get: function () {
    return _saved_objects_mixin.savedObjectsMixin;
  }
});

var _service = require('./service');

Object.defineProperty(exports, 'SavedObjectsClient', {
  enumerable: true,
  get: function () {
    return _service.SavedObjectsClient;
  }
});