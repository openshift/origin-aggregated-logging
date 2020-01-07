/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Panel = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _flexGrids = require('../flex-grids');

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Panel = exports.Panel = function (_React$Component) {
  (0, _inherits3.default)(Panel, _React$Component);

  function Panel() {
    (0, _classCallCheck3.default)(this, Panel);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  Panel.prototype.componentDidMount = function componentDidMount() {
    require('../../css/panels');
  };

  Panel.prototype.render = function render() {
    var _props = this.props,
        className = _props.className,
        title = _props.title,
        titleCols = _props.titleCols,
        titleClassName = _props.titleClassName,
        panelClassName = _props.panelClassName,
        header = _props.header,
        headerCols = _props.headerCols,
        headerClassName = _props.headerClassName,
        bodyClassName = _props.bodyClassName,
        loading = _props.loading,
        children = _props.children,
        footer = _props.footer,
        footerClassName = _props.footerClassName,
        props = (0, _objectWithoutProperties3.default)(_props, ['className', 'title', 'titleCols', 'titleClassName', 'panelClassName', 'header', 'headerCols', 'headerClassName', 'bodyClassName', 'loading', 'children', 'footer', 'footerClassName']);


    return _react2.default.createElement(
      'div',
      (0, _extends3.default)({}, props, { className: (0, _classnames2.default)('pui-panel-container', className) }),
      (title || titleCols.length > 0) && _react2.default.createElement(
        _flexGrids.Grid,
        { className: (0, _classnames2.default)('pui-panel-title', titleClassName) },
        title && _react2.default.createElement(
          _flexGrids.FlexCol,
          { className: 'h5 em-high type-ellipsis' },
          title
        ),
        titleCols.map(function (el, key) {
          return _react2.default.cloneElement(el, { key: key });
        })
      ),
      _react2.default.createElement(
        'div',
        { className: (0, _classnames2.default)('pui-panel bg-neutral-11 box-shadow-1 border-rounded', panelClassName) },
        (header || headerCols.length > 0) && _react2.default.createElement(
          _flexGrids.Grid,
          { className: (0, _classnames2.default)('pui-panel-header', headerClassName) },
          header && _react2.default.createElement(
            _flexGrids.FlexCol,
            { className: 'type-ellipsis em-high' },
            header
          ),
          headerCols.map(function (el, key) {
            return _react2.default.cloneElement(el, { key: key });
          })
        ),
        children && _react2.default.createElement(
          'div',
          { className: (0, _classnames2.default)('pui-panel-body', bodyClassName) },
          loading && _react2.default.createElement('div', { className: 'pui-panel-loading-indicator' }),
          children
        ),
        footer && _react2.default.createElement(
          'div',
          { className: (0, _classnames2.default)('pui-panel-footer type-ellipsis h6', footerClassName) },
          footer
        )
      )
    );
  };

  return Panel;
}(_react2.default.Component);

Panel.propTypes = {
  title: _propTypes2.default.string,
  titleCols: _propTypes2.default.array,
  titleClassName: _propTypes2.default.string,
  panelClassName: _propTypes2.default.string,
  header: _propTypes2.default.string,
  headerCols: _propTypes2.default.array,
  headerClassName: _propTypes2.default.string,
  loading: _propTypes2.default.bool,
  bodyClassName: _propTypes2.default.string,
  footer: _propTypes2.default.node,
  footerClassName: _propTypes2.default.string
};
Panel.defaultProps = {
  titleCols: [],
  headerCols: []
};