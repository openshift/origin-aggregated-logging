var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

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

import { getAttributeFunctor } from '../utils/scales-utils';

/**
 * Format title by detault.
 * @param {Array} values List of values.
 * @returns {*} Formatted value or undefined.
 */
function defaultTitleFormat(values) {
  var value = getFirstNonEmptyValue(values);
  if (value) {
    return {
      title: 'x',
      value: value.x
    };
  }
}

/**
 * Format items by default.
 * @param {Array} values Array of values.
 * @returns {*} Formatted list of items.
 */
function defaultItemsFormat(values) {
  return values.map(function (v, i) {
    if (v) {
      return { value: v.y, title: i };
    }
  });
}

/**
 * Get the first non-empty item from an array.
 * @param {Array} values Array of values.
 * @returns {*} First non-empty value or undefined.
 */
function getFirstNonEmptyValue(values) {
  return (values || []).find(function (v) {
    return Boolean(v);
  });
}

var Crosshair = function (_PureComponent) {
  _inherits(Crosshair, _PureComponent);

  function Crosshair() {
    _classCallCheck(this, Crosshair);

    return _possibleConstructorReturn(this, (Crosshair.__proto__ || Object.getPrototypeOf(Crosshair)).apply(this, arguments));
  }

  _createClass(Crosshair, [{
    key: '_renderCrosshairTitle',


    /**
     * Render crosshair title.
     * @returns {*} Container with the crosshair title.
     * @private
     */
    value: function _renderCrosshairTitle() {
      var _props = this.props,
          values = _props.values,
          titleFormat = _props.titleFormat,
          style = _props.style;

      var titleItem = titleFormat(values);
      if (!titleItem) {
        return null;
      }
      return React.createElement(
        'div',
        { className: 'rv-crosshair__title', key: 'title', style: style.title },
        React.createElement(
          'span',
          { className: 'rv-crosshair__title__title' },
          titleItem.title
        ),
        ': ',
        React.createElement(
          'span',
          { className: 'rv-crosshair__title__value' },
          titleItem.value
        )
      );
    }

    /**
     * Render crosshair items (title + value for each series).
     * @returns {*} Array of React classes with the crosshair values.
     * @private
     */

  }, {
    key: '_renderCrosshairItems',
    value: function _renderCrosshairItems() {
      var _props2 = this.props,
          values = _props2.values,
          itemsFormat = _props2.itemsFormat;

      var items = itemsFormat(values);
      if (!items) {
        return null;
      }
      return items.filter(function (i) {
        return i;
      }).map(function renderValue(item, i) {
        return React.createElement(
          'div',
          { className: 'rv-crosshair__item', key: 'item' + i },
          React.createElement(
            'span',
            { className: 'rv-crosshair__item__title' },
            item.title
          ),
          ': ',
          React.createElement(
            'span',
            { className: 'rv-crosshair__item__value' },
            item.value
          )
        );
      });
    }
  }, {
    key: 'render',
    value: function render() {
      var _props3 = this.props,
          children = _props3.children,
          values = _props3.values,
          marginTop = _props3.marginTop,
          marginLeft = _props3.marginLeft,
          innerWidth = _props3.innerWidth,
          innerHeight = _props3.innerHeight,
          style = _props3.style;

      var value = getFirstNonEmptyValue(values);
      if (!value) {
        return null;
      }
      var x = getAttributeFunctor(this.props, 'x');
      var innerLeft = x(value);

      var _props$orientation = this.props.orientation,
          orientation = _props$orientation === undefined ? innerLeft > innerWidth / 2 ? 'left' : 'right' : _props$orientation;

      var left = marginLeft + innerLeft;
      var top = marginTop;
      var innerClassName = 'rv-crosshair__inner rv-crosshair__inner--' + orientation;

      return React.createElement(
        'div',
        {
          className: 'rv-crosshair',
          style: { left: left + 'px', top: top + 'px' } },
        React.createElement('div', {
          className: 'rv-crosshair__line',
          style: _extends({ height: innerHeight + 'px' }, style.line) }),
        React.createElement(
          'div',
          { className: innerClassName },
          children ? children : React.createElement(
            'div',
            { className: 'rv-crosshair__inner__content', style: style.box },
            React.createElement(
              'div',
              null,
              this._renderCrosshairTitle(),
              this._renderCrosshairItems()
            )
          )
        )
      );
    }
  }], [{
    key: 'propTypes',
    get: function get() {
      return {
        values: PropTypes.array,
        series: PropTypes.object,
        innerWidth: PropTypes.number,
        innerHeight: PropTypes.number,
        marginLeft: PropTypes.number,
        marginTop: PropTypes.number,
        orientation: PropTypes.oneOf(['left', 'right']),
        itemsFormat: PropTypes.func,
        titleFormat: PropTypes.func,
        style: PropTypes.shape({
          line: PropTypes.object,
          title: PropTypes.object,
          box: PropTypes.object
        })
      };
    }
  }, {
    key: 'defaultProps',
    get: function get() {
      return {
        titleFormat: defaultTitleFormat,
        itemsFormat: defaultItemsFormat,
        style: {
          line: {},
          title: {},
          box: {}
        }
      };
    }
  }]);

  return Crosshair;
}(PureComponent);

Crosshair.displayName = 'Crosshair';

export default Crosshair;