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
import uiRoutes from 'ui/routes';
import { uiModules } from 'ui/modules';
import { toastNotifications } from 'ui/notify';
import 'ui/autoload/styles';
import infoTemplate from './accountinfo.html';
import '../configuration/backend_api/account';
import '../configuration/directives/directives'

uiRoutes.enable();

uiRoutes
    .when('/', {
        template: infoTemplate,
        controller: 'accountInfoNavController',
        controllerAs: 'ctrl'
    });

const app = uiModules.get('app/security-accountinfo', []);

app.controller('accountInfoNavController', function ($scope, $http, $window, Private, security_resolvedInfo, backendAccount) {

    $scope.security_user = {}
    $scope.service = backendAccount;
    $scope.resourcelabel = "Account";
    $scope.show_password_box = false;

    this.is_basicauth = chrome.getInjected("auth.type") == 'basicauth';

    $scope.service.fetch($scope.resource)
        .then(
          (response) => {
            $scope.service.postFetch(response);
            $scope.security_user = response.data;
            $scope.show_password_box = this.is_basicauth && $scope.security_user.is_internal_user && !$scope.security_user.is_reserved && !$scope.security_user.is_hidden;
            $scope.resourcename = $scope.security_user.user_name;
          },
          (error) => {
            toastNotifications.addDanger({
                text: error.data.message,
            });
          }
        );
});

app.controller('accountEditController', function ($scope, $element, $route, $location, $routeParams, createNotifier, backendAccount, kbnUrl, securityAccessControl) {
    $scope.service = backendAccount;

    $scope.saveObject = (event) => {
        if (event) {
            event.preventDefault();
        }

        const form = $element.find('form[name="objectForm"]');

        if (form.hasClass('ng-invalid-required')) {
            $scope.errorMessage = 'Please fill in all the required parameters.';
            return;
        }
        if (!form.hasClass('ng-valid')) {
            $scope.errorMessage = 'Please correct all errors and try again.';
            return;
        }

        if ($scope.resource.password !== $scope.resource.password_confirmation) {
            $scope.errorMessage = 'Passwords do not match.';
            return;
        }

        $scope.service.save($scope.resource)
            .then(
                () => { securityAccessControl.logout() },
                (error) => {$scope.errorMessage = error.data.message}
            );

        $scope.errorMessage = null;
    }
});