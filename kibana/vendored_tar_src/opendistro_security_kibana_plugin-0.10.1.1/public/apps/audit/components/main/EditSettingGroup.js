import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import {
  EuiCodeBlock,
  EuiComboBox,
  EuiDescribedFormGroup,
  EuiFormRow,
  EuiIcon,
  EuiLink,
  EuiSpacer,
  EuiSwitch,
  EuiText,
  EuiTextColor,
  EuiTitle,
} from '@elastic/eui';
import { get } from 'lodash';
import {
  displayBoolean,
  displayLabel,
  generateComboBoxLabels,
  removeComboBoxLabels,
  filterReadonly,
} from './utils';
import EditorBox from './EditorBox';

function EditSettingGroup({ settingGroup, config, handleChange, handleInvalid, readonly }) {
  const renderField = (config, setting, handleChange, handleInvalid) => {
    const val = get(config, setting.path);
    if (setting.type === 'bool') {
      return (
        <EuiSwitch
          label={displayBoolean(val)}
          checked={val}
          onChange={e => {
            handleChange(setting, e.target.checked);
          }}
        />
      );
    } else if (setting.type === 'array' && typeof setting.options !== 'undefined') {
      return (
        <EuiComboBox
          placeholder={setting.title}
          options={generateComboBoxLabels(setting.options)}
          selectedOptions={generateComboBoxLabels(val)}
          onChange={selectedOptions => {
            handleChange(setting, removeComboBoxLabels(selectedOptions));
          }}
        />
      );
    } else if (setting.type === 'array') {
      return (
        <EuiComboBox
          noSuggestions
          placeholder={setting.title}
          selectedOptions={generateComboBoxLabels(val)}
          onChange={selectedOptions => {
            handleChange(setting, removeComboBoxLabels(selectedOptions));
          }}
          onCreateOption={searchValue => {
            handleChange(setting, [...val, searchValue]);
          }}
        />
      );
    } else if (setting.type === 'map') {
      return (
        <EditorBox
          config={config}
          handleChange={handleChange}
          handleInvalid={handleInvalid}
          setting={setting}
        />
      );
    } else if (setting.type === 'text') {
      return (
        <EuiText color="subdued" size="s">
          <EuiTextColor color="subdued">
            <p>
              {setting.content}
              <EuiLink href={setting.url}>
                Learn more
                <EuiIcon type="popout" />
              </EuiLink>
            </p>
          </EuiTextColor>
        </EuiText>
      );
    } else {
      return <Fragment />;
    }
  };

  const renderCodeBlock = setting => {
    return (
      <Fragment>
        <EuiCodeBlock paddingSize="none" style={{opacity: 0.6}} isCopyable>
          {setting.code}
        </EuiCodeBlock>
      </Fragment>
    );
  };

  const settingGroupFiltered = filterReadonly(readonly, settingGroup);
  const renderedSettings =
    settingGroupFiltered.settings.length != 0 ? (
      <Fragment>
        {settingGroupFiltered.title && (
          <Fragment>
            <EuiTitle>
              <h3>{settingGroupFiltered.title}</h3>
            </EuiTitle>
            <EuiSpacer />
          </Fragment>
        )}
        {settingGroupFiltered.settings.map(setting => {
          return (
            <Fragment key={setting.path}>
              <EuiDescribedFormGroup
                title={<h3>{setting.title}</h3>}
                description={
                  <Fragment>
                    {setting.description}
                    {setting.code && renderCodeBlock(setting)}
                  </Fragment>
                }
                fullWidth
              >
                <EuiFormRow label={setting.hideLabel ? null : displayLabel(setting.path)} helpText={setting.helpText}>
                  {renderField(config, setting, handleChange, handleInvalid)}
                </EuiFormRow>
              </EuiDescribedFormGroup>
            </Fragment>
          );
        })}
      </Fragment>
    ) : null;

  return renderedSettings ? (
    <Fragment>
      {renderedSettings}
      <EuiSpacer size="m"/>
    </Fragment>
  ) : null;
}

EditSettingGroup.propTypes = {
  settingGroup: PropTypes.object,
  config: PropTypes.object,
  handleChange: PropTypes.func,
  handleInvalid: PropTypes.func,
  readonly: PropTypes.array,
};

export default EditSettingGroup;
