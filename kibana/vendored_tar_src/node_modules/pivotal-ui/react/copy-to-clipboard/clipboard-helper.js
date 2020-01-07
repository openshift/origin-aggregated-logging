/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
var select = function select(window, document, element) {
  window.getSelection().removeAllRanges();
  var range = document.createRange();
  range.selectNode(element);
  window.getSelection().addRange(range);
};

var copy = function copy(window, document, element) {
  select(window, document, element);
  try {
    document.execCommand('copy');
  } catch (e) {} finally {
    window.getSelection().removeAllRanges();
  }
};

exports.default = { select: select, copy: copy };
module.exports = exports['default'];