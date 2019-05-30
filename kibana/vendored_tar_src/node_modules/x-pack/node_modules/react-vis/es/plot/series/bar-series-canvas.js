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
import PropTypes from 'prop-types';
import { rgb } from 'd3-color';

import { DEFAULT_OPACITY } from '../../theme';
import { getAttributeFunctor, getScaleObjectFromProps, getAttr0Functor } from '../../utils/scales-utils';
import { getStackParams } from '../../utils/series-utils';
import AbstractSeries from './abstract-series';

function getScaleDistance(props, attr) {
  var scaleObject = getScaleObjectFromProps(props, attr);
  return scaleObject ? scaleObject.distance : 0;
}

var BarSeriesCanvas = function (_AbstractSeries) {
  _inherits(BarSeriesCanvas, _AbstractSeries);

  function BarSeriesCanvas() {
    _classCallCheck(this, BarSeriesCanvas);

    return _possibleConstructorReturn(this, (BarSeriesCanvas.__proto__ || Object.getPrototypeOf(BarSeriesCanvas)).apply(this, arguments));
  }

  _createClass(BarSeriesCanvas, [{
    key: 'render',
    value: function render() {
      return null;
    }
  }], [{
    key: 'renderLayer',
    value: function renderLayer(props, ctx) {
      var data = props.data,
          linePosAttr = props.linePosAttr,
          lineSizeAttr = props.lineSizeAttr,
          valuePosAttr = props.valuePosAttr,
          marginTop = props.marginTop,
          marginBottom = props.marginBottom;

      if (!data || data.length === 0) {
        return;
      }

      var distance = getScaleDistance(props, linePosAttr);
      var line = getAttributeFunctor(props, linePosAttr);
      var value = getAttributeFunctor(props, valuePosAttr);
      var value0 = getAttr0Functor(props, valuePosAttr);
      var fill = getAttributeFunctor(props, 'fill') || getAttributeFunctor(props, 'color');
      var stroke = getAttributeFunctor(props, 'stroke') || getAttributeFunctor(props, 'color');
      var opacity = getAttributeFunctor(props, 'opacity');

      var itemSize = distance / 2 * 0.85;

      var _getStackParams = getStackParams(props),
          sameTypeTotal = _getStackParams.sameTypeTotal,
          sameTypeIndex = _getStackParams.sameTypeIndex;

      data.forEach(function (row) {
        var fillColor = rgb(fill(row));
        var strokeColor = rgb(stroke(row));
        var rowOpacity = opacity(row) || DEFAULT_OPACITY;

        var linePos = line(row) - itemSize + itemSize * 2 / sameTypeTotal * sameTypeIndex;
        var valuePos = Math.min(value0(row), value(row));
        var x = valuePosAttr === 'x' ? valuePos : linePos;
        var y = valuePosAttr === 'y' ? valuePos : linePos;

        var lineSize = itemSize * 2 / sameTypeTotal;
        var valueSize = Math.abs(-value0(row) + value(row));
        var height = lineSizeAttr === 'height' ? lineSize : valueSize;
        var width = lineSizeAttr === 'width' ? lineSize : valueSize;

        ctx.beginPath();
        ctx.rect(x + marginBottom, y + marginTop, width, height);
        ctx.fillStyle = 'rgba(' + fillColor.r + ', ' + fillColor.g + ', ' + fillColor.b + ', ' + rowOpacity + ')';
        ctx.fill();
        ctx.strokeStyle = 'rgba(' + strokeColor.r + ', ' + strokeColor.g + ', ' + strokeColor.b + ', ' + rowOpacity + ')';
        ctx.stroke();
      });
    }
  }, {
    key: 'requiresSVG',
    get: function get() {
      return false;
    }
  }, {
    key: 'isCanvas',
    get: function get() {
      return true;
    }
  }]);

  return BarSeriesCanvas;
}(AbstractSeries);

BarSeriesCanvas.displayName = 'BarSeriesCanvas';
BarSeriesCanvas.defaultProps = {
  linePosAttr: PropTypes.string.isRequired,
  valuePosAttr: PropTypes.string.isRequired,
  lineSizeAttr: PropTypes.string.isRequired,
  valueSizeAttr: PropTypes.string.isRequired
};

BarSeriesCanvas.propTypes = _extends({}, AbstractSeries.propTypes);

export default BarSeriesCanvas;