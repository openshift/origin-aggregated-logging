/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _values = require('babel-runtime/core-js/object/values');

var _values2 = _interopRequireDefault(_values);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _weakMap = require('babel-runtime/core-js/weak-map');

var _weakMap2 = _interopRequireDefault(_weakMap);

exports.withRowDrawer = withRowDrawer;

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _collapsible = require('../../collapsible');

var _iconography = require('../../iconography');

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _tablePlugin = require('../table-plugin');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
var privates = new _weakMap2.default();
var TABLE_KEYS = {
  UP: 38,
  DOWN: 40
};
var ROW_KEYS = {
  LEFT: 37,
  RIGHT: 39
};

function withRowDrawer(Table) {
  var _class, _temp;

  var TbodyWithDrawer = function (_React$Component) {
    (0, _inherits3.default)(TbodyWithDrawer, _React$Component);

    function TbodyWithDrawer(props) {
      (0, _classCallCheck3.default)(this, TbodyWithDrawer);

      var _this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call(this, props));

      _this.state = {};
      privates.set(_this, {});
      return _this;
    }

    TbodyWithDrawer.prototype.componentWillMount = function componentWillMount() {
      var _this2 = this;

      if (!this.props.keyboardNavigation) return;
      var keyDownListener = function keyDownListener(e) {
        return _this2.handleKeyDown(e);
      };
      privates.set(this, { keyDownListener: keyDownListener });
      document.addEventListener('keydown', keyDownListener);
    };

    TbodyWithDrawer.prototype.componentWillUnmount = function componentWillUnmount() {
      var _privates$get = privates.get(this),
          keyDownListener = _privates$get.keyDownListener;

      if (!keyDownListener) return;
      document.removeEventListener('keydown', keyDownListener);
      privates.set(this, { keyDownListener: null });
    };

    TbodyWithDrawer.prototype.handleKeyDown = function handleKeyDown(e) {
      if ((0, _values2.default)(TABLE_KEYS).indexOf(e.keyCode) === -1) return;

      e.preventDefault();

      var children = this.props.children;
      var selectedRow = this.state.selectedRow;


      var currentRow = typeof selectedRow === 'number' ? selectedRow : -1;

      var newSelectedRow = void 0;
      if (e.keyCode === TABLE_KEYS.UP) {
        newSelectedRow = Math.max(0, currentRow - 1);
      } else {
        newSelectedRow = Math.min(children.length - 1, currentRow + 1);
      }

      this.setState({ selectedRow: newSelectedRow });
    };

    TbodyWithDrawer.prototype.render = function render() {
      var selectedRow = this.state.selectedRow;
      // eslint-disable-next-line no-unused-vars

      var _props = this.props,
          oldChildren = _props.children,
          keyboardNavigation = _props.keyboardNavigation,
          props = (0, _objectWithoutProperties3.default)(_props, ['children', 'keyboardNavigation']);

      var children = oldChildren.filter(function (child) {
        return child;
      }).map(function (child, i) {
        var isSelected = i === selectedRow;
        if (!isSelected) return child;
        return _react2.default.cloneElement(child, { isSelected: isSelected });
      });
      return _react2.default.createElement(
        'div',
        props,
        children
      );
    };

    return TbodyWithDrawer;
  }(_react2.default.Component);

  TbodyWithDrawer.propTypes = {
    keyboardNavigation: _propTypes2.default.bool
  };

  var RowWithDrawer = function (_React$Component2) {
    (0, _inherits3.default)(RowWithDrawer, _React$Component2);

    function RowWithDrawer(props) {
      (0, _classCallCheck3.default)(this, RowWithDrawer);

      var _this3 = (0, _possibleConstructorReturn3.default)(this, _React$Component2.call(this, props));

      _this3.state = { expanded: false };
      privates.set(_this3, {});
      return _this3;
    }

    RowWithDrawer.prototype.componentWillMount = function componentWillMount() {
      var _this4 = this;

      if (!this.props.keyboardNavigation) return;
      var keyDownListener = function keyDownListener(e) {
        return _this4.handleKeyDown(e);
      };
      privates.set(this, { keyDownListener: keyDownListener });
      document.addEventListener('keydown', keyDownListener);
    };

    RowWithDrawer.prototype.componentWillUnmount = function componentWillUnmount() {
      var _privates$get2 = privates.get(this),
          keyDownListener = _privates$get2.keyDownListener;

      if (!keyDownListener) return;
      document.removeEventListener('keydown', keyDownListener);
      privates.set(this, { keyDownListener: null });
    };

    RowWithDrawer.prototype.handleKeyDown = function handleKeyDown(e) {
      if ((0, _values2.default)(ROW_KEYS).indexOf(e.keyCode) === -1) return;

      e.preventDefault();

      var isSelected = this.props.isSelected;

      if (!isSelected) return;

      var _props2 = this.props,
          rowDrawer = _props2.rowDrawer,
          rowIndex = _props2.rowIndex,
          rowDatum = _props2.rowDatum;

      var drawerContent = rowIndex !== -1 && rowDrawer(rowIndex, rowDatum);
      if (!drawerContent) return;

      if (e.keyCode === ROW_KEYS.RIGHT) {
        this.setState({ expanded: true });
      } else {
        this.setState({ expanded: false });
      }
    };

    RowWithDrawer.prototype.render = function render() {
      var _this5 = this;

      // eslint-disable-next-line no-unused-vars
      var _props3 = this.props,
          children = _props3.children,
          rowDrawer = _props3.rowDrawer,
          rowIndex = _props3.rowIndex,
          rowDatum = _props3.rowDatum,
          keyboardNavigation = _props3.keyboardNavigation,
          isSelected = _props3.isSelected,
          props = (0, _objectWithoutProperties3.default)(_props3, ['children', 'rowDrawer', 'rowIndex', 'rowDatum', 'keyboardNavigation', 'isSelected']);
      var expanded = this.state.expanded;


      var drawerContent = rowIndex !== -1 && rowDrawer(rowIndex, rowDatum);
      var onClick = function onClick() {
        return drawerContent && _this5.setState({ expanded: !expanded });
      };
      var src = expanded ? 'chevron_down' : 'chevron_right';
      var className = (0, _classnames2.default)(props.className, { expandable: rowIndex !== -1 }, { expanded: expanded }, { 'tr-selected': isSelected }, { 'no-drawer-content': rowIndex !== -1 && !drawerContent });

      var leftColumn = void 0;
      if (rowIndex !== -1) {
        leftColumn = _react2.default.createElement(_iconography.Icon, { className: 'expand-icon', src: src });
      } else {
        leftColumn = _react2.default.createElement('div', {
          className: 'th col col-fixed',
          style: { borderRightWidth: '0px', width: '36px' }
        });
      }
      return _react2.default.createElement(
        'div',
        { className: 'tr-drawer' },
        _react2.default.createElement(
          'div',
          (0, _extends3.default)({}, props, { onClick: onClick, className: className }),
          leftColumn,
          children
        ),
        rowIndex !== -1 && _react2.default.createElement(
          _collapsible.Collapsible,
          { expanded: expanded && !!drawerContent, delay: 200 },
          drawerContent
        )
      );
    };

    return RowWithDrawer;
  }(_react2.default.Component);

  RowWithDrawer.propTypes = {
    rowDrawer: _propTypes2.default.func,
    rowIndex: _propTypes2.default.number,
    rowDatum: _propTypes2.default.object,
    keyboardNavigation: _propTypes2.default.bool,
    isSelected: _propTypes2.default.bool
  };


  return _temp = _class = function (_TablePlugin) {
    (0, _inherits3.default)(TableWithRowDrawer, _TablePlugin);

    function TableWithRowDrawer() {
      (0, _classCallCheck3.default)(this, TableWithRowDrawer);
      return (0, _possibleConstructorReturn3.default)(this, _TablePlugin.apply(this, arguments));
    }

    TableWithRowDrawer.prototype.render = function render() {
      var _props4 = this.props,
          rowDrawer = _props4.rowDrawer,
          keyboardNavigation = _props4.keyboardNavigation,
          props = (0, _objectWithoutProperties3.default)(_props4, ['rowDrawer', 'keyboardNavigation']);

      return this.renderTable(Table, {
        tbodyTag: function tbodyTag() {
          return rowDrawer && TbodyWithDrawer;
        },
        trTag: function trTag() {
          return rowDrawer && RowWithDrawer;
        },
        tbody: function tbody() {
          return rowDrawer && { keyboardNavigation: keyboardNavigation };
        },
        tr: function tr(props, _ref) {
          var rowIndex = _ref.rowIndex,
              rowDatum = _ref.rowDatum;
          return rowDrawer && {
            rowDrawer: rowDrawer,
            rowIndex: rowIndex,
            rowDatum: rowDatum,
            keyboardNavigation: keyboardNavigation
          };
        }
      }, props);
    };

    return TableWithRowDrawer;
  }(_tablePlugin.TablePlugin), _class.propTypes = {
    rowDrawer: _propTypes2.default.func,
    keyboardNavigation: _propTypes2.default.bool
  }, _temp;
}