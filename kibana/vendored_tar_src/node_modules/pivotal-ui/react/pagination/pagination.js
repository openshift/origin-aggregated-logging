/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Pagination = undefined;

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

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var PaginationButton = function (_React$PureComponent) {
  (0, _inherits3.default)(PaginationButton, _React$PureComponent);

  function PaginationButton() {
    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, PaginationButton);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.call.apply(_React$PureComponent, [this].concat(args))), _this), _this.click = function (e) {
      var _this$props = _this.props,
          eventKey = _this$props.eventKey,
          onSelect = _this$props.onSelect;

      onSelect && onSelect(e, { eventKey: eventKey });
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  PaginationButton.prototype.componentDidMount = function componentDidMount() {
    require('../../css/pagination');
  };

  PaginationButton.prototype.render = function render() {
    var _props = this.props,
        content = _props.content,
        active = _props.active;

    return _react2.default.createElement(
      'button',
      { onClick: this.click, className: (0, _classnames2.default)('btn', {
          'btn-default-alt': !active, 'btn-default': active
        }) },
      content
    );
  };

  return PaginationButton;
}(_react2.default.PureComponent);

PaginationButton.propTypes = {
  content: _propTypes2.default.node,
  active: _propTypes2.default.bool,
  onSelect: _propTypes2.default.func,
  eventKey: _propTypes2.default.oneOfType([_propTypes2.default.number, _propTypes2.default.string])
};

var Pagination = exports.Pagination = function (_React$PureComponent2) {
  (0, _inherits3.default)(Pagination, _React$PureComponent2);

  function Pagination() {
    (0, _classCallCheck3.default)(this, Pagination);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent2.apply(this, arguments));
  }

  Pagination.prototype.componentDidMount = function componentDidMount() {
    require('../../css/pagination');
  };

  Pagination.prototype.render = function render() {
    var _props2 = this.props,
        items = _props2.items,
        next = _props2.next,
        prev = _props2.prev,
        activePage = _props2.activePage,
        onSelect = _props2.onSelect,
        small = _props2.small,
        large = _props2.large,
        props = (0, _objectWithoutProperties3.default)(_props2, ['items', 'next', 'prev', 'activePage', 'onSelect', 'small', 'large']);

    var paginationButtons = [];
    for (var i = 0; i < items; i++) {
      var isActive = i + 1 === activePage;
      paginationButtons.push(_react2.default.createElement(PaginationButton, (0, _extends3.default)({
        key: i,
        content: i + 1,
        active: isActive,
        onSelect: onSelect,
        eventKey: i + 1
      }, props)));
    }

    var prevButton = _react2.default.createElement(PaginationButton, { onSelect: onSelect, eventKey: 'prev', content: '\u2039' });
    var nextButton = _react2.default.createElement(PaginationButton, { onSelect: onSelect, eventKey: 'next', content: '\u203A' });

    return _react2.default.createElement(
      'div',
      { className: (0, _classnames2.default)('pagination', 'btn-group', {
          'btn-group-small': small,
          'btn-group-large': large
        }), role: 'group' },
      prev ? prevButton : null,
      paginationButtons,
      next ? nextButton : null
    );
  };

  return Pagination;
}(_react2.default.PureComponent);

Pagination.propTypes = {
  items: _propTypes2.default.number,
  next: _propTypes2.default.bool,
  prev: _propTypes2.default.bool,
  activePage: _propTypes2.default.number,
  onSelect: _propTypes2.default.func,
  small: _propTypes2.default.bool,
  large: _propTypes2.default.bool
};
Pagination.defaultProps = {
  items: 1,
  next: true,
  prev: true,
  onSelect: function onSelect() {}
};