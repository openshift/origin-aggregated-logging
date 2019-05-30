/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.SmallTabs = undefined;

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

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SmallTab = function (_React$PureComponent) {
  (0, _inherits3.default)(SmallTab, _React$PureComponent);

  function SmallTab() {
    (0, _classCallCheck3.default)(this, SmallTab);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  SmallTab.prototype.render = function render() {
    var _props = this.props,
        animation = _props.animation,
        ariaLabelledBy = _props.ariaLabelledBy,
        children = _props.children,
        disabled = _props.disabled,
        expanded = _props.expanded,
        header = _props.header,
        onClick = _props.onClick,
        paneId = _props.paneId;

    var delay = void 0;
    if (!animation) delay = 0;

    var collapsibleProps = {
      'aria-labelledby': ariaLabelledBy,
      className: 'tab-content',
      delay: delay,
      expanded: expanded,
      role: 'tabpanel'
    };

    return _react2.default.createElement(
      'div',
      null,
      _react2.default.createElement(
        'div',
        { className: 'tab-heading' },
        _react2.default.createElement(
          'h4',
          { className: 'tab-title', role: 'presentation' },
          _react2.default.createElement(
            'a',
            { 'aria-expanded': expanded, 'aria-controls': paneId, 'aria-selected': expanded,
              className: (0, _classnames2.default)({ disabled: disabled }), role: 'tab', onClick: onClick },
            header
          )
        )
      ),
      _react2.default.createElement(
        _collapsible.Collapsible,
        collapsibleProps,
        children
      )
    );
  };

  return SmallTab;
}(_react2.default.PureComponent);

SmallTab.propTypes = {
  animation: _propTypes2.default.bool,
  ariaLabelledBy: _propTypes2.default.string,
  disabled: _propTypes2.default.bool,
  expanded: _propTypes2.default.bool,
  header: _propTypes2.default.node,
  onClick: _propTypes2.default.func,
  paneId: _propTypes2.default.string
};

var SmallTabs = exports.SmallTabs = function (_React$Component) {
  (0, _inherits3.default)(SmallTabs, _React$Component);

  function SmallTabs() {
    (0, _classCallCheck3.default)(this, SmallTabs);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  SmallTabs.prototype.render = function render() {
    var _props2 = this.props,
        actions = _props2.actions,
        activeKey = _props2.activeKey,
        animation = _props2.animation,
        children = _props2.children,
        className = _props2.className,
        id = _props2.id,
        handleClick = _props2.handleClick,
        onSelect = _props2.onSelect,
        smallScreenClassName = _props2.smallScreenClassName,
        tabType = _props2.tabType;

    var smallScreenClasses = (0, _classnames2.default)(['tab-' + tabType + '-small-screen', 'panel-group', smallScreenClassName, className]);
    var childArray = _react2.default.Children.toArray(children);
    var childrenAsPanels = childArray.map(function (child, key) {
      var _child$props = child.props,
          ariaLabelledBy = _child$props['aria-labelledby'],
          disabled = _child$props.disabled,
          title = _child$props.title,
          eventKey = _child$props.eventKey,
          children = _child$props.children;

      var paneId = id + '-pane-' + key;
      var tabId = id + '-tab-' + key;
      var onClick = disabled ? function () {} : function (e) {
        return handleClick(e, eventKey, onSelect);
      };
      var myProps = {
        animation: animation,
        ariaLabelledBy: ariaLabelledBy || tabId,
        disabled: disabled,
        expanded: eventKey === activeKey,
        header: title,
        key: key,
        onClick: onClick,
        paneId: paneId
      };
      return _react2.default.createElement(
        SmallTab,
        myProps,
        children
      );
    });

    var actionsNode = actions ? _react2.default.createElement(
      'div',
      { className: 'tabs-action' },
      actions
    ) : null;

    return _react2.default.createElement(
      'div',
      { className: smallScreenClasses },
      actionsNode,
      childrenAsPanels
    );
  };

  return SmallTabs;
}(_react2.default.Component);

SmallTabs.propTypes = {
  actions: _propTypes2.default.oneOfType([_propTypes2.default.node, _propTypes2.default.object]),
  activeKey: _propTypes2.default.number,
  animation: _propTypes2.default.bool,
  id: _propTypes2.default.string,
  handleClick: _propTypes2.default.func,
  onSelect: _propTypes2.default.func,
  smallScreenClassName: _propTypes2.default.string,
  tabType: _propTypes2.default.string
};