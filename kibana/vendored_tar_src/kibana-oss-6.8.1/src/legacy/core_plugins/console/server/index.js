'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _proxy_config_collection = require('./proxy_config_collection');

Object.defineProperty(exports, 'ProxyConfigCollection', {
  enumerable: true,
  get: function () {
    return _proxy_config_collection.ProxyConfigCollection;
  }
});

var _elasticsearch_proxy_config = require('./elasticsearch_proxy_config');

Object.defineProperty(exports, 'getElasticsearchProxyConfig', {
  enumerable: true,
  get: function () {
    return _elasticsearch_proxy_config.getElasticsearchProxyConfig;
  }
});

var _proxy_route = require('./proxy_route');

Object.defineProperty(exports, 'createProxyRoute', {
  enumerable: true,
  get: function () {
    return _proxy_route.createProxyRoute;
  }
});