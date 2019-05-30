var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

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

import PropTypes from 'prop-types';

/**
 * Get the dimensions of the component for the future use.
 * @param {Object} props Props.
 * @param {Object} defaultMargins Object with default margins.
 * @returns {Object} Dimensions of the component.
 */
export function getInnerDimensions(props, defaultMargins) {
  var margin = props.margin,
      width = props.width,
      height = props.height;

  var marginProps = _extends({}, defaultMargins, typeof margin === 'number' ? {
    left: margin,
    right: margin,
    top: margin,
    bottom: margin
  } : margin);
  var _marginProps$left = marginProps.left,
      marginLeft = _marginProps$left === undefined ? 0 : _marginProps$left,
      _marginProps$top = marginProps.top,
      marginTop = _marginProps$top === undefined ? 0 : _marginProps$top,
      _marginProps$right = marginProps.right,
      marginRight = _marginProps$right === undefined ? 0 : _marginProps$right,
      _marginProps$bottom = marginProps.bottom,
      marginBottom = _marginProps$bottom === undefined ? 0 : _marginProps$bottom;

  return {
    marginLeft: marginLeft,
    marginTop: marginTop,
    marginRight: marginRight,
    marginBottom: marginBottom,
    innerHeight: height - marginBottom - marginTop,
    innerWidth: width - marginLeft - marginRight
  };
}

/**
 * Calculate the margin of the sunburst,
 * so it can be at the center of the container
 * @param  {Number} width - the width of the container
 * @param  {Number} height - the height of the container
 * @param  {Number} radius - the max radius of the sunburst
 * @return {Object} an object includes {bottom, left, right, top}
 */
export function getRadialLayoutMargin(width, height, radius) {
  var marginX = width / 2 - radius;
  var marginY = height / 2 - radius;
  return {
    bottom: marginY,
    left: marginX,
    right: marginX,
    top: marginY
  };
}

export var MarginPropType = PropTypes.oneOfType([PropTypes.shape({
  left: PropTypes.number,
  top: PropTypes.number,
  right: PropTypes.number,
  bottom: PropTypes.number
}), PropTypes.number]);