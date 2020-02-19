'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.errors = exports.SavedObjectsRepositoryProvider = exports.ScopedSavedObjectsClientProvider = exports.SavedObjectsRepository = undefined;

var _repository = require('./repository');

Object.defineProperty(exports, 'SavedObjectsRepository', {
  enumerable: true,
  get: function () {
    return _repository.SavedObjectsRepository;
  }
});

var _scoped_client_provider = require('./scoped_client_provider');

Object.defineProperty(exports, 'ScopedSavedObjectsClientProvider', {
  enumerable: true,
  get: function () {
    return _scoped_client_provider.ScopedSavedObjectsClientProvider;
  }
});

var _repository_provider = require('./repository_provider');

Object.defineProperty(exports, 'SavedObjectsRepositoryProvider', {
  enumerable: true,
  get: function () {
    return _repository_provider.SavedObjectsRepositoryProvider;
  }
});

var _errors = require('./errors');

var errors = _interopRequireWildcard(_errors);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

exports.errors = errors;