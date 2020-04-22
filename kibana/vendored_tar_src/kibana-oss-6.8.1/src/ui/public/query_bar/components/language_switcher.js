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
import * as tslib_1 from "tslib";
import { EuiButtonEmpty, EuiForm, EuiFormRow, EuiHorizontalRule, EuiLink, EuiPopover, EuiPopoverTitle, EuiSpacer, EuiSwitch, EuiText, } from '@elastic/eui';
import { FormattedMessage } from '@kbn/i18n/react';
import React, { Component } from 'react';
import { documentationLinks } from '../../documentation_links/documentation_links';
var luceneQuerySyntaxDocs = documentationLinks.query.luceneQuerySyntax;
var kueryQuerySyntaxDocs = documentationLinks.query.kueryQuerySyntax;
var QueryLanguageSwitcher = /** @class */ (function (_super) {
    tslib_1.__extends(QueryLanguageSwitcher, _super);
    function QueryLanguageSwitcher() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.state = {
            isPopoverOpen: false,
        };
        _this.togglePopover = function () {
            _this.setState({
                isPopoverOpen: !_this.state.isPopoverOpen,
            });
        };
        _this.closePopover = function () {
            _this.setState({
                isPopoverOpen: false,
            });
        };
        _this.onSwitchChange = function () {
            var newLanguage = _this.props.language === 'lucene' ? 'kuery' : 'lucene';
            _this.props.onSelectLanguage(newLanguage);
        };
        return _this;
    }
    QueryLanguageSwitcher.prototype.render = function () {
        var button = (React.createElement(EuiButtonEmpty, { size: "xs", onClick: this.togglePopover },
            React.createElement(FormattedMessage, { id: "common.ui.queryBar.optionsButtonLabel", defaultMessage: "Options" })));
        return (React.createElement(EuiPopover, { id: "popover", className: "eui-displayBlock", ownFocus: true, anchorPosition: "downRight", button: button, isOpen: this.state.isPopoverOpen, closePopover: this.closePopover, withTitle: true },
            React.createElement(EuiPopoverTitle, null,
                React.createElement(FormattedMessage, { id: "common.ui.queryBar.syntaxOptionsTitle", defaultMessage: "Syntax options" })),
            React.createElement("div", { style: { width: '350px' } },
                React.createElement(EuiText, null,
                    React.createElement("p", null,
                        React.createElement(FormattedMessage, { id: "common.ui.queryBar.syntaxOptionsDescription", defaultMessage: "Our experimental autocomplete and simple syntax features can help you create your\n                queries. Just start typing and you\u2019ll see matches related to your data. See docs {docsLink}.", values: {
                                docsLink: (React.createElement(EuiLink, { href: kueryQuerySyntaxDocs, target: "_blank" },
                                    React.createElement(FormattedMessage, { id: "common.ui.queryBar.syntaxOptionsDescription.docsLinkText", defaultMessage: "here" }))),
                            } }))),
                React.createElement(EuiSpacer, { size: "m" }),
                React.createElement(EuiForm, null,
                    React.createElement(EuiFormRow, null,
                        React.createElement(EuiSwitch, { id: "queryEnhancementOptIn", name: "popswitch", label: React.createElement(FormattedMessage, { id: "common.ui.queryBar.turnOnQueryFeaturesLabel", defaultMessage: "Turn on query features" }), checked: this.props.language === 'kuery', onChange: this.onSwitchChange, "data-test-subj": "languageToggle" }))),
                React.createElement(EuiHorizontalRule, { margin: "s" }),
                React.createElement(EuiText, { size: "xs" },
                    React.createElement("p", null,
                        React.createElement(FormattedMessage, { id: "common.ui.queryBar.luceneDocsDescription", defaultMessage: "Not ready yet? Find our lucene docs {docsLink}.", values: {
                                docsLink: (React.createElement(EuiLink, { href: luceneQuerySyntaxDocs, target: "_blank" },
                                    React.createElement(FormattedMessage, { id: "common.ui.queryBar.luceneDocsDescription.docsLinkText", defaultMessage: "here" }))),
                            } }))))));
    };
    return QueryLanguageSwitcher;
}(Component));
export { QueryLanguageSwitcher };
