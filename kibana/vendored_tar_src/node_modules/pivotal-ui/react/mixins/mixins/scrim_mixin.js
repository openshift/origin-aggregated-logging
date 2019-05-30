/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function rootClick(e) {
  var node = _reactDom2.default.findDOMNode(this);
  if (typeof node.contains !== 'function') {
    node.contains = HTMLDivElement.prototype.contains;
  }

  if (this.props.disableScrim || node.contains(e.target)) return;
  this.scrimClick(e);
}

var privates = new _weakMap2.default();

exports.default = function (ParentClass) {
  var _class, _temp;

  return _temp = _class = function (_ParentClass) {
    (0, _inherits3.default)(Scrim, _ParentClass);

    function Scrim(props, context) {
      (0, _classCallCheck3.default)(this, Scrim);

      var _this = (0, _possibleConstructorReturn3.default)(this, _ParentClass.call(this, props, context));

      privates.set(_this, rootClick.bind(_this));
      return _this;
    }

    Scrim.prototype.scrimClick = function scrimClick() {};

    Scrim.prototype.componentDidMount = function componentDidMount() {
      var _ParentClass$prototyp;

      for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      if (_ParentClass.prototype.componentDidMount) (_ParentClass$prototyp = _ParentClass.prototype.componentDidMount).call.apply(_ParentClass$prototyp, [this].concat(args));
      var document = this.props.getDocument ? this.props.getDocument() : global.document;
      if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) === 'object') document.documentElement.addEventListener('click', privates.get(this));
    };

    Scrim.prototype.componentWillUnmount = function componentWillUnmount() {
      var _ParentClass$prototyp2;

      for (var _len2 = arguments.length, args = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
        args[_key2] = arguments[_key2];
      }

      if (_ParentClass.prototype.componentWillUnmount) (_ParentClass$prototyp2 = _ParentClass.prototype.componentWillUnmount).call.apply(_ParentClass$prototyp2, [this].concat(args));
      var document = this.props.getDocument ? this.props.getDocument() : global.document;
      if ((typeof document === 'undefined' ? 'undefined' : (0, _typeof3.default)(document)) === 'object') document.documentElement.removeEventListener('click', privates.get(this));
    };

    return Scrim;
  }(ParentClass), _class.propTypes = {
    disableScrim: _propTypes2.default.bool
  }, _temp;
};

module.exports = exports['default'];