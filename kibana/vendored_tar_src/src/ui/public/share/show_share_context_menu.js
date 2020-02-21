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
import React from 'react';
import ReactDOM from 'react-dom';
import { ShareContextMenu } from './components/share_context_menu';
import { EuiWrappingPopover } from '@elastic/eui';
import { I18nContext } from 'ui/i18n';
var isOpen = false;
var container = document.createElement('div');
var onClose = function () {
    ReactDOM.unmountComponentAtNode(container);
    isOpen = false;
};
export function showShareContextMenu(_a) {
    var anchorElement = _a.anchorElement, allowEmbed = _a.allowEmbed, getUnhashableStates = _a.getUnhashableStates, objectId = _a.objectId, objectType = _a.objectType, shareContextMenuExtensions = _a.shareContextMenuExtensions, sharingData = _a.sharingData, isDirty = _a.isDirty;
    if (isOpen) {
        onClose();
        return;
    }
    isOpen = true;
    document.body.appendChild(container);
    var element = (React.createElement(I18nContext, null,
        React.createElement(EuiWrappingPopover, { className: "kuiLocalNav__popover", anchorClassName: "kuiLocalNav__popoverAnchor", id: "sharePopover", button: anchorElement, isOpen: true, closePopover: onClose, panelPaddingSize: "none", withTitle: true },
            React.createElement(ShareContextMenu, { allowEmbed: allowEmbed, getUnhashableStates: getUnhashableStates, objectId: objectId, objectType: objectType, shareContextMenuExtensions: shareContextMenuExtensions, sharingData: sharingData, isDirty: isDirty, onClose: onClose }))));
    ReactDOM.render(element, container);
}
