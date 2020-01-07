"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
var _a;
"use strict";
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
const empty_states_1 = require("../empty_states");
const loading_1 = require("../loading");
const section_1 = require("./section");
exports.Metrics = react_1.injectI18n((_a = class extends react_2.default.PureComponent {
        constructor() {
            super(...arguments);
            this.state = {
                crosshairValue: null,
            };
            this.handleRefetch = () => {
                this.props.refetch();
            };
            this.renderLayout = (layout) => {
                return (react_2.default.createElement(react_2.default.Fragment, { key: layout.id },
                    react_2.default.createElement(eui_1.EuiPageContentBody, null,
                        react_2.default.createElement(eui_1.EuiTitle, { size: "m" },
                            react_2.default.createElement("h2", { id: layout.id },
                                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.infra.metrics.layoutLabelOverviewTitle", defaultMessage: "{layoutLabel} Overview", values: {
                                        layoutLabel: layout.label,
                                    } })))),
                    layout.sections.map(this.renderSection(layout))));
            };
            this.renderSection = (layout) => (section) => {
                let sectionProps = {};
                if (section.type === 'chart') {
                    const { onChangeRangeTime, isLiveStreaming, stopLiveStreaming } = this.props;
                    sectionProps = {
                        onChangeRangeTime,
                        isLiveStreaming,
                        stopLiveStreaming,
                        crosshairValue: this.state.crosshairValue,
                        onCrosshairUpdate: this.onCrosshairUpdate,
                    };
                }
                return (react_2.default.createElement(section_1.Section, Object.assign({ section: section, metrics: this.props.metrics, key: `${layout.id}-${section.id}` }, sectionProps)));
            };
            this.onCrosshairUpdate = (crosshairValue) => {
                this.setState({
                    crosshairValue,
                });
            };
        }
        render() {
            const { intl } = this.props;
            if (this.props.loading) {
                return (react_2.default.createElement(loading_1.InfraLoadingPanel, { height: "100vh", width: "auto", text: intl.formatMessage({
                        id: 'xpack.infra.metrics.loadingNodeDataText',
                        defaultMessage: 'Loading data',
                    }) }));
            }
            else if (!this.props.loading && this.props.metrics && this.props.metrics.length === 0) {
                return (react_2.default.createElement(empty_states_1.NoData, { titleText: intl.formatMessage({
                        id: 'xpack.infra.metrics.emptyViewTitle',
                        defaultMessage: 'There is no data to display.',
                    }), bodyText: intl.formatMessage({
                        id: 'xpack.infra.metrics.emptyViewDescription',
                        defaultMessage: 'Try adjusting your time or filter.',
                    }), refetchText: intl.formatMessage({
                        id: 'xpack.infra.metrics.refetchButtonLabel',
                        defaultMessage: 'Check for new data',
                    }), onRefetch: this.handleRefetch, testString: "metricsEmptyViewState" }));
            }
            return react_2.default.createElement(react_2.default.Fragment, null, this.props.layouts.map(this.renderLayout));
        }
    },
    _a.displayName = 'Metrics',
    _a));
