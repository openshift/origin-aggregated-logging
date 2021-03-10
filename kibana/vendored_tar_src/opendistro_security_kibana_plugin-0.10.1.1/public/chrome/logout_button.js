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

uiModules
.get('kibana')
.directive('securityLogoutButton', function (securityAccessControl) {
  return {
    template: require('plugins/opendistro_security/chrome/logout_button.html'),
    replace: true,
    restrict: 'E',
    link: ($scope) => {
      $scope.logout = () => securityAccessControl.logout();

        let chromeInjected = chrome.getInjected();

        $scope.logoutButtonLabel = 'Logout';
        $scope.logoutTooltip = 'Logout';

        if (chromeInjected && chromeInjected.securityDynamic && chromeInjected.securityDynamic.user) {
            if (!chromeInjected.securityDynamic.user.isAnonymousAuth) {
                $scope.logoutButtonLabel = chromeInjected.securityDynamic.user.username;
                $scope.logoutTooltip = 'Logout ' + chromeInjected.securityDynamic.user.username;
            } else {
                $scope.logoutButtonLabel = 'Login';
                $scope.logoutTooltip = 'Login';
            }
        }
    }
  };
});
