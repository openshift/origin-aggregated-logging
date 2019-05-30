/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Svg = undefined;

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

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var unDefault = function unDefault(obj) {
  return obj && obj.__esModule ? obj.default : obj;
};

var Svg = exports.Svg = function (_React$PureComponent) {
  (0, _inherits3.default)(Svg, _React$PureComponent);

  function Svg(props, context) {
    (0, _classCallCheck3.default)(this, Svg);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this.state = { Component: null };
    return _this;
  }

  Svg.prototype.setComponent = function setComponent(_ref) {
    var src = _ref.src;

    this.setState({ Component: unDefault(this.svgPathLoader(src)) });
  };

  Svg.prototype.componentDidMount = function componentDidMount() {
    this.setComponent(this.props);
  };

  Svg.prototype.componentWillReceiveProps = function componentWillReceiveProps(props) {
    this.setComponent(props);
  };

  Svg.prototype.svgPathLoader = function svgPathLoader(src) {
    try {
      return __non_webpack_require__('!!babel-loader?{"presets":["react"]}!react-svg-loader?{"svgo":{"plugins":[{"removeUnknownsAndDefaults":false},{"cleanupNumericValues":false},{"removeUselessStrokeAndFill":false}]}}!../../../../app/svgs/' + src + '.svg');
    } catch (e) {}
  };

  Svg.prototype.render = function render() {
    var _props = this.props,
        src = _props.src,
        props = (0, _objectWithoutProperties3.default)(_props, ['src']);
    var Component = this.state.Component;

    if (Component) return _react2.default.createElement(Component, props);
    return _react2.default.createElement('svg', props);
  };

  return Svg;
}(_react2.default.PureComponent);

Svg.propTypes = {
  src: _propTypes2.default.string.isRequired
};