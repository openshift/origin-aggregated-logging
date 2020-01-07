/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.BreadcrumbList = exports.InlineList = exports.OrderedList = exports.UnorderedList = exports.ListItem = undefined;

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

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ListItem = exports.ListItem = function (_React$PureComponent) {
  (0, _inherits3.default)(ListItem, _React$PureComponent);

  function ListItem() {
    (0, _classCallCheck3.default)(this, ListItem);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  ListItem.prototype.render = function render() {
    return _react2.default.createElement('li', this.props);
  };

  return ListItem;
}(_react2.default.PureComponent);

var defList = function defList(tagName, classNames, childClassNames) {
  var _class, _temp;

  return _temp = _class = function (_React$Component) {
    (0, _inherits3.default)(_class, _React$Component);

    function _class() {
      (0, _classCallCheck3.default)(this, _class);
      return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
    }

    _class.prototype.componentDidMount = function componentDidMount() {
      require('../../css/lists');
    };

    _class.prototype.render = function render() {
      var _props = this.props,
          className = _props.className,
          children = _props.children,
          unstyled = _props.unstyled,
          divider = _props.divider,
          others = (0, _objectWithoutProperties3.default)(_props, ['className', 'children', 'unstyled', 'divider']);

      var classes = (0, _classnames2.default)(classNames(this.props), className);
      if (childClassNames) {
        children = _react2.default.Children.map(children, function (child) {
          return _react2.default.cloneElement(child, { className: childClassNames });
        });
      }

      return tagName === 'ul' ? _react2.default.createElement(
        'ul',
        (0, _extends3.default)({ className: classes }, others),
        children
      ) : tagName === 'ol' ? _react2.default.createElement(
        'ol',
        (0, _extends3.default)({ className: classes }, others),
        children
      ) : null;
    };

    return _class;
  }(_react2.default.Component), _class.propTypes = {
    className: _propTypes2.default.string,
    unstyled: _propTypes2.default.bool,
    divider: _propTypes2.default.bool
  }, _temp;
};

var UnorderedList = exports.UnorderedList = defList('ul', function (_ref) {
  var unstyled = _ref.unstyled,
      divider = _ref.divider;
  return (0, _classnames2.default)({ 'list-unordered': !unstyled, 'list-unstyled': unstyled, 'list-divider': divider });
});
var OrderedList = exports.OrderedList = defList('ol', function (_ref2) {
  var unstyled = _ref2.unstyled,
      divider = _ref2.divider;
  return (0, _classnames2.default)({ 'list-unstyled': unstyled, 'list-divider': divider });
});
var InlineList = exports.InlineList = defList('ul', function (_ref3) {
  var divider = _ref3.divider;
  return (0, _classnames2.default)('list-inline', { 'list-inline-divider': divider });
});
var BreadcrumbList = exports.BreadcrumbList = defList('ul', function () {
  return (0, _classnames2.default)('list-breadcrumb');
});