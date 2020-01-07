var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { sankey, sankeyLinkHorizontal, sankeyLeft, sankeyRight, sankeyCenter, sankeyJustify } from 'd3-sankey';
import XYPlot from '../plot/xy-plot';

import { MarginPropType, getInnerDimensions } from '../utils/chart-utils';
import VerticalRectSeries from '../plot/series/vertical-rect-series';
import LabelSeries from '../plot/series/label-series';
import Voronoi from '../plot/voronoi';
import { DISCRETE_COLOR_RANGE } from '../theme';

import SankeyLink from './sankey-link';
var NOOP = function NOOP(f) {
  return f;
};

var ALIGNMENTS = {
  justify: sankeyJustify,
  center: sankeyCenter,
  left: sankeyLeft,
  right: sankeyRight
};

var DEFAULT_MARGINS = {
  top: 20,
  left: 20,
  right: 20,
  bottom: 20
};

var Sankey = function (_Component) {
  _inherits(Sankey, _Component);

  function Sankey() {
    _classCallCheck(this, Sankey);

    return _possibleConstructorReturn(this, (Sankey.__proto__ || Object.getPrototypeOf(Sankey)).apply(this, arguments));
  }

  _createClass(Sankey, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          align = _props.align,
          animation = _props.animation,
          children = _props.children,
          className = _props.className,
          hasVoronoi = _props.hasVoronoi,
          height = _props.height,
          hideLabels = _props.hideLabels,
          layout = _props.layout,
          links = _props.links,
          linkOpacity = _props.linkOpacity,
          margin = _props.margin,
          nodePadding = _props.nodePadding,
          nodes = _props.nodes,
          nodeWidth = _props.nodeWidth,
          onValueClick = _props.onValueClick,
          onValueMouseOver = _props.onValueMouseOver,
          onValueMouseOut = _props.onValueMouseOut,
          onLinkClick = _props.onLinkClick,
          onLinkMouseOver = _props.onLinkMouseOver,
          onLinkMouseOut = _props.onLinkMouseOut,
          style = _props.style,
          width = _props.width;

      var nodesCopy = [].concat(_toConsumableArray(new Array(nodes.length))).map(function (e, i) {
        return _extends({}, nodes[i]);
      });
      var linksCopy = [].concat(_toConsumableArray(new Array(links.length))).map(function (e, i) {
        return _extends({}, links[i]);
      });

      var _getInnerDimensions = getInnerDimensions({
        margin: margin, height: height, width: width
      }, DEFAULT_MARGINS),
          marginLeft = _getInnerDimensions.marginLeft,
          marginTop = _getInnerDimensions.marginTop,
          marginRight = _getInnerDimensions.marginRight,
          marginBottom = _getInnerDimensions.marginBottom;

      var sankeyInstance = sankey().extent([[marginLeft, marginTop], [width - marginRight, height - marginBottom - marginTop]]).nodeWidth(nodeWidth).nodePadding(nodePadding).nodes(nodesCopy).links(linksCopy).nodeAlign(ALIGNMENTS[align]).iterations(layout);
      sankeyInstance(nodesCopy);

      var nWidth = sankeyInstance.nodeWidth();
      var path = sankeyLinkHorizontal();

      return React.createElement(
        XYPlot,
        _extends({}, this.props, {
          yType: 'literal',
          className: 'rv-sankey ' + className }),
        linksCopy.map(function (link, i) {
          return React.createElement(SankeyLink, {
            style: style.links,
            data: path(link),
            opacity: link.opacity || linkOpacity,
            color: link.color,
            onLinkClick: onLinkClick,
            onLinkMouseOver: onLinkMouseOver,
            onLinkMouseOut: onLinkMouseOut,
            strokeWidth: Math.max(link.width, 1),
            node: link,
            nWidth: nWidth,
            key: 'link-' + i });
        }),
        React.createElement(VerticalRectSeries, {
          animation: animation,
          className: className + ' rv-sankey__node',
          data: nodesCopy.map(function (node) {
            return _extends({}, node, {
              y: node.y1 - marginTop,
              y0: node.y0 - marginTop,
              x: node.x1,
              x0: node.x0,
              color: node.color || DISCRETE_COLOR_RANGE[0],
              sourceLinks: null,
              targetLinks: null
            });
          }),
          style: style.rects,
          onValueClick: onValueClick,
          onValueMouseOver: onValueMouseOver,
          onValueMouseOut: onValueMouseOut,
          colorType: 'literal' }),
        !hideLabels && React.createElement(LabelSeries, {
          animation: animation,
          className: className,
          data: nodesCopy.map(function (node) {
            return {
              x: node.x0 + (node.x0 < width / 2 ? nWidth + 10 : -10),
              y: node.y0 + (node.y1 - node.y0) / 2 - marginTop,
              label: node.name,
              style: style.labels
            };
          })
        }),
        hasVoronoi && React.createElement(Voronoi, {
          className: 'rv-sankey__voronoi',
          extent: [[-marginLeft, -marginTop], [width + marginRight, height + marginBottom]],
          nodes: nodesCopy,
          onClick: onValueClick,
          onHover: onValueMouseOver,
          onBlur: onValueMouseOut,
          x: function x(d) {
            return d.x0 + (d.x1 - d.x0) / 2;
          },
          y: function y(d) {
            return d.y0 + (d.y1 - d.y0) / 2;
          }
        }),
        children
      );
    }
  }]);

  return Sankey;
}(Component);

Sankey.defaultProps = {
  align: 'justify',
  className: '',
  hasVoronoi: false,
  hideLabels: false,
  layout: 50,
  margin: DEFAULT_MARGINS,
  nodePadding: 10,
  nodeWidth: 10,
  onValueMouseOver: NOOP,
  onValueClick: NOOP,
  onValueMouseOut: NOOP,
  onLinkClick: NOOP,
  onLinkMouseOver: NOOP,
  onLinkMouseOut: NOOP,
  style: {
    links: {},
    rects: {},
    labels: {}
  }
};
Sankey.propTypes = {
  align: PropTypes.oneOf(['justify', 'left', 'right', 'center']),
  className: PropTypes.string,
  hasVoronoi: PropTypes.bool,
  height: PropTypes.number.isRequired,
  hideLabels: PropTypes.bool,
  layout: PropTypes.number,
  links: PropTypes.arrayOf(PropTypes.shape({
    source: PropTypes.oneOfType([PropTypes.number, PropTypes.object]).isRequired,
    target: PropTypes.oneOfType([PropTypes.number, PropTypes.object]).isRequired
  })).isRequired,
  margin: MarginPropType,
  nodePadding: PropTypes.number,
  nodes: PropTypes.arrayOf(PropTypes.object).isRequired,
  nodeWidth: PropTypes.number,
  onValueMouseOver: PropTypes.func,
  onValueClick: PropTypes.func,
  onValueMouseOut: PropTypes.func,
  onLinkClick: PropTypes.func,
  onLinkMouseOver: PropTypes.func,
  onLinkMouseOut: PropTypes.func,
  style: PropTypes.shape({
    links: PropTypes.object,
    rects: PropTypes.object,
    labels: PropTypes.object
  }),
  width: PropTypes.number.isRequired
};
export default Sankey;