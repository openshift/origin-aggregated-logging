'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _prompt = require('./prompt');

Object.defineProperty(exports, 'confirm', {
  enumerable: true,
  get: function () {
    return _prompt.confirm;
  }
});
Object.defineProperty(exports, 'question', {
  enumerable: true,
  get: function () {
    return _prompt.question;
  }
});