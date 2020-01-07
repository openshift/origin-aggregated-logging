/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Image = undefined;

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

var _helpers = require('../helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Image = exports.Image = function (_React$PureComponent) {
  (0, _inherits3.default)(Image, _React$PureComponent);

  function Image() {
    (0, _classCallCheck3.default)(this, Image);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  Image.prototype.componentDidMount = function componentDidMount() {
    require('../../css/images');
  };

  Image.prototype.render = function render() {
    var _props = this.props,
        responsive = _props.responsive,
        href = _props.href,
        children = _props.children,
        props = (0, _objectWithoutProperties3.default)(_props, ['responsive', 'href', 'children']);

    if (responsive) {
      props = (0, _helpers.mergeProps)(props, { className: 'img-responsive' });
    }

    var image = _react2.default.createElement(
      'img',
      props,
      children
    );
    return href ? _react2.default.createElement(
      'a',
      { href: href },
      image
    ) : image;
  };

  return Image;
}(_react2.default.PureComponent);

Image.propTypes = {
  responsive: _propTypes2.default.bool,
  href: _propTypes2.default.string,
  alt: _propTypes2.default.string,
  src: _propTypes2.default.string.isRequired
};