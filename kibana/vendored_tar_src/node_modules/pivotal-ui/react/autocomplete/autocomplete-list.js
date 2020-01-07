/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.AutocompleteList = undefined;

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

var AutocompleteList = exports.AutocompleteList = function (_React$Component) {
  (0, _inherits3.default)(AutocompleteList, _React$Component);

  function AutocompleteList(props, context) {
    (0, _classCallCheck3.default)(this, AutocompleteList);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call(this, props, context));

    _this.onClick = _this.onClick.bind(_this);
    return _this;
  }

  AutocompleteList.prototype.componentDidMount = function componentDidMount() {
    require('../../css/autocomplete');
  };

  AutocompleteList.prototype.onClick = function onClick(value, e) {
    e.preventDefault();
    this.props.onPick(value);
  };

  AutocompleteList.prototype.renderSuggestionList = function renderSuggestionList() {
    var _this2 = this;

    var _props = this.props,
        className = _props.className,
        showNoSearchResults = _props.showNoSearchResults;

    var suggestedValues = this.props.$autocomplete.get('suggestedValues');
    var suggestions = suggestedValues.map(function (suggestion, key) {
      var value = '_key_' in suggestion ? suggestion._key_ : suggestion.value;
      var className = (0, _classnames2.default)('autocomplete-item', { highlighted: key === _this2.props.$autocomplete.get('highlightedSuggestion') }, { selected: value === _this2.props.selectedSuggestion });
      return _react2.default.createElement(
        'li',
        { key: key },
        _react2.default.createElement(
          'a',
          { href: '#', onClick: _this2.onClick.bind(_this2, suggestion), role: 'button', title: value,
            className: className },
          value
        )
      );
    });
    if (!suggestions.length) {
      var result = showNoSearchResults ? _react2.default.createElement(
        'div',
        null,
        _react2.default.createElement(
          'ul',
          null,
          _react2.default.createElement(
            'li',
            { className: 'autocomplete-list autocomplete-item autocomplete-item-no-results' },
            'No search results'
          )
        )
      ) : null;
      return result;
    }
    return _react2.default.createElement(
      'ul',
      { className: (0, _classnames2.default)('autocomplete-list', className) },
      suggestions
    );
  };

  AutocompleteList.prototype.renderDefault = function renderDefault() {
    var _props2 = this.props,
        $autocomplete = _props2.$autocomplete,
        minSearchTerm = _props2.minSearchTerm;

    var _$autocomplete$get = $autocomplete.get(),
        hidden = _$autocomplete$get.hidden,
        value = _$autocomplete$get.value;

    if (hidden || value.length < minSearchTerm) return null;
    return this.renderSuggestionList();
  };

  AutocompleteList.prototype.render = function render() {
    var _this3 = this;

    var _props3 = this.props,
        children = _props3.children,
        $autocomplete = _props3.$autocomplete,
        props = (0, _objectWithoutProperties3.default)(_props3, ['children', '$autocomplete']);

    if (!$autocomplete) return null;
    if (!children) return this.renderDefault();

    var _$autocomplete$get2 = $autocomplete.get(),
        hidden = _$autocomplete$get2.hidden,
        value = _$autocomplete$get2.value,
        highlightedSuggestion = _$autocomplete$get2.highlightedSuggestion,
        suggestedValues = _$autocomplete$get2.suggestedValues;

    if (hidden) return null;

    children = _react2.default.Children.map(children, function (e) {
      return _react2.default.cloneElement(e, (0, _extends3.default)({
        value: value,
        suggestedValues: suggestedValues,
        highlightedSuggestion: highlightedSuggestion,
        onClick: _this3.onClick
      }, props));
    });

    return _react2.default.createElement(
      'div',
      null,
      children
    );
  };

  return AutocompleteList;
}(_react2.default.Component);

AutocompleteList.propTypes = {
  $autocomplete: _propTypes2.default.object,
  children: function children(props, name) {
    if (props[name] && props[name].length) return new Error('AutocompleteList can only wrap one element');
  },

  className: _propTypes2.default.string,
  minSearchTerm: _propTypes2.default.number,
  onPick: _propTypes2.default.func,
  selectedSuggestion: _propTypes2.default.any,
  showNoSearchResults: _propTypes2.default.bool
};
AutocompleteList.defaultProps = {
  minSearchTerm: 0
};