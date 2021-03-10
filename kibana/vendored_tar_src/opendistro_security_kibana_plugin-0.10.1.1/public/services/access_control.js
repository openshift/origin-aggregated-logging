/*
 * Copyright 2015-2018 _floragunn_ GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
/*
 * Portions Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import chrome from 'ui/chrome';
import { uiModules } from 'ui/modules';
import { toastNotifications } from 'ui/notify';

uiModules
.get('kibana')
.service('securityAccessControl', function ($rootScope, $window, $http, $location, createNotifier) {
  const APP_ROOT = `${chrome.getBasePath()}`;
  const API_ROOT = `${APP_ROOT}/api/v1/auth`;

  const authConfig = chrome.getInjected('auth');
  const authType = authConfig.type || null;
  const logoutUrl = authConfig.logout_url || null;

  class SecurityControlService {

    logout() {
        $http.post(`${API_ROOT}/logout`)
        .then(
          (response) => {
            localStorage.clear();
            sessionStorage.clear();
            if (authType && ['openid', 'saml'].indexOf(authType) > -1) {
                if (response.data.redirectURL) {
                    $window.location.href = response.data.redirectURL;
                } else {
                    $window.location.href = `${APP_ROOT}/customerror`;
                }
            } else {
                if (logoutUrl && logoutUrl.length > 0) {
                    $window.location.href = logoutUrl;
            } else {
                $window.location.href = `${APP_ROOT}/login?type=${authType || ''}Logout`;
            }
            }
          },
          (error) =>
          {
              toastNotifications.addDanger({
                  title: 'Unable to log out.',
                  text: error
              });

          }
        );
    }
  }

  return new SecurityControlService();
});
