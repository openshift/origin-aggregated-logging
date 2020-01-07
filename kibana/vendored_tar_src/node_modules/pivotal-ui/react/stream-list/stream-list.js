/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.StreamListItem = exports.StreamList = undefined;

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

var _buttons = require('../buttons');

var _lists = require('../lists');

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _animation_mixin = require('../mixins/mixins/animation_mixin');

var _animation_mixin2 = _interopRequireDefault(_animation_mixin);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var StreamListNewItemsButton = function (_React$PureComponent) {
  (0, _inherits3.default)(StreamListNewItemsButton, _React$PureComponent);

  function StreamListNewItemsButton() {
    (0, _classCallCheck3.default)(this, StreamListNewItemsButton);
    return (0, _possibleConstructorReturn3.default)(this, _React$PureComponent.apply(this, arguments));
  }

  StreamListNewItemsButton.prototype.render = function render() {
    return _react2.default.createElement(
      _buttons.DefaultButton,
      { flat: true, className: 'list-stream-new-items-btn', onClick: this.props.showNewItems },
      this.props.numNewItems + ' ' + (this.props.numNewItems === 1 ? this.props.singularNewItemText : this.props.pluralNewItemsText)
    );
  };

  return StreamListNewItemsButton;
}(_react2.default.PureComponent);

StreamListNewItemsButton.propTypes = {
  showNewItems: _propTypes2.default.func.isRequired,
  singularNewItemText: _propTypes2.default.string,
  pluralNewItemsText: _propTypes2.default.string,
  numNewItems: _propTypes2.default.number.isRequired
};

var StreamList = exports.StreamList = function (_mixin$with) {
  (0, _inherits3.default)(StreamList, _mixin$with);

  function StreamList(props, context) {
    (0, _classCallCheck3.default)(this, StreamList);

    var _this2 = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _initialiseProps.call(_this2);

    _this2.state = { numRenderedItems: _this2.numTotalItems(props) };
    return _this2;
  }

  StreamList.prototype.render = function render() {
    var _this3 = this;

    var _props = this.props,
        children = _props.children,
        singularNewItemText = _props.singularNewItemText,
        pluralNewItemsText = _props.pluralNewItemsText,
        others = (0, _objectWithoutProperties3.default)(_props, ['children', 'singularNewItemText', 'pluralNewItemsText']);

    var updatedChildren = [];
    _react2.default.Children.forEach(children, function (child) {
      if (updatedChildren.length === _this3.state.numRenderedItems) return;
      updatedChildren.unshift(child);
    });
    var newItemsButton = null;
    var height = 0;
    if (this.numNewItems()) {
      var newItemsBtnProps = {
        showNewItems: this.showNewItems,
        singularNewItemText: singularNewItemText,
        pluralNewItemsText: pluralNewItemsText,
        numNewItems: this.numNewItems()
      };
      newItemsButton = _react2.default.createElement(StreamListNewItemsButton, newItemsBtnProps);
      height = this.animate('list-stream-btn-key-' + this.state.numRenderedItems, 45, 150, { startValue: 0 });
      // animating using `numRenderedItems` makes a new animation every time the button appears
    }
    return _react2.default.createElement(
      'div',
      null,
      _react2.default.createElement(
        'div',
        { className: 'list-stream-new-items-btn-wrapper', style: { height: height } },
        newItemsButton
      ),
      _react2.default.createElement(
        _lists.UnorderedList,
        others,
        updatedChildren
      )
    );
  };

  return StreamList;
}((0, _mixins2.default)(_react2.default.Component).with(_animation_mixin2.default));

StreamList.propTypes = {
  singularNewItemText: _propTypes2.default.string.isRequired,
  pluralNewItemsText: _propTypes2.default.string.isRequired
};
StreamList.defaultProps = {
  singularNewItemText: 'new item',
  pluralNewItemsText: 'new items'
};

var _initialiseProps = function _initialiseProps() {
  var _this4 = this;

  this.numTotalItems = function (props) {
    return _react2.default.Children.count(props.children);
  };

  this.numNewItems = function () {
    return _this4.numTotalItems(_this4.props) - _this4.state.numRenderedItems;
  };

  this.showNewItems = function () {
    return _this4.setState({ numRenderedItems: _this4.numTotalItems(_this4.props) });
  };
};

var StreamListItem = exports.StreamListItem = _lists.ListItem;