'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _bulk_create = require('./bulk_create');

Object.defineProperty(exports, 'createBulkCreateRoute', {
  enumerable: true,
  get: function () {
    return _bulk_create.createBulkCreateRoute;
  }
});

var _bulk_get = require('./bulk_get');

Object.defineProperty(exports, 'createBulkGetRoute', {
  enumerable: true,
  get: function () {
    return _bulk_get.createBulkGetRoute;
  }
});

var _create = require('./create');

Object.defineProperty(exports, 'createCreateRoute', {
  enumerable: true,
  get: function () {
    return _create.createCreateRoute;
  }
});

var _delete = require('./delete');

Object.defineProperty(exports, 'createDeleteRoute', {
  enumerable: true,
  get: function () {
    return _delete.createDeleteRoute;
  }
});

var _find = require('./find');

Object.defineProperty(exports, 'createFindRoute', {
  enumerable: true,
  get: function () {
    return _find.createFindRoute;
  }
});

var _get = require('./get');

Object.defineProperty(exports, 'createGetRoute', {
  enumerable: true,
  get: function () {
    return _get.createGetRoute;
  }
});

var _update = require('./update');

Object.defineProperty(exports, 'createUpdateRoute', {
  enumerable: true,
  get: function () {
    return _update.createUpdateRoute;
  }
});