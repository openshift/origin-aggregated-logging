/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Autocomplete = undefined;

var _from = require('babel-runtime/core-js/array/from');

var _from2 = _interopRequireDefault(_from);

var _keys = require('babel-runtime/core-js/object/keys');

var _keys2 = _interopRequireDefault(_keys);

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

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

var _promise = require('babel-runtime/core-js/promise');

var _promise2 = _interopRequireDefault(_promise);

var _autocompleteList = require('./autocomplete-list');

var _autocompleteInput = require('./autocomplete-input');

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _puiCursor = require('pui-cursor');

var _puiCursor2 = _interopRequireDefault(_puiCursor);

var _from3 = require('from');

var _from4 = _interopRequireDefault(_from3);

var _mixins = require('../mixins');

var _mixins2 = _interopRequireDefault(_mixins);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _scrollIntoView = require('scroll-into-view');

var _scrollIntoView2 = _interopRequireDefault(_scrollIntoView);

var _scrim_mixin = require('../mixins/mixins/scrim_mixin');

var _scrim_mixin2 = _interopRequireDefault(_scrim_mixin);

var _through = require('through');

var _through2 = _interopRequireDefault(_through);

var _trieSearch = require('trie-search');

var _trieSearch2 = _interopRequireDefault(_trieSearch);

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var trieFromSearchableItems = function trieFromSearchableItems(searchableItems, trieOptions) {
  return new _promise2.default(function (resolve) {
    var trie = void 0;
    (0, _from4.default)(function (count, callback) {
      if (searchableItems && count >= searchableItems.length) this.emit('end');
      this.emit('data', searchableItems[count]);
      callback();
    }).pipe((0, _through2.default)(function (value) {
      if ((typeof value === 'undefined' ? 'undefined' : (0, _typeof3.default)(value)) === 'object') {
        if (!trie) trie = new _trieSearch2.default(null, trieOptions);
        trie.addFromObject(value);
        resolve(trie);
        return;
      }
      if (!trie) trie = new _trieSearch2.default('value', trieOptions);
      trie.add({ value: value });
      resolve(trie);
    }));
  });
};

var Autocomplete = exports.Autocomplete = function (_mixin$with) {
  (0, _inherits3.default)(Autocomplete, _mixin$with);

  function Autocomplete(props, context) {
    (0, _classCallCheck3.default)(this, Autocomplete);

    var _this = (0, _possibleConstructorReturn3.default)(this, _mixin$with.call(this, props, context));

    _initialiseProps.call(_this);

    var value = _this.props.value || '';
    _this.state = { hidden: true, highlightedSuggestion: 0, suggestedValues: [], trie: null, value: value };
    return _this;
  }

  Autocomplete.prototype.componentWillReceiveProps = function componentWillReceiveProps(_ref) {
    var value = _ref.value;

    if (value !== this.props.value) {
      this.setState({ value: value });
    }
  };

  Autocomplete.prototype.componentDidMount = function componentDidMount() {
    var _this2 = this;

    _mixin$with.prototype.componentDidMount.call(this);
    require('../../css/autocomplete');
    this.props.onInitializeItems(function () {
      var searchableItems = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : [];

      trieFromSearchableItems(searchableItems, _this2.props.trieOptions).then(function (trie) {
        _this2.setState({ searchableItems: searchableItems, trie: trie });
      });
    });
  };

  Autocomplete.prototype.render = function render() {
    var _this3 = this;

    var $autocomplete = new _puiCursor2.default(this.state, function (state) {
      return _this3.setState(state);
    });
    var _props = this.props,
        className = _props.className,
        maxItems = _props.maxItems,
        onFocus = _props.onFocus,
        onClick = _props.onClick,
        disabled = _props.disabled,
        selectedSuggestion = _props.selectedSuggestion,
        placeholder = _props.placeholder,
        input = _props.input,
        children = _props.children,
        __IGNORE1 = _props.onInitializeItems,
        __IGNORE2 = _props.onFilter,
        __IGNORE3 = _props.onPick,
        __IGNORE4 = _props.onSearch,
        __IGNORE5 = _props.trieOptions,
        showNoSearchResults = _props.showNoSearchResults,
        props = (0, _objectWithoutProperties3.default)(_props, ['className', 'maxItems', 'onFocus', 'onClick', 'disabled', 'selectedSuggestion', 'placeholder', 'input', 'children', 'onInitializeItems', 'onFilter', 'onPick', 'onSearch', 'trieOptions', 'showNoSearchResults']);
    var scrollIntoViewFn = this.scrollIntoViewFn,
        onPick = this.onPick,
        onSearch = this.onSearch;

    var clonedInput = _react2.default.cloneElement(input, { $autocomplete: $autocomplete, onPick: onPick, scrollIntoView: scrollIntoViewFn, onSearch: onSearch, disabled: disabled, onFocus: onFocus, onClick: onClick, placeholder: placeholder });

    return _react2.default.createElement(
      'div',
      (0, _extends3.default)({ className: (0, _classnames2.default)('autocomplete', className), ref: function ref(_ref2) {
          return _this3.autocomplete = _ref2;
        } }, props),
      clonedInput,
      _react2.default.createElement(
        _autocompleteList.AutocompleteList,
        { $autocomplete: $autocomplete, onPick: onPick, maxItems: maxItems, selectedSuggestion: selectedSuggestion, showNoSearchResults: showNoSearchResults },
        children
      )
    );
  };

  return Autocomplete;
}((0, _mixins2.default)(_react2.default.Component).with(_scrim_mixin2.default));

Autocomplete.propTypes = {
  className: _propTypes2.default.string,
  disabled: _propTypes2.default.bool,
  input: _propTypes2.default.object,
  maxItems: _propTypes2.default.number,
  onClick: _propTypes2.default.func,
  onFilter: _propTypes2.default.func,
  onFocus: _propTypes2.default.func,
  onInitializeItems: _propTypes2.default.func,
  onPick: _propTypes2.default.func,
  onSearch: _propTypes2.default.func,
  placeholder: _propTypes2.default.string,
  selectedSuggestion: _propTypes2.default.any,
  trieOptions: _propTypes2.default.object,
  value: _propTypes2.default.string,
  showNoSearchResults: _propTypes2.default.bool
};
Autocomplete.defaultProps = {
  maxItems: 50,
  onInitializeItems: function onInitializeItems(done) {
    return done([]);
  },
  input: _react2.default.createElement(_autocompleteInput.AutocompleteInput, null),
  placeholder: 'Search',
  showNoSearchResults: false
};

var _initialiseProps = function _initialiseProps() {
  var _this4 = this;

  this.searchItemsInOrder = function () {
    var searchableItems = _this4.state.searchableItems;

    if (searchableItems.every(function (item) {
      return typeof item === 'string';
    })) return searchableItems.map(function (value) {
      return { value: value };
    });

    return searchableItems.map(function (item) {
      var key = (0, _keys2.default)(item)[0];
      return { _key_: key, value: item[key] };
    });
  };

  this.onSearch = function (value, callback) {
    if (_this4.props.onSearch) return _this4.props.onSearch(value, callback);
    var maxItems = _this4.props.maxItems;
    var trie = _this4.state.trie;

    if (!trie) return callback([]);
    value = value.trim();
    var result = value ? trie.get(value) : _this4.searchItemsInOrder();

    if (_this4.props.onFilter) {
      result = _this4.props.onFilter(result);
    }
    callback(result.slice(0, maxItems));
  };

  this.showList = function () {
    var defaultValue = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;

    var value = defaultValue === null ? _this4.state.value : defaultValue;
    _this4.onSearch(value, function (suggestedValues) {
      _this4.setState({ hidden: false, suggestedValues: suggestedValues });
    });
  };

  this.onPick = function (value) {
    _this4.props.onPick && _this4.props.onPick(value);
    _this4.hideList();
  };

  this.scrollIntoViewFn = function () {
    if (!_this4.autocomplete) return;
    (0, _from2.default)(_this4.autocomplete.querySelectorAll('.highlighted')).map(function (el) {
      return (0, _scrollIntoView2.default)(el, { validTarget: function validTarget(target) {
          return target !== window;
        } });
    });
  };

  this.hideList = function () {
    _this4.setState({ hidden: true });
  };

  this.scrimClick = function () {
    _this4.hideList();
  };
};