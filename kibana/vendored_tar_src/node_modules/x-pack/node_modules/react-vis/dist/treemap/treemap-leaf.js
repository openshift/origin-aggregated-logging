'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _animation = require('../animation');

var _animation2 = _interopRequireDefault(_animation);

var _scalesUtils = require('../utils/scales-utils');

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

var ANIMATED_PROPS = ['colorRange', 'colorDomain', 'color', 'opacityRange', 'opacityDomain', 'opacity', 'x0', 'x1', 'y0', 'y1', 'r'];

var TreemapLeaf = function (_React$Component) {
  _inherits(TreemapLeaf, _React$Component);

  function TreemapLeaf() {
    _classCallCheck(this, TreemapLeaf);

    return _possibleConstructorReturn(this, (TreemapLeaf.__proto__ || Object.getPrototypeOf(TreemapLeaf)).apply(this, arguments));
  }

  _createClass(TreemapLeaf, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          animation = _props.animation,
          getLabel = _props.getLabel,
          mode = _props.mode,
          node = _props.node,
          onLeafClick = _props.onLeafClick,
          onLeafMouseOver = _props.onLeafMouseOver,
          onLeafMouseOut = _props.onLeafMouseOut,
          r = _props.r,
          scales = _props.scales,
          x0 = _props.x0,
          x1 = _props.x1,
          y0 = _props.y0,
          y1 = _props.y1,
          style = _props.style;


      if (animation) {
        return _react2.default.createElement(
          _animation2.default,
          _extends({}, this.props, { animatedProps: ANIMATED_PROPS }),
          _react2.default.createElement(TreemapLeaf, _extends({}, this.props, { animation: null }))
        );
      }
      var useCirclePacking = mode === 'circlePack';
      var background = scales.color(node);
      var opacity = scales.opacity(node);
      var color = (0, _scalesUtils.getFontColorFromBackground)(background);
      var data = node.data;

      var title = getLabel(data);
      var leafStyle = _extends({
        top: useCirclePacking ? y0 - r : y0,
        left: useCirclePacking ? x0 - r : x0,
        width: useCirclePacking ? r * 2 : x1 - x0,
        height: useCirclePacking ? r * 2 : y1 - y0,
        background: background,
        opacity: opacity,
        color: color
      }, style, node.data.style);

      return _react2.default.createElement(
        'div',
        {
          className: 'rv-treemap__leaf ' + (useCirclePacking ? 'rv-treemap__leaf--circle' : ''),
          onMouseEnter: function onMouseEnter(event) {
            return onLeafMouseOver(node, event);
          },
          onMouseLeave: function onMouseLeave(event) {
            return onLeafMouseOut(node, event);
          },
          onClick: function onClick(event) {
            return onLeafClick(node, event);
          },
          style: leafStyle },
        _react2.default.createElement(
          'div',
          { className: 'rv-treemap__leaf__content' },
          title
        )
      );
    }
  }]);

  return TreemapLeaf;
}(_react2.default.Component);

TreemapLeaf.propTypes = {
  animation: _animation.AnimationPropType,
  height: _propTypes2.default.number.isRequired,
  mode: _propTypes2.default.string,
  node: _propTypes2.default.object.isRequired,
  onLeafClick: _propTypes2.default.func,
  onLeafMouseOver: _propTypes2.default.func,
  onLeafMouseOut: _propTypes2.default.func,
  scales: _propTypes2.default.object.isRequired,
  width: _propTypes2.default.number.isRequired,
  r: _propTypes2.default.number.isRequired,
  x0: _propTypes2.default.number.isRequired,
  x1: _propTypes2.default.number.isRequired,
  y0: _propTypes2.default.number.isRequired,
  y1: _propTypes2.default.number.isRequired
};
exports.default = TreemapLeaf;