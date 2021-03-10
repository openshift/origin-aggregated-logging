import React, { Fragment, Component } from 'react';
import {
  EuiCallOut,
  EuiPage,
  EuiPageBody,
  EuiPanel,
  EuiSpacer,
  EuiTitle,
  EuiFlexGroup,
  EuiFlexItem,
  EuiButton,
} from '@elastic/eui';
import { toastNotifications } from 'ui/notify';
import { cloneDeep, pull, set } from 'lodash';
import {
  AUDIT_API,
  CONFIG_LABELS,
  SETTING_GROUPS,
  RESPONSE_MESSAGES,
  TOAST_MESSAGES,
} from './config';
import ContentPanel from './ContentPanel';
import DisplaySettingGroup from './DisplaySettingGroup';
import EditSettingGroup from './EditSettingGroup';
import { generateReadonlyPaths } from './utils';

export class Main extends Component {
  constructor(props) {
    super(props);
    this.state = {
      config: null,
      editConfig: null,
      readonly: [],
      showAllSettings: true,
      showConfigureAudit: false,
      showConfigureCompliance: false,
      showError: false,
      invalidSettings: [],
    };
  }

  componentDidMount() {
    this.fetchConfig();
  }

  handleChange = (setting, val) => {
    const editedConfig = set(cloneDeep(this.state.editConfig), setting.path, val);
    this.setState({ editConfig: editedConfig });
  };

  handleChangeWithSave = (setting, val) => {
    const editedConfig = set(cloneDeep(this.state.editConfig), setting.path, val);
    this.saveConfig(editedConfig, false);
  };

  handleInvalid = (key, error) => {
    const invalid = pull([...this.state.invalidSettings], key);
    if (error) {
      invalid.push(key);
    }
    this.setState({ invalidSettings: invalid });
  };

  toggleDisplay = (
    show_all_settings = true,
    show_configure_audit = false,
    show_configure_compliance = false
  ) => {
    this.setState({
      showAllSettings: show_all_settings,
      showConfigureAudit: show_configure_audit,
      showConfigureCompliance: show_configure_compliance,
    });
    window.scrollTo({ top: 0 });
  };

  cancel = () => {
    this.toggleDisplay();
    this.setState({ editConfig: this.state.config, invalidSettings: [] });
  };

  saveConfig = (payload, showToast = true, successMessage = '') => {
    const { httpClient } = this.props;
    httpClient
      .post(AUDIT_API.PUT, payload)
      .then(() => {
        if (showToast) {
          toastNotifications.addSuccess({
            title: 'Success',
            text: successMessage,
          });
        }
        this.toggleDisplay();
        this.fetchConfig();
      })
      .catch(() => {
        toastNotifications.addDanger(RESPONSE_MESSAGES.UPDATE_FAILURE);
      });
  };

  fetchConfig = () => {
    const { httpClient } = this.props;
    httpClient
      .get(AUDIT_API.GET)
      .then(resp => {
        const responseConfig = resp.data.data.config;
        const readonly = generateReadonlyPaths(resp.data.data._readonly);
        this.setState({
          config: responseConfig,
          editConfig: responseConfig,
          readonly: readonly,
          showError: false,
        });
      })
      .catch(() => {
        this.setState({ showError: true });
      });
  };

  renderError = () => {
    const { showError } = this.state;
    return showError ? (
      <EuiCallOut title={RESPONSE_MESSAGES.FETCH_ERROR_TITLE} color="danger" iconType="alert">
        <p>{RESPONSE_MESSAGES.FETCH_ERROR_MESSAGE}</p>
      </EuiCallOut>
    ) : null;
  };

  renderSave = message => {
    const { editConfig, invalidSettings } = this.state;
    return (
      <Fragment>
        <EuiSpacer />
        <EuiFlexGroup justifyContent="flexEnd">
          <EuiFlexItem grow={false}>
            <EuiButton
              onClick={() => {
                this.cancel();
              }}
            >
              Cancel
            </EuiButton>
          </EuiFlexItem>
          <EuiFlexItem grow={false}>
            <EuiButton
              fill
              isDisabled={invalidSettings.length != 0}
              onClick={() => {
                this.saveConfig(editConfig, true, message);
              }}
            >
              Save
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </Fragment>
    );
  };

  renderEditableAuditSettings = () => {
    const { editConfig, readonly } = this.state;
    return (
      <Fragment>
        <EuiTitle size="l">
          <h1>{CONFIG_LABELS.GENERAL_SETTINGS}</h1>
        </EuiTitle>
        <EuiSpacer size="m" />
        <EuiPanel>
          <EditSettingGroup
            settingGroup={SETTING_GROUPS.LAYER_SETTINGS}
            config={editConfig}
            handleChange={this.handleChange}
            readonly={readonly}
          />
          <EditSettingGroup
            settingGroup={SETTING_GROUPS.ATTRIBUTE_SETTINGS}
            config={editConfig}
            handleChange={this.handleChange}
            readonly={readonly}
          />
          <EditSettingGroup
            settingGroup={SETTING_GROUPS.IGNORE_SETTINGS}
            config={editConfig}
            handleChange={this.handleChange}
            readonly={readonly}
          />
        </EuiPanel>
        {this.renderSave(TOAST_MESSAGES.GENERAL_SETTINGS)}
      </Fragment>
    );
  };

  renderEditableComplianceSettings = () => {
    const { editConfig, readonly } = this.state;
    return (
      <Fragment>
        <EuiTitle size="l">
          <h1>{CONFIG_LABELS.COMPLIANCE_SETTINGS}</h1>
        </EuiTitle>
        <EuiSpacer size="m" />
        <EuiPanel>
          <EuiSpacer size="m" />
          <EditSettingGroup
            settingGroup={SETTING_GROUPS.COMPLIANCE_LOGGING_SETTINGS}
            config={editConfig}
            handleChange={this.handleChange}
            readonly={readonly}
          />
          {editConfig.compliance.enabled && (
            <Fragment>
              <EditSettingGroup
                settingGroup={SETTING_GROUPS.COMPLIANCE_CONFIG_SETTINGS}
                config={editConfig}
                handleChange={this.handleChange}
                readonly={readonly}
              ></EditSettingGroup>
              <EditSettingGroup
                settingGroup={SETTING_GROUPS.COMPLIANCE_READ_SETTINGS}
                config={editConfig}
                handleChange={this.handleChange}
                handleInvalid={this.handleInvalid}
                readonly={readonly}
              ></EditSettingGroup>
              <EditSettingGroup
                settingGroup={SETTING_GROUPS.COMPLIANCE_WRITE_SETTINGS}
                config={editConfig}
                handleChange={this.handleChange}
                readonly={readonly}
              ></EditSettingGroup>
            </Fragment>
          )}
        </EuiPanel>
        {this.renderSave(TOAST_MESSAGES.COMPLIANCE_SETTINGS)}
      </Fragment>
    );
  };

  renderAllSettings = () => {
    const { config, editConfig, readonly } = this.state;
    return (
      <Fragment>
        <ContentPanel title={CONFIG_LABELS.AUDIT_LOGGING}>
          <EditSettingGroup
            settingGroup={SETTING_GROUPS.AUDIT_SETTINGS}
            config={editConfig}
            handleChange={this.handleChangeWithSave}
            readonly={readonly}
          />
          <EuiSpacer size="s" />
        </ContentPanel>
        {config.enabled && (
          <Fragment>
            {!readonly.includes('audit') && (
              <Fragment>
                <EuiSpacer />
                <ContentPanel
                  title={CONFIG_LABELS.GENERAL_SETTINGS}
                  configureHandler={() => {
                    this.toggleDisplay(false, true, false);
                  }}
                >
                  <DisplaySettingGroup
                    settingGroup={SETTING_GROUPS.LAYER_SETTINGS}
                    config={config}
                    readonly={readonly}
                  />
                  <DisplaySettingGroup
                    settingGroup={SETTING_GROUPS.ATTRIBUTE_SETTINGS}
                    config={config}
                    readonly={readonly}
                  />
                  <DisplaySettingGroup
                    settingGroup={SETTING_GROUPS.IGNORE_SETTINGS}
                    config={config}
                    readonly={readonly}
                  />
                </ContentPanel>
              </Fragment>
            )}
            {!readonly.includes('compliance') && (
              <Fragment>
                <EuiSpacer />
                <ContentPanel
                  title={CONFIG_LABELS.COMPLIANCE_SETTINGS}
                  configureHandler={() => {
                    this.toggleDisplay(false, false, true);
                  }}
                >
                  <DisplaySettingGroup
                    config={config}
                    settingGroup={SETTING_GROUPS.COMPLIANCE_LOGGING_SETTINGS}
                    readonly={readonly}
                  />
                  <DisplaySettingGroup
                    config={config}
                    settingGroup={SETTING_GROUPS.COMPLIANCE_CONFIG_SETTINGS}
                    readonly={readonly}
                  />
                  <DisplaySettingGroup
                    settingGroup={SETTING_GROUPS.COMPLIANCE_READ_SETTINGS}
                    config={config}
                    readonly={readonly}
                  />
                  <DisplaySettingGroup
                    settingGroup={SETTING_GROUPS.COMPLIANCE_WRITE_SETTINGS}
                    config={config}
                    readonly={readonly}
                  />
                </ContentPanel>
              </Fragment>
            )}
          </Fragment>
        )}
      </Fragment>
    );
  };

  renderBody = () => {
    const {
      config,
      editConfig,
      showAllSettings,
      showConfigureAudit,
      showConfigureCompliance,
    } = this.state;
    return config && editConfig ? (
      <Fragment>
        {showAllSettings && this.renderAllSettings()}
        {showConfigureAudit && this.renderEditableAuditSettings()}
        {showConfigureCompliance && this.renderEditableComplianceSettings()}
      </Fragment>
    ) : null;
  };

  render() {
    return (
      <EuiPage restrictWidth={true} style={{ width: '100%' }}>
        <EuiPageBody>
          {this.renderError()}
          {this.renderBody()}
        </EuiPageBody>
      </EuiPage>
    );
  }
}
