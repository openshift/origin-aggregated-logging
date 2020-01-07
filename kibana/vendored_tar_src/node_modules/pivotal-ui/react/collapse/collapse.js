/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.AltCollapse = exports.Collapse = exports.BaseCollapse = undefined;

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

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _collapsible = require('../collapsible');

var _helpers = require('../helpers');

var _iconography = require('../iconography');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BaseCollapse = exports.BaseCollapse = function (_React$PureComponent) {
  (0, _inherits3.default)(BaseCollapse, _React$PureComponent);

  function BaseCollapse(props, context) {
    (0, _classCallCheck3.default)(this, BaseCollapse);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call(this, props, context));

    _this.handleSelect = function (e) {
      e.preventDefault();
      _this.setState({ expanded: !_this.state.expanded });
    };

    _this.state = { expanded: !!props.defaultExpanded };
    return _this;
  }

  BaseCollapse.prototype.componentDidMount = function componentDidMount() {
    require('../../css/collapse');
  };

  BaseCollapse.prototype.renderHeader = function renderHeader() {
    var header = this.props.header;
    var expanded = this.state.expanded;

    return _react2.default.createElement(
      'a',
      { href: '#', 'aria-expanded': expanded, 'aria-selected': expanded },
      header
    );
  };

  BaseCollapse.prototype.render = function render() {
    var _props = this.props,
        children = _props.children,
        defaultExpanded = _props.defaultExpanded,
        divider = _props.divider,
        header = _props.header,
        others = (0, _objectWithoutProperties3.default)(_props, ['children', 'defaultExpanded', 'divider', 'header']);

    var props = (0, _helpers.mergeProps)(others, { className: ['panel', { 'panel-divider': divider }] });
    var expanded = this.state.expanded;


    return _react2.default.createElement(
      'div',
      props,
      _react2.default.createElement(
        'div',
        { className: 'panel-heading', onClick: this.handleSelect },
        _react2.default.createElement(
          'div',
          { className: 'panel-title', role: 'presentation' },
          this.renderHeader()
        )
      ),
      _react2.default.createElement(
        'div',
        { className: 'panel-collapse' },
        _react2.default.createElement(
          _collapsible.Collapsible,
          { className: 'panel-body', expanded: expanded, delay: 200 },
          children
        )
      )
    );
  };

  return BaseCollapse;
}(_react2.default.PureComponent);

BaseCollapse.propTypes = {
  divider: _propTypes2.default.bool,
  header: _propTypes2.default.node.isRequired,
  defaultExpanded: _propTypes2.default.bool
};

var Collapse = exports.Collapse = function (_BaseCollapse) {
  (0, _inherits3.default)(Collapse, _BaseCollapse);

  function Collapse() {
    (0, _classCallCheck3.default)(this, Collapse);
    return (0, _possibleConstructorReturn3.default)(this, _BaseCollapse.apply(this, arguments));
  }

  Collapse.prototype.renderHeader = function renderHeader() {
    var header = this.props.header;
    var expanded = this.state.expanded;

    var iconSrc = expanded ? 'arrow_drop_down' : 'arrow_drop_right';
    return _react2.default.createElement(
      'div',
      { className: 'collapse-trigger' },
      _react2.default.createElement(_iconography.Icon, { className: 'collapse-icon', src: iconSrc }),
      header
    );
  };

  return Collapse;
}(BaseCollapse);

var AltCollapse = exports.AltCollapse = function (_BaseCollapse2) {
  (0, _inherits3.default)(AltCollapse, _BaseCollapse2);

  function AltCollapse() {
    (0, _classCallCheck3.default)(this, AltCollapse);
    return (0, _possibleConstructorReturn3.default)(this, _BaseCollapse2.apply(this, arguments));
  }

  AltCollapse.prototype.renderHeader = function renderHeader() {
    var header = this.props.header;
    var expanded = this.state.expanded;

    var iconSrc = expanded ? 'remove_circle' : 'add_circle';
    return _react2.default.createElement(
      'div',
      { className: 'collapse-trigger' },
      _react2.default.createElement(_iconography.Icon, { className: 'collapse-icon', src: iconSrc }),
      header
    );
  };

  return AltCollapse;
}(BaseCollapse);