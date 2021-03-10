import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import {
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiHorizontalRule,
  EuiPanel,
  EuiTitle,
} from '@elastic/eui';

const ContentPanel = ({ title, children, configureHandler }) => (
  <Fragment>
    <EuiPanel paddingSize="none">
      <div style={{ padding: 20, paddingBottom: 12 }}>
        <EuiFlexGroup>
          <EuiFlexItem>
            <EuiTitle>
              <h3>{title}</h3>
            </EuiTitle>
          </EuiFlexItem>
          {typeof configureHandler == 'function' && (
            <EuiFlexItem grow={false}>
              <EuiButton onClick={configureHandler}>Configure</EuiButton>
            </EuiFlexItem>
          )}
        </EuiFlexGroup>
      </div>
      <EuiHorizontalRule margin="xs" />
      <div style={{ padding: 24, paddingBottom: 0 }}>{children}</div>
    </EuiPanel>
  </Fragment>
);

ContentPanel.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node,
  configureHandler: PropTypes.func,
};

export default ContentPanel;
