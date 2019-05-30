var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

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

import PropTypes from 'prop-types';
import { voronoi } from 'd3-voronoi';
import { PureComponent } from 'react';

import { AnimationPropType } from '../../animation';
import { getAttributeFunctor, getAttr0Functor, getAttributeValue, getScaleObjectFromProps, getScalePropTypesByAttribute } from '../../utils/scales-utils';

var propTypes = _extends({}, getScalePropTypesByAttribute('x'), getScalePropTypesByAttribute('y'), getScalePropTypesByAttribute('size'), getScalePropTypesByAttribute('opacity'), getScalePropTypesByAttribute('color'), {
  width: PropTypes.number,
  height: PropTypes.number,
  data: PropTypes.arrayOf(PropTypes.object),
  onValueMouseOver: PropTypes.func,
  onValueMouseOut: PropTypes.func,
  onValueClick: PropTypes.func,
  onValueRightClick: PropTypes.func,
  onSeriesMouseOver: PropTypes.func,
  onSeriesMouseOut: PropTypes.func,
  onSeriesClick: PropTypes.func,
  onSeriesRightClick: PropTypes.func,
  onNearestX: PropTypes.func,
  onNearestXY: PropTypes.func,
  style: PropTypes.object,
  animation: AnimationPropType
});

var defaultProps = {
  className: '',
  style: {}
};

var AbstractSeries = function (_PureComponent) {
  _inherits(AbstractSeries, _PureComponent);

  _createClass(AbstractSeries, null, [{
    key: 'getParentConfig',


    /**
     * Get a default config for the parent.
     * @returns {Object} Empty config.
     */
    value: function getParentConfig() {
      return {};
    }
  }, {
    key: 'requiresSVG',

    /**
     * Tells the rest of the world that it requires SVG to work.
     * @returns {boolean} Result.
     */
    get: function get() {
      return true;
    }
  }]);

  function AbstractSeries(props) {
    _classCallCheck(this, AbstractSeries);

    var _this = _possibleConstructorReturn(this, (AbstractSeries.__proto__ || Object.getPrototypeOf(AbstractSeries)).call(this, props));

    _this._seriesMouseOverHandler = _this._seriesMouseOverHandler.bind(_this);
    _this._valueMouseOverHandler = _this._valueMouseOverHandler.bind(_this);
    _this._seriesMouseOutHandler = _this._seriesMouseOutHandler.bind(_this);
    _this._valueMouseOutHandler = _this._valueMouseOutHandler.bind(_this);
    _this._seriesClickHandler = _this._seriesClickHandler.bind(_this);
    _this._valueClickHandler = _this._valueClickHandler.bind(_this);
    _this._seriesRightClickHandler = _this._seriesRightClickHandler.bind(_this);
    _this._valueRightClickHandler = _this._valueRightClickHandler.bind(_this);
    return _this;
  }

  /**
   * Mouse over handler for the specific series' value.
   * @param {Object} d Value object
   * @param {Object} event Event.
   * @protected
   */


  _createClass(AbstractSeries, [{
    key: '_valueMouseOverHandler',
    value: function _valueMouseOverHandler(d, event) {
      var _props = this.props,
          onValueMouseOver = _props.onValueMouseOver,
          onSeriesMouseOver = _props.onSeriesMouseOver;

      if (onValueMouseOver) {
        onValueMouseOver(d, { event: event });
      }
      if (onSeriesMouseOver) {
        onSeriesMouseOver({ event: event });
      }
    }

    /**
     * Mouse over handler for the entire series.
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_seriesMouseOverHandler',
    value: function _seriesMouseOverHandler(event) {
      var onSeriesMouseOver = this.props.onSeriesMouseOver;

      if (onSeriesMouseOver) {
        onSeriesMouseOver({ event: event });
      }
    }

    /**
     * Mouse out handler for the specific series' value.
     * @param {Object} d Value object
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_valueMouseOutHandler',
    value: function _valueMouseOutHandler(d, event) {
      var _props2 = this.props,
          onValueMouseOut = _props2.onValueMouseOut,
          onSeriesMouseOut = _props2.onSeriesMouseOut;

      if (onValueMouseOut) {
        onValueMouseOut(d, { event: event });
      }
      if (onSeriesMouseOut) {
        onSeriesMouseOut({ event: event });
      }
    }

    /**
     * Mouse out handler for the entire series.
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_seriesMouseOutHandler',
    value: function _seriesMouseOutHandler(event) {
      var onSeriesMouseOut = this.props.onSeriesMouseOut;

      if (onSeriesMouseOut) {
        onSeriesMouseOut({ event: event });
      }
    }

    /**
     * Click handler for the specific series' value.
     * @param {Object} d Value object
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_valueClickHandler',
    value: function _valueClickHandler(d, event) {
      var _props3 = this.props,
          onValueClick = _props3.onValueClick,
          onSeriesClick = _props3.onSeriesClick;

      if (onValueClick) {
        onValueClick(d, { event: event });
      }
      if (onSeriesClick) {
        onSeriesClick({ event: event });
      }
    }

    /**
     * Right Click handler for the specific series' value.
     * @param {Object} d Value object
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_valueRightClickHandler',
    value: function _valueRightClickHandler(d, event) {
      var _props4 = this.props,
          onValueRightClick = _props4.onValueRightClick,
          onSeriesRightClick = _props4.onSeriesRightClick;

      if (onValueRightClick) {
        onValueRightClick(d, { event: event });
      }
      if (onSeriesRightClick) {
        onSeriesRightClick({ event: event });
      }
    }

    /**
     * Click handler for the entire series.
     * @param {Object} event Event.
     * @protected
     */

  }, {
    key: '_seriesClickHandler',
    value: function _seriesClickHandler(event) {
      var onSeriesClick = this.props.onSeriesClick;

      if (onSeriesClick) {
        onSeriesClick({ event: event });
      }
    }

    /**
    * Right Click handler for the entire series.
    * @param {Object} event Event.
    * @protected
    */

  }, {
    key: '_seriesRightClickHandler',
    value: function _seriesRightClickHandler(event) {
      var onSeriesRightClick = this.props.onSeriesRightClick;

      if (onSeriesRightClick) {
        onSeriesRightClick({ event: event });
      }
    }

    /**
     * Get attribute functor.
     * @param {string} attr Attribute name
     * @returns {*} Functor.
     * @protected
     */

  }, {
    key: '_getAttributeFunctor',
    value: function _getAttributeFunctor(attr) {
      return getAttributeFunctor(this.props, attr);
    }

    /**
     * Get the attr0 functor.
     * @param {string} attr Attribute name.
     * @returns {*} Functor.
     * @private
     */

  }, {
    key: '_getAttr0Functor',
    value: function _getAttr0Functor(attr) {
      return getAttr0Functor(this.props, attr);
    }

    /**
     * Get the attribute value if it is available.
     * @param {string} attr Attribute name.
     * @returns {*} Attribute value if available, fallback value or undefined
     * otherwise.
     * @protected
     */

  }, {
    key: '_getAttributeValue',
    value: function _getAttributeValue(attr) {
      return getAttributeValue(this.props, attr);
    }

    /**
     * Get the scale object distance by the attribute from the list of properties.
     * @param {string} attr Attribute name.
     * @returns {number} Scale distance.
     * @protected
     */

  }, {
    key: '_getScaleDistance',
    value: function _getScaleDistance(attr) {
      var scaleObject = getScaleObjectFromProps(this.props, attr);
      return scaleObject ? scaleObject.distance : 0;
    }
  }, {
    key: '_getXYCoordinateInContainer',
    value: function _getXYCoordinateInContainer(event) {
      var _props5 = this.props,
          _props5$marginTop = _props5.marginTop,
          marginTop = _props5$marginTop === undefined ? 0 : _props5$marginTop,
          _props5$marginLeft = _props5.marginLeft,
          marginLeft = _props5$marginLeft === undefined ? 0 : _props5$marginLeft;
      var _event$nativeEvent = event.nativeEvent,
          clientX = _event$nativeEvent.clientX,
          clientY = _event$nativeEvent.clientY,
          currentTarget = event.currentTarget;

      var rect = currentTarget.getBoundingClientRect();
      return {
        x: clientX - rect.left - currentTarget.clientLeft - marginLeft,
        y: clientY - rect.top - currentTarget.clientTop - marginTop
      };
    }
  }, {
    key: '_handleNearestX',
    value: function _handleNearestX(event) {
      var _props6 = this.props,
          onNearestX = _props6.onNearestX,
          data = _props6.data;

      var minDistance = Number.POSITIVE_INFINITY;
      var value = null;
      var valueIndex = null;

      var coordinate = this._getXYCoordinateInContainer(event);
      var xScaleFn = this._getAttributeFunctor('x');

      data.forEach(function (item, i) {
        var currentCoordinate = xScaleFn(item);
        var newDistance = Math.abs(coordinate.x - currentCoordinate);
        if (newDistance < minDistance) {
          minDistance = newDistance;
          value = item;
          valueIndex = i;
        }
      });
      if (!value) {
        return;
      }
      onNearestX(value, {
        innerX: xScaleFn(value),
        index: valueIndex,
        event: event.nativeEvent
      });
    }
  }, {
    key: '_handleNearestXY',
    value: function _handleNearestXY(event) {
      var _props7 = this.props,
          onNearestXY = _props7.onNearestXY,
          data = _props7.data;


      var coordinate = this._getXYCoordinateInContainer(event);
      var xScaleFn = this._getAttributeFunctor('x');
      var yScaleFn = this._getAttributeFunctor('y');

      // Create a voronoi with each node center points
      var voronoiInstance = voronoi().x(xScaleFn).y(yScaleFn);

      var foundPoint = voronoiInstance(data).find(coordinate.x, coordinate.y);
      var value = foundPoint.data;

      if (!value) {
        return;
      }
      onNearestXY(value, {
        innerX: foundPoint.x,
        innerY: foundPoint.y,
        index: foundPoint.index,
        event: event.nativeEvent
      });
    }
  }, {
    key: 'onParentMouseMove',
    value: function onParentMouseMove(event) {
      var _props8 = this.props,
          onNearestX = _props8.onNearestX,
          onNearestXY = _props8.onNearestXY,
          data = _props8.data;

      if (!onNearestX && !onNearestXY || !data) {
        return;
      }
      if (onNearestXY) {
        this._handleNearestXY(event);
      } else {
        this._handleNearestX(event);
      }
    }
  }]);

  return AbstractSeries;
}(PureComponent);

AbstractSeries.displayName = 'AbstractSeries';
AbstractSeries.propTypes = propTypes;
AbstractSeries.defaultProps = defaultProps;

export default AbstractSeries;