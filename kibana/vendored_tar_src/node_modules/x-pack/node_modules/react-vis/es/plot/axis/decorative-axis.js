var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

// Copyright (c) 2017 Uber Technologies, Inc.
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

import React from 'react';
import { format } from 'd3-format';
import PropTypes from 'prop-types';

import AbstractSeries from '../series/abstract-series';
import DecorativeAxisTicks from './decorative-axis-ticks';
import Animation from '../../animation';

var predefinedClassName = 'rv-xy-manipulable-axis rv-xy-plot__axis';

var animatedProps = ['xRange', 'yRange', 'xDomain', 'yDomain', 'width', 'height', 'marginLeft', 'marginTop', 'marginRight', 'marginBottom', 'tickSize', 'tickTotal', 'tickSizeInner', 'tickSizeOuter'];

var DecorativeAxis = function (_AbstractSeries) {
  _inherits(DecorativeAxis, _AbstractSeries);

  function DecorativeAxis() {
    _classCallCheck(this, DecorativeAxis);

    return _possibleConstructorReturn(this, (DecorativeAxis.__proto__ || Object.getPrototypeOf(DecorativeAxis)).apply(this, arguments));
  }

  _createClass(DecorativeAxis, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          animation = _props.animation,
          className = _props.className,
          marginLeft = _props.marginLeft,
          marginTop = _props.marginTop,
          axisStart = _props.axisStart,
          axisEnd = _props.axisEnd,
          axisDomain = _props.axisDomain,
          numberOfTicks = _props.numberOfTicks,
          tickValue = _props.tickValue,
          tickSize = _props.tickSize,
          style = _props.style;


      if (animation) {
        return React.createElement(
          Animation,
          _extends({}, this.props, { animatedProps: animatedProps }),
          React.createElement(DecorativeAxis, _extends({}, this.props, { animation: null }))
        );
      }

      var x = this._getAttributeFunctor('x');
      var y = this._getAttributeFunctor('y');

      return React.createElement(
        'g',
        { className: predefinedClassName + ' ' + className,
          ref: 'container',
          transform: 'translate(' + marginLeft + ',' + marginTop + ')' },
        React.createElement('line', _extends({}, _extends({
          x1: x({ x: axisStart.x }),
          x2: x({ x: axisEnd.x }),
          y1: y({ y: axisStart.y }),
          y2: y({ y: axisEnd.y })
        }, style.line), { className: 'rv-xy-plot__axis__line' })),
        React.createElement(
          'g',
          { className: 'rv-xy-manipulable-axis__ticks' },
          DecorativeAxisTicks({
            axisDomain: axisDomain,
            axisEnd: { x: x(axisEnd), y: y(axisEnd) },
            axisStart: { x: x(axisStart), y: y(axisStart) },
            numberOfTicks: numberOfTicks,
            tickValue: tickValue,
            tickSize: tickSize,
            style: style
          })
        )
      );
    }
  }]);

  return DecorativeAxis;
}(AbstractSeries);

var DEFAULT_FORMAT = format('.2r');

DecorativeAxis.defaultProps = {
  className: '',
  numberOfTicks: 10,
  tickValue: function tickValue(d) {
    return DEFAULT_FORMAT(d);
  },
  tickSize: 5,
  style: {
    line: {
      strokeWidth: 1
    },
    ticks: {
      strokeWidth: 2
    },
    text: {}
  }
};
DecorativeAxis.propTypes = _extends({}, AbstractSeries.propTypes, {
  axisDomain: PropTypes.arrayOf(PropTypes.number).isRequired,
  axisEnd: PropTypes.shape({
    x: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
    y: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
  }).isRequired,
  axisStart: PropTypes.shape({
    x: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
    y: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
  }).isRequired,
  className: PropTypes.string,
  numberOfTicks: PropTypes.number,
  tickValue: PropTypes.func,
  tickSize: PropTypes.number,
  style: PropTypes.shape({
    line: PropTypes.object,
    ticks: PropTypes.object,
    text: PropTypes.object
  })
});
DecorativeAxis.displayName = 'DecorativeAxis';
export default DecorativeAxis;