//(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.
'use strict';

exports.__esModule = true;

var _injector = require('./injector');

var _injector2 = _interopRequireDefault(_injector);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var animate = (0, _injector2.default)();

exports.default = {
  componentWillUnmount: animate.reset,
  animate: animate,
  shouldAnimate: function shouldAnimate() {
    return true;
  }
};
module.exports = exports['default'];