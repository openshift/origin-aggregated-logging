/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.AutocompleteInput = undefined;

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

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

var DOWN_KEY = 40;
var ENTER_KEY = 13;
var ESC_KEY = 27;
var TAB_KEY = 9;
var UP_KEY = 38;

var AutocompleteInput = exports.AutocompleteInput = function (_React$Component) {
  (0, _inherits3.default)(AutocompleteInput, _React$Component);

  function AutocompleteInput() {
    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, AutocompleteInput);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call.apply(_React$Component, [this].concat(args))), _this), _this.change = function (e) {
      var value = e.currentTarget.value;

      _this.props.onSearch(value, function (suggestedValues) {
        _this.props.$autocomplete.merge({ hidden: false, highlightedSuggestion: 0, value: value, suggestedValues: suggestedValues }).flush();
      });
    }, _this.keyDown = function (e) {
      var _keyCodes;

      var keyCode = e.keyCode;

      var _this$props$$autocomp = _this.props.$autocomplete.get(),
          highlightedSuggestion = _this$props$$autocomp.highlightedSuggestion,
          suggestedValues = _this$props$$autocomp.suggestedValues;

      var _this$props$onPicking = _this.props.onPicking,
          onPicking = _this$props$onPicking === undefined ? function () {
        return suggestedValues;
      } : _this$props$onPicking;


      var pickItem = function pickItem() {
        var selectableSuggestions = onPicking(suggestedValues);
        e && keyCode === ENTER_KEY && e.preventDefault();
        _this.props.$autocomplete.merge({ highlightedSuggestion: -1, hidden: true }).flush();
        _this.props.onPick(selectableSuggestions[highlightedSuggestion] || { value: _this.props.$autocomplete.get('value') });
      };

      var keyCodes = (_keyCodes = {}, _keyCodes[DOWN_KEY] = function () {
        var selectableSuggestions = onPicking(suggestedValues);
        _this.props.$autocomplete.merge({
          hidden: false,
          highlightedSuggestion: Math.min(highlightedSuggestion + 1, selectableSuggestions.length - 1)
        });
        _this.props.scrollIntoView();
      }, _keyCodes[UP_KEY] = function () {
        _this.props.$autocomplete.merge({ highlightedSuggestion: Math.max(highlightedSuggestion - 1, -1) });
        _this.props.scrollIntoView();
      }, _keyCodes[TAB_KEY] = pickItem, _keyCodes[ENTER_KEY] = pickItem, _keyCodes[ESC_KEY] = function () {
        _this.props.$autocomplete.merge({ highlightedSuggestion: -1, hidden: true });
      }, _keyCodes.noop = function noop() {}, _keyCodes);

      keyCodes[keyCode in keyCodes ? keyCode : 'noop']();
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  AutocompleteInput.prototype.componentDidMount = function componentDidMount() {
    require('../../css/inputs');
    require('../../css/forms');
  };

  AutocompleteInput.prototype.renderDefault = function renderDefault(props) {
    return _react2.default.createElement('input', (0, _extends3.default)({}, props, { className: (0, _classnames2.default)('autocomplete-input', 'form-control', props.className), type: 'search',
      value: props.value, 'aria-label': props.placeholder }));
  };

  AutocompleteInput.prototype.render = function render() {
    var _props = this.props,
        autoFocus = _props.autoFocus,
        children = _props.children,
        $autocomplete = _props.$autocomplete,
        onPick = _props.onPick,
        onPicking = _props.onPicking,
        onSearch = _props.onSearch,
        scrollIntoView = _props.scrollIntoView,
        props = (0, _objectWithoutProperties3.default)(_props, ['autoFocus', 'children', '$autocomplete', 'onPick', 'onPicking', 'onSearch', 'scrollIntoView']);

    if (!$autocomplete) return null;

    var _$autocomplete$get = $autocomplete.get(),
        value = _$autocomplete$get.value;

    var otherProps = { autoFocus: autoFocus, value: value, onChange: this.change, onKeyDown: this.keyDown };
    props = (0, _extends3.default)({}, props, otherProps);
    if (!children) return this.renderDefault(props);
    children = _react2.default.Children.map(children, function (e) {
      return _react2.default.cloneElement(e, props);
    });

    return _react2.default.createElement(
      'div',
      null,
      children
    );
  };

  return AutocompleteInput;
}(_react2.default.Component);

AutocompleteInput.propTypes = {
  $autocomplete: _propTypes2.default.object,
  autoFocus: _propTypes2.default.bool,
  children: function children(props, name) {
    if (props[name] && props[name].length) return new Error('AutocompleteInput can only wrap one element');
  },

  disabled: _propTypes2.default.bool,
  onClick: _propTypes2.default.func,
  onFocus: _propTypes2.default.func,
  onPick: _propTypes2.default.func,
  onPicking: _propTypes2.default.func,
  onSearch: _propTypes2.default.func,
  scrollIntoView: _propTypes2.default.func
};
AutocompleteInput.defaultProps = {
  autoFocus: null
};
AutocompleteInput.DOWN_KEY = DOWN_KEY;
AutocompleteInput.ENTER_KEY = ENTER_KEY;
AutocompleteInput.ESC_KEY = ESC_KEY;
AutocompleteInput.TAB_KEY = TAB_KEY;
AutocompleteInput.UP_KEY = UP_KEY;