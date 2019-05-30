/*(c) Copyright 2015 Pivotal Software, Inc. All Rights Reserved.*/
'use strict';

exports.__esModule = true;
exports.Flag = exports.Media = undefined;

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

var _classnames2 = require('classnames');

var _classnames3 = _interopRequireDefault(_classnames2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var shortSizes = { xsmall: 'xs', small: 'sm', medium: 'md', large: 'lg' };
var charSizes = { small: 's', medium: 'm', large: 'l', xlarge: 'xl' };
var paddingDirection = { left: 'r', right: 'l' };

var Media = exports.Media = function (_React$Component) {
  (0, _inherits3.default)(Media, _React$Component);

  function Media() {
    (0, _classCallCheck3.default)(this, Media);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component.apply(this, arguments));
  }

  Media.prototype.componentDidMount = function componentDidMount() {
    require('../../css/media');
  };

  Media.prototype.render = function render() {
    var _classnames;

    var _props = this.props,
        className = _props.className,
        innerClassName = _props.innerClassName,
        image = _props.image,
        mediaSpacing = _props.mediaSpacing,
        stackSize = _props.stackSize,
        vAlign = _props.vAlign,
        placement = _props.placement,
        children = _props.children,
        other = (0, _objectWithoutProperties3.default)(_props, ['className', 'innerClassName', 'image', 'mediaSpacing', 'stackSize', 'vAlign', 'placement', 'children']);

    var vAlignClass = vAlign && 'media-' + vAlign;
    var classes = (0, _classnames3.default)('media', stackSize && 'media-stackable-' + shortSizes[stackSize], className);
    var bodyClasses = (0, _classnames3.default)('media-body', vAlignClass, innerClassName);
    var mediaClasses = (0, _classnames3.default)('media-' + placement, vAlignClass, (_classnames = {}, _classnames['p' + paddingDirection[placement] + charSizes[mediaSpacing]] = charSizes[mediaSpacing], _classnames));
    var content = [_react2.default.createElement(
      'div',
      { key: 0, className: mediaClasses },
      image
    ), _react2.default.createElement(
      'div',
      { key: 1, className: bodyClasses },
      children
    )];

    if (placement === 'right') content.reverse();

    return _react2.default.createElement(
      'div',
      (0, _extends3.default)({}, other, { className: classes }),
      content
    );
  };

  return Media;
}(_react2.default.Component);

Media.propTypes = {
  image: _propTypes2.default.oneOfType([_propTypes2.default.node, _propTypes2.default.object]).isRequired,
  innerClassName: _propTypes2.default.string,
  mediaSpacing: _propTypes2.default.oneOf(['small', 'medium', 'large', 'xlarge']),
  stackSize: _propTypes2.default.oneOf(['xsmall', 'small', 'medium', 'large']),
  vAlign: _propTypes2.default.oneOf(['middle', 'bottom']),
  placement: _propTypes2.default.oneOf(['left', 'right']),
  className: _propTypes2.default.string
};
Media.defaultProps = {
  placement: 'left'
};

var Flag = exports.Flag = function (_React$Component2) {
  (0, _inherits3.default)(Flag, _React$Component2);

  function Flag() {
    (0, _classCallCheck3.default)(this, Flag);
    return (0, _possibleConstructorReturn3.default)(this, _React$Component2.apply(this, arguments));
  }

  Flag.prototype.componentDidMount = function componentDidMount() {
    require('../../css/media');
  };

  Flag.prototype.render = function render() {
    return _react2.default.createElement(Media, (0, _extends3.default)({}, this.props, { vAlign: 'middle' }));
  };

  return Flag;
}(_react2.default.Component);