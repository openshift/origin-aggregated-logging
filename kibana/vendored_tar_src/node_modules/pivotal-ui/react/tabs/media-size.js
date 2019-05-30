/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
"use strict";

exports.__esModule = true;
var matches = function matches(screenSizeString) {
  var screenSizes = {
    xs: 0,
    sm: 768,
    md: 992,
    lg: 1200,
    xl: 1800
  };

  var minWidth = screenSizes[screenSizeString];

  return window.matchMedia("(min-width: " + minWidth + "px)").matches;
};

exports.default = { matches: matches };
module.exports = exports["default"];