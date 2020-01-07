/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
"use strict";

exports.__esModule = true;

exports.default = function (collection, startIndex, endIndex) {
  while (startIndex < 0) {
    startIndex += collection.length;
  }
  while (endIndex < 0) {
    endIndex += collection.length;
  }
  if (endIndex >= collection.length) {
    var k = endIndex - collection.length;
    while (k-- + 1) {
      collection.push(undefined);
    }
  }
  collection.splice(endIndex, 0, collection.splice(startIndex, 1)[0]);

  return collection;
};

module.exports = exports["default"];