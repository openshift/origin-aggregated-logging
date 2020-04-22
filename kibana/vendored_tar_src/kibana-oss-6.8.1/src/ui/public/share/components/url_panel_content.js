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
import React, { Component } from 'react';
import { EuiButton, EuiCopy, EuiFlexGroup, EuiFlexItem, EuiForm, EuiFormRow, EuiIconTip, EuiLoadingSpinner, EuiRadioGroup, EuiSwitch, } from '@elastic/eui';
import { format as formatUrl, parse as parseUrl } from 'url';
import { unhashUrl } from '../../state_management/state_hashing';
import { shortenUrl } from '../lib/url_shortener';
import { FormattedMessage, injectI18n } from '@kbn/i18n/react';
// TODO: Remove once EuiIconTip supports "content" prop
var FixedEuiIconTip = EuiIconTip;
var ExportUrlAsType;
(function (ExportUrlAsType) {
    ExportUrlAsType["EXPORT_URL_AS_SAVED_OBJECT"] = "savedObject";
    ExportUrlAsType["EXPORT_URL_AS_SNAPSHOT"] = "snapshot";
})(ExportUrlAsType || (ExportUrlAsType = {}));
var UrlPanelContentUI = /** @class */ (function (_super) {
    tslib_1.__extends(UrlPanelContentUI, _super);
    function UrlPanelContentUI(props) {
        var _this = _super.call(this, props) || this;
        _this.isNotSaved = function () {
            return _this.props.objectId === undefined || _this.props.objectId === '';
        };
        _this.resetUrl = function () {
            if (_this.mounted) {
                _this.shortUrlCache = undefined;
                _this.setState({
                    useShortUrl: false,
                }, _this.setUrl);
            }
        };
        _this.getSavedObjectUrl = function () {
            if (_this.isNotSaved()) {
                return;
            }
            var url = window.location.href;
            // Replace hashes with original RISON values.
            var unhashedUrl = unhashUrl(url, _this.props.getUnhashableStates());
            var parsedUrl = parseUrl(unhashedUrl);
            if (!parsedUrl || !parsedUrl.hash) {
                return;
            }
            // Get the application route, after the hash, and remove the #.
            var parsedAppUrl = parseUrl(parsedUrl.hash.slice(1), true);
            return formatUrl({
                protocol: parsedUrl.protocol,
                auth: parsedUrl.auth,
                host: parsedUrl.host,
                pathname: parsedUrl.pathname,
                hash: formatUrl({
                    pathname: parsedAppUrl.pathname,
                    query: {
                        // Add global state to the URL so that the iframe doesn't just show the time range
                        // default.
                        _g: parsedAppUrl.query._g,
                    },
                }),
            });
        };
        _this.getSnapshotUrl = function () {
            var url = window.location.href;
            // Replace hashes with original RISON values.
            return unhashUrl(url, _this.props.getUnhashableStates());
        };
        _this.makeUrlEmbeddable = function (url) {
            var embedQueryParam = '?embed=true';
            var urlHasQueryString = url.indexOf('?') !== -1;
            if (urlHasQueryString) {
                return url.replace('?', embedQueryParam + "&");
            }
            return "" + url + embedQueryParam;
        };
        _this.makeIframeTag = function (url) {
            if (!url) {
                return;
            }
            var embeddableUrl = _this.makeUrlEmbeddable(url);
            return "<iframe src=\"" + embeddableUrl + "\" height=\"600\" width=\"800\"></iframe>";
        };
        _this.setUrl = function () {
            var url;
            if (_this.state.exportUrlAs === ExportUrlAsType.EXPORT_URL_AS_SAVED_OBJECT) {
                url = _this.getSavedObjectUrl();
            }
            else if (_this.state.useShortUrl) {
                url = _this.shortUrlCache;
            }
            else {
                url = _this.getSnapshotUrl();
            }
            if (_this.props.isEmbedded) {
                url = _this.makeIframeTag(url);
            }
            _this.setState({ url: url });
        };
        _this.handleExportUrlAs = function (optionId) {
            _this.setState({
                exportUrlAs: optionId,
            }, _this.setUrl);
        };
        // TODO: switch evt type to ChangeEvent<HTMLInputElement> once https://github.com/elastic/eui/issues/1134 is resolved
        _this.handleShortUrlChange = function (evt) { return tslib_1.__awaiter(_this, void 0, void 0, function () {
            var isChecked, shortUrl, fetchError_1;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        isChecked = evt.target.checked;
                        if (!isChecked || this.shortUrlCache !== undefined) {
                            this.setState({ useShortUrl: isChecked }, this.setUrl);
                            return [2 /*return*/];
                        }
                        // "Use short URL" is checked but shortUrl has not been generated yet so one needs to be created.
                        this.setState({
                            isCreatingShortUrl: true,
                            shortUrlErrorMsg: undefined,
                        });
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, shortenUrl(this.getSnapshotUrl())];
                    case 2:
                        shortUrl = _a.sent();
                        if (this.mounted) {
                            this.shortUrlCache = shortUrl;
                            this.setState({
                                isCreatingShortUrl: false,
                                useShortUrl: isChecked,
                            }, this.setUrl);
                        }
                        return [3 /*break*/, 4];
                    case 3:
                        fetchError_1 = _a.sent();
                        if (this.mounted) {
                            this.shortUrlCache = undefined;
                            this.setState({
                                useShortUrl: false,
                                isCreatingShortUrl: false,
                                shortUrlErrorMsg: this.props.intl.formatMessage({
                                    id: 'common.ui.share.urlPanel.unableCreateShortUrlErrorMessage',
                                    defaultMessage: 'Unable to create short URL. Error: {errorMessage}',
                                }, {
                                    errorMessage: fetchError_1.message,
                                }),
                            }, this.setUrl);
                        }
                        return [3 /*break*/, 4];
                    case 4: return [2 /*return*/];
                }
            });
        }); };
        _this.renderExportUrlAsOptions = function () {
            var _a, _b;
            return [
                (_a = {
                        id: ExportUrlAsType.EXPORT_URL_AS_SNAPSHOT,
                        label: _this.renderWithIconTip(React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.snapshotLabel", defaultMessage: "Snapshot" }), React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.snapshotDescription", defaultMessage: "Snapshot URLs encode the current state of the {objectType} in the URL itself.\n            Edits to the saved {objectType} won't be visible via this URL.", values: { objectType: _this.props.objectType } }))
                    },
                    _a['data-test-subj'] = 'exportAsSnapshot',
                    _a),
                (_b = {
                        id: ExportUrlAsType.EXPORT_URL_AS_SAVED_OBJECT,
                        disabled: _this.isNotSaved(),
                        label: _this.renderWithIconTip(React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.savedObjectLabel", defaultMessage: "Saved object" }), React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.savedObjectDescription", defaultMessage: "You can share this URL with people to let them load the most recent saved version of this {objectType}.", values: { objectType: _this.props.objectType } }))
                    },
                    _b['data-test-subj'] = 'exportAsSavedObject',
                    _b),
            ];
        };
        _this.renderWithIconTip = function (child, tipContent) {
            return (React.createElement(EuiFlexGroup, { gutterSize: "none" },
                React.createElement(EuiFlexItem, null, child),
                React.createElement(EuiFlexItem, { grow: false },
                    React.createElement(FixedEuiIconTip, { content: tipContent, position: "bottom" }))));
        };
        _this.renderExportAsRadioGroup = function () {
            var generateLinkAsHelp = _this.isNotSaved() ? (React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.canNotShareAsSavedObjectHelpText", defaultMessage: "Can't share as saved object until the {objectType} has been saved.", values: { objectType: _this.props.objectType } })) : (undefined);
            return (React.createElement(EuiFormRow, { label: React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.generateLinkAsLabel", defaultMessage: "Generate the link as" }), helpText: generateLinkAsHelp },
                React.createElement(EuiRadioGroup, { options: _this.renderExportUrlAsOptions(), idSelected: _this.state.exportUrlAs, onChange: _this.handleExportUrlAs })));
        };
        _this.renderShortUrlSwitch = function () {
            if (_this.state.exportUrlAs === ExportUrlAsType.EXPORT_URL_AS_SAVED_OBJECT) {
                return;
            }
            var shortUrlLabel = (React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.shortUrlLabel", defaultMessage: "Short URL" }));
            var switchLabel = _this.state.isCreatingShortUrl ? (React.createElement("span", null,
                React.createElement(EuiLoadingSpinner, { size: "s" }),
                " ",
                shortUrlLabel)) : (shortUrlLabel);
            var switchComponent = (React.createElement(EuiSwitch, { label: switchLabel, checked: _this.state.useShortUrl, onChange: _this.handleShortUrlChange, "data-test-subj": "useShortUrl" }));
            var tipContent = (React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.shortUrlHelpText", defaultMessage: "We recommend sharing shortened snapshot URLs for maximum compatibility.\n        Internet Explorer has URL length restrictions,\n        and some wiki and markup parsers don't do well with the full-length version of the snapshot URL,\n        but the short URL should work great." }));
            return (React.createElement(EuiFormRow, { helpText: _this.state.shortUrlErrorMsg }, _this.renderWithIconTip(switchComponent, tipContent)));
        };
        _this.shortUrlCache = undefined;
        _this.state = {
            exportUrlAs: ExportUrlAsType.EXPORT_URL_AS_SNAPSHOT,
            useShortUrl: false,
            isCreatingShortUrl: false,
            url: '',
        };
        return _this;
    }
    UrlPanelContentUI.prototype.componentWillUnmount = function () {
        window.removeEventListener('hashchange', this.resetUrl);
        this.mounted = false;
    };
    UrlPanelContentUI.prototype.componentDidMount = function () {
        this.mounted = true;
        this.setUrl();
        window.addEventListener('hashchange', this.resetUrl, false);
    };
    UrlPanelContentUI.prototype.render = function () {
        var _this = this;
        return (React.createElement(EuiForm, { className: "sharePanelContent", "data-test-subj": "shareUrlForm" },
            this.renderExportAsRadioGroup(),
            this.renderShortUrlSwitch(),
            React.createElement(EuiCopy, { textToCopy: this.state.url, anchorClassName: "sharePanel__copyAnchor" }, function (copy) { return (React.createElement(EuiFormRow, null,
                React.createElement(EuiButton, { fill: true, onClick: copy, disabled: _this.state.isCreatingShortUrl || _this.state.url === '', "data-share-url": _this.state.url, "data-test-subj": "copyShareUrlButton", size: "s" }, _this.props.isEmbedded ? (React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.copyIframeCodeButtonLabel", defaultMessage: "Copy iFrame code" })) : (React.createElement(FormattedMessage, { id: "common.ui.share.urlPanel.copyLinkButtonLabel", defaultMessage: "Copy link" }))))); })));
    };
    return UrlPanelContentUI;
}(Component));
export var UrlPanelContent = injectI18n(UrlPanelContentUI);
