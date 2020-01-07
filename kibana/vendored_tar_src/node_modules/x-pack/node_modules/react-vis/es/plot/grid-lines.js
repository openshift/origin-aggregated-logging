var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

// Copyright (c) 2016 - 2017 Uber Technologies, Inc.
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

import React, { PureComponent } from 'react';

import PropTypes from 'prop-types';

import { getAttributeScale } from '../utils/scales-utils';
import Animation, { AnimationPropType } from '../animation';

import { getTicksTotalFromSize, getTickValues, DIRECTION } from '../utils/axis-utils';

var VERTICAL = DIRECTION.VERTICAL,
    HORIZONTAL = DIRECTION.HORIZONTAL;


var propTypes = {
  direction: PropTypes.oneOf([VERTICAL, HORIZONTAL]),
  attr: PropTypes.string.isRequired,
  width: PropTypes.number,
  height: PropTypes.number,
  top: PropTypes.number,
  left: PropTypes.number,

  style: PropTypes.object,

  tickValues: PropTypes.array,
  tickTotal: PropTypes.number,

  animation: AnimationPropType,

  // generally supplied by xyplot
  marginTop: PropTypes.number,
  marginBottom: PropTypes.number,
  marginLeft: PropTypes.number,
  marginRight: PropTypes.number,
  innerWidth: PropTypes.number,
  innerHeight: PropTypes.number
};

var defaultProps = {
  direction: VERTICAL
};

var animatedProps = ['xRange', 'yRange', 'xDomain', 'yDomain', 'width', 'height', 'marginLeft', 'marginTop', 'marginRight', 'marginBottom', 'tickTotal'];

var GridLines = function (_PureComponent) {
  _inherits(GridLines, _PureComponent);

  function GridLines() {
    _classCallCheck(this, GridLines);

    return _possibleConstructorReturn(this, (GridLines.__proto__ || Object.getPrototypeOf(GridLines)).apply(this, arguments));
  }

  _createClass(GridLines, [{
    key: '_getDefaultProps',
    value: function _getDefaultProps() {
      var _props = this.props,
          innerWidth = _props.innerWidth,
          innerHeight = _props.innerHeight,
          marginTop = _props.marginTop,
          marginLeft = _props.marginLeft,
          direction = _props.direction;

      return {
        left: marginLeft,
        top: marginTop,
        width: innerWidth,
        height: innerHeight,
        tickTotal: getTicksTotalFromSize(direction === VERTICAL ? innerWidth : innerHeight)
      };
    }
  }, {
    key: 'render',
    value: function render() {
      var animation = this.props.animation;

      if (animation) {
        return React.createElement(
          Animation,
          _extends({}, this.props, { animatedProps: animatedProps }),
          React.createElement(GridLines, _extends({}, this.props, { animation: null }))
        );
      }

      var props = _extends({}, this._getDefaultProps(), this.props);

      var attr = props.attr,
          direction = props.direction,
          width = props.width,
          height = props.height,
          style = props.style,
          tickTotal = props.tickTotal,
          tickValues = props.tickValues,
          top = props.top,
          left = props.left;

      var isVertical = direction === VERTICAL;
      var tickXAttr = isVertical ? 'y' : 'x';
      var tickYAttr = isVertical ? 'x' : 'y';
      var length = isVertical ? height : width;

      var scale = getAttributeScale(props, attr);
      var values = getTickValues(scale, tickTotal, tickValues);

      return React.createElement(
        'g',
        {
          transform: 'translate(' + left + ',' + top + ')',
          className: 'rv-xy-plot__grid-lines' },
        values.map(function (v, i) {
          var _pathProps;

          var pos = scale(v);
          var pathProps = (_pathProps = {}, _defineProperty(_pathProps, tickYAttr + '1', pos), _defineProperty(_pathProps, tickYAttr + '2', pos), _defineProperty(_pathProps, tickXAttr + '1', 0), _defineProperty(_pathProps, tickXAttr + '2', length), _pathProps);
          return React.createElement('line', _extends({}, pathProps, {
            key: i,
            className: 'rv-xy-plot__grid-lines__line',
            style: style }));
        })
      );
    }
  }]);

  return GridLines;
}(PureComponent);

GridLines.displayName = 'GridLines';
GridLines.defaultProps = defaultProps;
GridLines.propTypes = propTypes;
GridLines.requiresSVG = true;

export default GridLines;