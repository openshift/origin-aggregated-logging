/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
"use strict";

exports.__esModule = true;
var getScrollTop = function getScrollTop(_ref) {
  var scrollTop = _ref.scrollTop;
  return scrollTop;
};
var setScrollTop = function setScrollTop(value, element) {
  return element.scrollTop = value;
};
exports.default = { getScrollTop: getScrollTop, setScrollTop: setScrollTop };
module.exports = exports["default"];