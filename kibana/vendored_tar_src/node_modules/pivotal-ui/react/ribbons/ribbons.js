/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Banner = exports.PrimaryRibbon = exports.Ribbon = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Ribbon = exports.Ribbon = function (_React$PureComponent) {
  (0, _inherits3.default)(Ribbon, _React$PureComponent);

  function Ribbon() {
    (0, _classCallCheck3.default)(this, Ribbon);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Ribbon.prototype.componentDidMount = function componentDidMount() {
    require('../../css/ribbons');
  };

  Ribbon.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        others = (0, _objectWithoutProperties3.default)(_props, ['children']);

    var props = (0, _helpers.mergeProps)(others, { className: 'ribbon' });
    return _react2.default.createElement(
      'div',
      props,
      children
    );
  };

  return Ribbon;
}(_react2.default.PureComponent);

var PrimaryRibbon = exports.PrimaryRibbon = function (_React$PureComponent2) {
  (0, _inherits3.default)(PrimaryRibbon, _React$PureComponent2);

  function PrimaryRibbon() {
    (0, _classCallCheck3.default)(this, PrimaryRibbon);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
  }

  PrimaryRibbon.prototype.componentDidMount = function componentDidMount() {
    require('../../css/ribbons');
  };

  PrimaryRibbon.prototype.render = function render() {
    var _props2 = this.props,
        children = _props2.children,
        others = (0, _objectWithoutProperties3.default)(_props2, ['children']);

    var props = (0, _helpers.mergeProps)(others, { className: ['ribbon', 'ribbon-primary'] });
    return _react2.default.createElement(
      'div',
      props,
      children
    );
  };

  return PrimaryRibbon;
}(_react2.default.PureComponent);

var Banner = exports.Banner = function (_React$PureComponent3) {
  (0, _inherits3.default)(Banner, _React$PureComponent3);

  function Banner() {
    (0, _classCallCheck3.default)(this, Banner);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent3.apply(this, arguments));
  }

  Banner.prototype.componentDidMount = function componentDidMount() {
    require('../../css/ribbons');
  };

  Banner.prototype.render = function render() {
    var _props3 = this.props,
        children = _props3.children,
        others = (0, _objectWithoutProperties3.default)(_props3, ['children']);

    var props = (0, _helpers.mergeProps)(others, { className: 'ribbon-banner' });
    return _react2.default.createElement(
      'div',
      props,
      children
    );
  };

  return Banner;
}(_react2.default.PureComponent);