/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.TextFilter = undefined;

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

var _flexGrids = require('../flex-grids');

var _iconography = require('../iconography');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-next-line no-unused-vars
var TextFilter = exports.TextFilter = function (_React$Component) {
  (0, _inherits3.default)(TextFilter, _React$Component);

  function TextFilter(props) {
    (0, _classCallCheck3.default)(this, TextFilter);

    var _this = (0, _possibleConstructorReturn3.default)(this, _React$Component.call(this, props));

    _this.state = { filterText: '' };
    _this.onFilterTextChange = _this.onFilterTextChange.bind(_this);
    return _this;
  }

  TextFilter.prototype.componentDidMount = function componentDidMount() {
    require('../../css/text-filter');
  };

  TextFilter.prototype.onFilterTextChange = function onFilterTextChange(_ref) {
    var value = _ref.target.value;

    this.setState({ filterText: value });
  };

  TextFilter.prototype.render = function render() {
    var _props = this.props,
        data = _props.data,
        filter = _props.filter,
        renderFilteredData = _props.renderFilteredData,
        className = _props.className,
        filterPlaceholderText = _props.filterPlaceholderText,
        emptyState = _props.emptyState;
    var filterText = this.state.filterText;

    var filteredData = filter(data, filterText);

    var renderBlock = renderFilteredData(filteredData);
    if (filteredData.length === 0 && !!emptyState) {
      renderBlock = emptyState;
    }

    return _react2.default.createElement(
      'div',
      { className: 'text-filter' },
      _react2.default.createElement(
        _flexGrids.Grid,
        { className: className },
        _react2.default.createElement(
          _flexGrids.FlexCol,
          { className: 'pan', fixed: true, contentAlignment: 'middle' },
          _react2.default.createElement(_iconography.Icon, { src: 'filter_list' })
        ),
        _react2.default.createElement(
          _flexGrids.FlexCol,
          { className: 'pan' },
          _react2.default.createElement('input', { placeholder: filterPlaceholderText, type: 'text', value: filterText, onChange: this.onFilterTextChange })
        ),
        _react2.default.createElement(
          _flexGrids.FlexCol,
          { className: 'pan text-filter-counts', fixed: true, alignment: 'middle' },
          _react2.default.createElement(
            'span',
            { className: 'filtered-count' },
            filteredData.length
          ),
          ' / ',
          _react2.default.createElement(
            'span',
            { className: 'unfiltered-count' },
            data.length
          )
        )
      ),
      renderBlock
    );
  };

  return TextFilter;
}(_react2.default.Component);

TextFilter.propTypes = {
  data: _propTypes2.default.array.isRequired,
  emptyState: _propTypes2.default.node,
  filter: _propTypes2.default.func.isRequired,
  filterPlaceholderText: _propTypes2.default.string,
  renderFilteredData: _propTypes2.default.func.isRequired
};
TextFilter.defaultProps = {
  data: [],
  filter: function filter(data) {
    return data;
  },
  renderFilteredData: function renderFilteredData() {
    return null;
  },
  filterPlaceholderText: 'Filter...'
};