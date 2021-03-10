import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import {
  EuiFlexGrid,
  EuiFlexItem,
  EuiSpacer,
  EuiText,
  EuiTextColor,
  EuiTitle,
} from '@elastic/eui';
import { displaySettingType, filterReadonly } from './utils';
import { get } from 'lodash';

function DisplaySettingGroup({ settingGroup, config, readonly }) {
  const settingGroupFiltered = filterReadonly(readonly, settingGroup);
  const renderedSettings =
    settingGroupFiltered.settings.length != 0 ? (
      <Fragment>
        {settingGroupFiltered.title && (
          <Fragment>
            <EuiTitle size="s">
              <h2>{settingGroupFiltered.title}</h2>
            </EuiTitle>
            <EuiSpacer size="m" />
          </Fragment>
        )}
        <EuiFlexGrid columns={3}>
          {settingGroupFiltered.settings.map(setting => {
            return (
              <Fragment key={setting.path}>
                <EuiFlexItem>
                  <EuiText size="s">
                    <h4>{setting.title}</h4>
                    <p>
                      <EuiTextColor color="subdued">
                        <small>{displaySettingType(setting, get(config, setting.path))}</small>
                      </EuiTextColor>
                    </p>
                  </EuiText>
                </EuiFlexItem>
              </Fragment>
            );
          })}
        </EuiFlexGrid>
      </Fragment>
    ) : null;

  return renderedSettings ? (
    <Fragment>
      {renderedSettings}
      <EuiSpacer />
    </Fragment>
  ) : null;
}

DisplaySettingGroup.propTypes = {
  settingGroup: PropTypes.object,
  config: PropTypes.object,
  readonly: PropTypes.array,
};

export default DisplaySettingGroup;
