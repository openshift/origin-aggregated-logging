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
import React from 'react';
import { EuiModal, EuiOverlayMask } from '@elastic/eui';
import { VisualizeConstants } from '../visualize_constants';
import { TypeSelection } from './type_selection';
import chrome from 'ui/chrome';
var NewVisModal = /** @class */ (function (_super) {
    tslib_1.__extends(NewVisModal, _super);
    function NewVisModal(props) {
        var _this = _super.call(this, props) || this;
        _this.onVisTypeSelected = function (visType) {
            var baseUrl = visType.requiresSearch && visType.options.showIndexSelection
                ? "#" + VisualizeConstants.WIZARD_STEP_2_PAGE_PATH + "?"
                : "#" + VisualizeConstants.CREATE_PATH + "?";
            var params = tslib_1.__spread(["type=" + encodeURIComponent(visType.name)], _this.props.editorParams);
            _this.props.onClose();
            location.assign("" + baseUrl + params.join('&'));
        };
        _this.isLabsEnabled = chrome.getUiSettingsClient().get('visualize:enableLabs');
        return _this;
    }
    NewVisModal.prototype.render = function () {
        if (!this.props.isOpen) {
            return null;
        }
        return (React.createElement(EuiOverlayMask, null,
            React.createElement(EuiModal, { onClose: this.props.onClose, maxWidth: '100vw', className: "visNewVisDialog" },
                React.createElement(TypeSelection, { showExperimental: this.isLabsEnabled, onVisTypeSelected: this.onVisTypeSelected, visTypesRegistry: this.props.visTypesRegistry }))));
    };
    NewVisModal.defaultProps = {
        editorParams: [],
    };
    return NewVisModal;
}(React.Component));
export { NewVisModal };
