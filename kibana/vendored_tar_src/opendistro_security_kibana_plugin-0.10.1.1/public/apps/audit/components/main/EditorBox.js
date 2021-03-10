import React, { Component, Fragment } from 'react';
import PropTypes from 'prop-types';
import { EuiCodeEditor, EuiText, EuiTextColor } from '@elastic/eui';
import { get } from 'lodash';

import 'brace/theme/textmate';
import 'brace/mode/json';

class EditorBox extends Component {
  constructor(props) {
    super(props);
    this.state = {
      invalid: false,
      value: JSON.stringify(get(props.config, props.setting.path), null, 2),
    };
  }

  onChange = text => {
    const { setting, handleChange, handleInvalid } = this.props;
    this.setState({ value: text });
    try {
      let parsed = JSON.parse(text);
      handleChange(setting, parsed);
      handleInvalid(setting.path, false);
      this.setState({ invalid: false });
    } catch (e) {
      this.setState({ invalid: true });
      handleInvalid(setting.path, true);
    }
  };

  render() {
    const { value, invalid } = this.state;
    const { setting } = this.props;
    return (
      <Fragment>
        <EuiCodeEditor
          mode="json"
          theme="textmate"
          width="100%"
          height="auto"
          showGutter={false}
          minLines={5}
          maxLines={25}
          setOptions={{
            showLineNumbers: false,
            tabSize: 2,
          }}
          value={value}
          onChange={this.onChange}
        />
        {invalid && (
          <EuiText size="s">
            <EuiTextColor color="danger">
              <small>{setting.error}</small>
            </EuiTextColor>
          </EuiText>
        )}
      </Fragment>
    );
  }
}

EditorBox.propTypes = {
  setting: PropTypes.object,
  config: PropTypes.object,
  handleChange: PropTypes.func,
  handleInvalid: PropTypes.func,
};

export default EditorBox;
