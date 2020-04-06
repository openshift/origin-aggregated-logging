'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _flights = require('./flights');

Object.defineProperty(exports, 'flightsSpecProvider', {
  enumerable: true,
  get: function () {
    return _flights.flightsSpecProvider;
  }
});

var _logs = require('./logs');

Object.defineProperty(exports, 'logsSpecProvider', {
  enumerable: true,
  get: function () {
    return _logs.logsSpecProvider;
  }
});

var _ecommerce = require('./ecommerce');

Object.defineProperty(exports, 'ecommerceSpecProvider', {
  enumerable: true,
  get: function () {
    return _ecommerce.ecommerceSpecProvider;
  }
});