"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importStar(require("react"));
class SpaceIdentifierUI extends react_2.Component {
    constructor(props) {
        super(props);
        this.textFieldRef = null;
        this.getLabel = () => {
            if (!this.props.editable) {
                return (react_2.default.createElement("p", null,
                    react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.urlIdentifierTitle", defaultMessage: "URL identifier" })));
            }
            const editLinkText = this.state.editing ? (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.stopEditingSpaceNameLinkText", defaultMessage: "[stop editing]" })) : (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.editSpaceLinkText", defaultMessage: "[edit]" }));
            return (react_2.default.createElement("p", null,
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.urlIdentifierLabel", defaultMessage: "URL identifier" }),
                react_2.default.createElement(eui_1.EuiLink, { onClick: this.onEditClick }, editLinkText)));
        };
        this.getHelpText = () => {
            return (react_2.default.createElement("p", null,
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.kibanaURLForEngineeringIdentifierDescription", defaultMessage: "If the identifier is {engineeringIdentifier}, the Kibana URL is{nextLine}\n          {engineeringKibanaUrl}.", values: {
                        engineeringIdentifier: (react_2.default.createElement("strong", null,
                            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.spaceIdentifier.engineeringText", defaultMessage: "engineering" }))),
                        nextLine: react_2.default.createElement("br", null),
                        engineeringKibanaUrl: (react_2.default.createElement(react_2.default.Fragment, null,
                            `https://my-kibana.example`,
                            react_2.default.createElement("strong", null, "/s/engineering/"),
                            "app/kibana")),
                    } })));
        };
        this.onEditClick = () => {
            this.setState({
                editing: !this.state.editing,
            }, () => {
                if (this.textFieldRef && this.state.editing) {
                    this.textFieldRef.focus();
                }
            });
        };
        this.onChange = (e) => {
            if (!this.state.editing) {
                return;
            }
            this.props.onChange(e);
        };
        this.state = {
            editing: false,
        };
    }
    render() {
        const { intl } = this.props;
        const { id = '' } = this.props.space;
        return (react_2.default.createElement(react_2.Fragment, null,
            react_2.default.createElement(eui_1.EuiFormRow, Object.assign({ label: this.getLabel(), helpText: this.getHelpText() }, this.props.validator.validateURLIdentifier(this.props.space), { fullWidth: true }),
                react_2.default.createElement(eui_1.EuiFieldText, { readOnly: !this.state.editing, placeholder: this.state.editing || !this.props.editable
                        ? undefined
                        : intl.formatMessage({
                            id: 'xpack.spaces.management.spaceIdentifier.urlIdentifierGeneratedFromSpaceNameTooltip',
                            defaultMessage: 'The URL identifier is generated from the space name.',
                        }), value: id, onChange: this.onChange, inputRef: ref => (this.textFieldRef = ref), fullWidth: true }))));
    }
}
exports.SpaceIdentifier = react_1.injectI18n(SpaceIdentifierUI);
