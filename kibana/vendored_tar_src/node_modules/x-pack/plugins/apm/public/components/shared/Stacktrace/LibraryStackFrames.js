"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = tslib_1.__importStar(require("react"));
const styled_components_1 = tslib_1.__importDefault(require("styled-components"));
const variables_1 = require("../../../style/variables");
// @ts-ignore
const Icons_1 = require("../../shared/Icons");
const Stackframe_1 = require("./Stackframe");
const LibraryFrameToggle = styled_components_1.default.div `
  user-select: none;
`;
class LibraryStackFrames extends react_1.default.Component {
    constructor() {
        super(...arguments);
        this.state = {
            isVisible: this.props.initialVisiblity
        };
        this.onClick = () => {
            this.setState(({ isVisible }) => ({ isVisible: !isVisible }));
        };
    }
    render() {
        const { stackframes, codeLanguage } = this.props;
        const { isVisible } = this.state;
        if (stackframes.length === 0) {
            return null;
        }
        if (stackframes.length === 1) {
            return (react_1.default.createElement(Stackframe_1.Stackframe, { isLibraryFrame: true, codeLanguage: codeLanguage, stackframe: stackframes[0] }));
        }
        return (react_1.default.createElement("div", null,
            react_1.default.createElement(LibraryFrameToggle, null,
                react_1.default.createElement(eui_1.EuiLink, { onClick: this.onClick },
                    react_1.default.createElement(Icons_1.Ellipsis, { horizontal: isVisible, style: { marginRight: variables_1.units.half } }),
                    ' ',
                    i18n_1.i18n.translate('xpack.apm.stacktraceTab.libraryFramesToogleButtonLabel', {
                        defaultMessage: '{stackframesLength} library frames',
                        values: { stackframesLength: stackframes.length }
                    }))),
            react_1.default.createElement("div", null, isVisible && (react_1.default.createElement(react_1.Fragment, null,
                react_1.default.createElement(eui_1.EuiSpacer, { size: "m" }),
                stackframes.map((stackframe, i) => (react_1.default.createElement(Stackframe_1.Stackframe, { key: i, isLibraryFrame: true, codeLanguage: codeLanguage, stackframe: stackframe }))))))));
    }
}
exports.LibraryStackFrames = LibraryStackFrames;
