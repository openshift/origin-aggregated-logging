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

import React from 'react';

import PropTypes from 'prop-types';

import { CONTINUOUS_COLOR_RANGE } from '../theme';

var propTypes = {
  className: PropTypes.string,
  height: PropTypes.number,
  endColor: PropTypes.string,
  endTitle: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  midColor: PropTypes.string,
  midTitle: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  startColor: PropTypes.string,
  startTitle: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  width: PropTypes.number
};

var defaultProps = {
  className: '',
  startColor: CONTINUOUS_COLOR_RANGE[0],
  endColor: CONTINUOUS_COLOR_RANGE[1]
};

function ContinuousColorLegend(_ref) {
  var startColor = _ref.startColor,
      midColor = _ref.midColor,
      endColor = _ref.endColor,
      startTitle = _ref.startTitle,
      midTitle = _ref.midTitle,
      endTitle = _ref.endTitle,
      height = _ref.height,
      width = _ref.width,
      className = _ref.className;

  var colors = [startColor];
  if (midColor) {
    colors.push(midColor);
  }
  colors.push(endColor);
  return React.createElement(
    'div',
    { className: 'rv-continuous-color-legend ' + className, style: { width: width, height: height } },
    React.createElement('div', {
      className: 'rv-gradient',
      style: { background: 'linear-gradient(to right, ' + colors.join(',') + ')' } }),
    React.createElement(
      'div',
      { className: 'rv-legend-titles' },
      React.createElement(
        'span',
        { className: 'rv-legend-titles__left' },
        startTitle
      ),
      React.createElement(
        'span',
        { className: 'rv-legend-titles__right' },
        endTitle
      ),
      midTitle ? React.createElement(
        'span',
        { className: 'rv-legend-titles__center' },
        midTitle
      ) : null
    )
  );
}

ContinuousColorLegend.displayName = 'ContinuousColorLegend';
ContinuousColorLegend.propTypes = propTypes;
ContinuousColorLegend.defaultProps = defaultProps;

export default ContinuousColorLegend;