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
import { UiSettingsApi } from './ui_settings_api';
import { UiSettingsClient } from './ui_settings_client';
import { i18n } from '@kbn/i18n';
var UiSettingsService = /** @class */ (function () {
    function UiSettingsService() {
    }
    UiSettingsService.prototype.start = function (_a) {
        var notifications = _a.notifications, loadingCount = _a.loadingCount, injectedMetadata = _a.injectedMetadata, basePath = _a.basePath;
        this.uiSettingsApi = new UiSettingsApi(basePath, injectedMetadata.getKibanaVersion());
        loadingCount.add(this.uiSettingsApi.getLoadingCount$());
        // TODO: Migrate away from legacyMetadata https://github.com/elastic/kibana/issues/22779
        var legacyMetadata = injectedMetadata.getLegacyMetadata();
        this.uiSettingsClient = new UiSettingsClient({
            api: this.uiSettingsApi,
            onUpdateError: function (error) {
                notifications.toasts.addDanger({
                    title: i18n.translate('core.uiSettings.unableUpdateUISettingNotificationMessageTitle', {
                        defaultMessage: 'Unable to update UI setting',
                    }),
                    text: error.message,
                });
            },
            defaults: legacyMetadata.uiSettings.defaults,
            initialSettings: legacyMetadata.uiSettings.user,
        });
        return this.uiSettingsClient;
    };
    UiSettingsService.prototype.stop = function () {
        if (this.uiSettingsClient) {
            this.uiSettingsClient.stop();
        }
        if (this.uiSettingsApi) {
            this.uiSettingsApi.stop();
        }
    };
    return UiSettingsService;
}());
export { UiSettingsService };
