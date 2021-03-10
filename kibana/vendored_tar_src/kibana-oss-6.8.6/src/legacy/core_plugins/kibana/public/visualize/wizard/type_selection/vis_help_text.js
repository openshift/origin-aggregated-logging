/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import { FormattedMessage } from '@kbn/i18n/react';
import React from 'react';
import { EuiSpacer, EuiText, EuiTitle } from '@elastic/eui';
export var VisHelpText = function (_a) {
    var visType = _a.visType;
    return (React.createElement(React.Fragment, null,
        React.createElement(EuiTitle, { size: "s" },
            React.createElement("h2", null, visType.title)),
        React.createElement(EuiSpacer, { size: "s" }),
        React.createElement("div", { id: "visTypeDescription-" + visType.name },
            visType.stage === 'experimental' && (React.createElement(React.Fragment, null,
                React.createElement(EuiText, null,
                    React.createElement("em", null,
                        React.createElement(FormattedMessage, { id: "kbn.visualize.newVisWizard.experimentalDescription", defaultMessage: "This visualization is experimental. The design and implementation\n                    are less mature than stable visualizations and might be subject to change." }))),
                React.createElement(EuiSpacer, { size: "s" }))),
            React.createElement(EuiText, null, visType.description))));
};
