'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _theme = require('../theme');

var _animation = require('../animation');

var _animation2 = _interopRequireDefault(_animation);

var _seriesUtils = require('../utils/series-utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; } // Copyright (c) 2016 - 2017 Uber Technologies, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

var DEFAULT_LINK_COLOR = _theme.DISCRETE_COLOR_RANGE[1];
var DEFAULT_LINK_OPACITY = 0.7;

var SankeyLink = function (_PureComponent) {
  _inherits(SankeyLink, _PureComponent);

  function SankeyLink() {
    _classCallCheck(this, SankeyLink);

    return _possibleConstructorReturn(this, (SankeyLink.__proto__ || Object.getPrototypeOf(SankeyLink)).apply(this, arguments));
  }

  _createClass(SankeyLink, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          animation = _props.animation,
          data = _props.data,
          node = _props.node,
          opacity = _props.opacity,
          color = _props.color,
          strokeWidth = _props.strokeWidth,
          style = _props.style,
          onLinkClick = _props.onLinkClick,
          onLinkMouseOver = _props.onLinkMouseOver,
          onLinkMouseOut = _props.onLinkMouseOut;

      if (animation) {
        return _react2.default.createElement(
          _animation2.default,
          _extends({}, this.props, { animatedProps: _seriesUtils.ANIMATED_SERIES_PROPS }),
          _react2.default.createElement(SankeyLink, _extends({}, this.props, { animation: null }))
        );
      }
      return _react2.default.createElement('path', _extends({
        d: data
      }, style, {
        className: 'rv-sankey__link',
        opacity: Number.isFinite(opacity) ? opacity : DEFAULT_LINK_OPACITY,
        stroke: color || DEFAULT_LINK_COLOR,
        onClick: function onClick(e) {
          return onLinkClick(node, e);
        },
        onMouseOver: function onMouseOver(e) {
          return onLinkMouseOver(node, e);
        },
        onMouseOut: function onMouseOut(e) {
          return onLinkMouseOut(node, e);
        },
        strokeWidth: strokeWidth,
        fill: 'none' }));
    }
  }]);

  return SankeyLink;
}(_react.PureComponent);

SankeyLink.displayName = 'SankeyLink';
SankeyLink.requiresSVG = true;
exports.default = SankeyLink;