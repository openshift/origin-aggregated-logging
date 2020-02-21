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
import './core.css';
import { BasePathService } from './base_path';
import { ChromeService } from './chrome';
import { FatalErrorsService } from './fatal_errors';
import { I18nService } from './i18n';
import { InjectedMetadataService } from './injected_metadata';
import { LegacyPlatformService } from './legacy_platform';
import { LoadingCountService } from './loading_count';
import { NotificationsService } from './notifications';
import { UiSettingsService } from './ui_settings';
/**
 * The CoreSystem is the root of the new platform, and starts all parts
 * of Kibana in the UI, including the LegacyPlatform which is managed
 * by the LegacyPlatformService. As we migrate more things to the new
 * platform the CoreSystem will get many more Services.
 */
var CoreSystem = /** @class */ (function () {
    function CoreSystem(params) {
        var _this = this;
        var rootDomElement = params.rootDomElement, injectedMetadata = params.injectedMetadata, requireLegacyFiles = params.requireLegacyFiles, useLegacyTestHarness = params.useLegacyTestHarness;
        this.rootDomElement = rootDomElement;
        this.i18n = new I18nService();
        this.injectedMetadata = new InjectedMetadataService({
            injectedMetadata: injectedMetadata,
        });
        this.fatalErrors = new FatalErrorsService({
            rootDomElement: rootDomElement,
            injectedMetadata: this.injectedMetadata,
            stopCoreSystem: function () {
                _this.stop();
            },
        });
        this.notificationsTargetDomElement = document.createElement('div');
        this.notifications = new NotificationsService({
            targetDomElement: this.notificationsTargetDomElement,
        });
        this.loadingCount = new LoadingCountService();
        this.basePath = new BasePathService();
        this.uiSettings = new UiSettingsService();
        this.chrome = new ChromeService();
        this.legacyPlatformTargetDomElement = document.createElement('div');
        this.legacyPlatform = new LegacyPlatformService({
            targetDomElement: this.legacyPlatformTargetDomElement,
            requireLegacyFiles: requireLegacyFiles,
            useLegacyTestHarness: useLegacyTestHarness,
        });
    }
    CoreSystem.prototype.start = function () {
        try {
            // ensure the rootDomElement is empty
            this.rootDomElement.textContent = '';
            this.rootDomElement.classList.add('coreSystemRootDomElement');
            this.rootDomElement.appendChild(this.notificationsTargetDomElement);
            this.rootDomElement.appendChild(this.legacyPlatformTargetDomElement);
            var i18n = this.i18n.start();
            var notifications = this.notifications.start({ i18n: i18n });
            var injectedMetadata = this.injectedMetadata.start();
            var fatalErrors = this.fatalErrors.start({ i18n: i18n });
            var loadingCount = this.loadingCount.start({ fatalErrors: fatalErrors });
            var basePath = this.basePath.start({ injectedMetadata: injectedMetadata });
            var uiSettings = this.uiSettings.start({
                notifications: notifications,
                loadingCount: loadingCount,
                injectedMetadata: injectedMetadata,
                basePath: basePath,
            });
            var chrome = this.chrome.start();
            this.legacyPlatform.start({
                i18n: i18n,
                injectedMetadata: injectedMetadata,
                fatalErrors: fatalErrors,
                notifications: notifications,
                loadingCount: loadingCount,
                basePath: basePath,
                uiSettings: uiSettings,
                chrome: chrome,
            });
            return { fatalErrors: fatalErrors };
        }
        catch (error) {
            this.fatalErrors.add(error);
        }
    };
    CoreSystem.prototype.stop = function () {
        this.legacyPlatform.stop();
        this.notifications.stop();
        this.loadingCount.stop();
        this.uiSettings.stop();
        this.chrome.stop();
        this.i18n.stop();
        this.rootDomElement.textContent = '';
    };
    return CoreSystem;
}());
export { CoreSystem };
