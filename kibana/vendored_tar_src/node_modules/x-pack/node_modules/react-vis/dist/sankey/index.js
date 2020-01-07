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

var _d3Sankey = require('d3-sankey');

var _xyPlot = require('../plot/xy-plot');

var _xyPlot2 = _interopRequireDefault(_xyPlot);

var _chartUtils = require('../utils/chart-utils');

var _verticalRectSeries = require('../plot/series/vertical-rect-series');

var _verticalRectSeries2 = _interopRequireDefault(_verticalRectSeries);

var _labelSeries = require('../plot/series/label-series');

var _labelSeries2 = _interopRequireDefault(_labelSeries);

var _voronoi = require('../plot/voronoi');

var _voronoi2 = _interopRequireDefault(_voronoi);

var _theme = require('../theme');

var _sankeyLink = require('./sankey-link');

var _sankeyLink2 = _interopRequireDefault(_sankeyLink);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var NOOP = function NOOP(f) {
  return f;
};

var ALIGNMENTS = {
  justify: _d3Sankey.sankeyJustify,
  center: _d3Sankey.sankeyCenter,
  left: _d3Sankey.sankeyLeft,
  right: _d3Sankey.sankeyRight
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

      var _getInnerDimensions = (0, _chartUtils.getInnerDimensions)({
        margin: margin, height: height, width: width
      }, DEFAULT_MARGINS),
          marginLeft = _getInnerDimensions.marginLeft,
          marginTop = _getInnerDimensions.marginTop,
          marginRight = _getInnerDimensions.marginRight,
          marginBottom = _getInnerDimensions.marginBottom;

      var sankeyInstance = (0, _d3Sankey.sankey)().extent([[marginLeft, marginTop], [width - marginRight, height - marginBottom - marginTop]]).nodeWidth(nodeWidth).nodePadding(nodePadding).nodes(nodesCopy).links(linksCopy).nodeAlign(ALIGNMENTS[align]).iterations(layout);
      sankeyInstance(nodesCopy);

      var nWidth = sankeyInstance.nodeWidth();
      var path = (0, _d3Sankey.sankeyLinkHorizontal)();

      return _react2.default.createElement(
        _xyPlot2.default,
        _extends({}, this.props, {
          yType: 'literal',
          className: 'rv-sankey ' + className }),
        linksCopy.map(function (link, i) {
          return _react2.default.createElement(_sankeyLink2.default, {
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
        _react2.default.createElement(_verticalRectSeries2.default, {
          animation: animation,
          className: className + ' rv-sankey__node',
          data: nodesCopy.map(function (node) {
            return _extends({}, node, {
              y: node.y1 - marginTop,
              y0: node.y0 - marginTop,
              x: node.x1,
              x0: node.x0,
              color: node.color || _theme.DISCRETE_COLOR_RANGE[0],
              sourceLinks: null,
              targetLinks: null
            });
          }),
          style: style.rects,
          onValueClick: onValueClick,
          onValueMouseOver: onValueMouseOver,
          onValueMouseOut: onValueMouseOut,
          colorType: 'literal' }),
        !hideLabels && _react2.default.createElement(_labelSeries2.default, {
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
        hasVoronoi && _react2.default.createElement(_voronoi2.default, {
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
}(_react.Component);

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
  align: _propTypes2.default.oneOf(['justify', 'left', 'right', 'center']),
  className: _propTypes2.default.string,
  hasVoronoi: _propTypes2.default.bool,
  height: _propTypes2.default.number.isRequired,
  hideLabels: _propTypes2.default.bool,
  layout: _propTypes2.default.number,
  links: _propTypes2.default.arrayOf(_propTypes2.default.shape({
    source: _propTypes2.default.oneOfType([_propTypes2.default.number, _propTypes2.default.object]).isRequired,
    target: _propTypes2.default.oneOfType([_propTypes2.default.number, _propTypes2.default.object]).isRequired
  })).isRequired,
  margin: _chartUtils.MarginPropType,
  nodePadding: _propTypes2.default.number,
  nodes: _propTypes2.default.arrayOf(_propTypes2.default.object).isRequired,
  nodeWidth: _propTypes2.default.number,
  onValueMouseOver: _propTypes2.default.func,
  onValueClick: _propTypes2.default.func,
  onValueMouseOut: _propTypes2.default.func,
  onLinkClick: _propTypes2.default.func,
  onLinkMouseOver: _propTypes2.default.func,
  onLinkMouseOut: _propTypes2.default.func,
  style: _propTypes2.default.shape({
    links: _propTypes2.default.object,
    rects: _propTypes2.default.object,
    labels: _propTypes2.default.object
  }),
  width: _propTypes2.default.number.isRequired
};
exports.default = Sankey;