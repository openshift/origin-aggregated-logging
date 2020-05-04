import { uiModules } from 'ui/modules';
import { get } from 'lodash';
import client from './backend_api/client';
import './directives/directives';

const app = uiModules.get('apps/opendistro_security/configuration', ['ui.ace']);

app.controller('securityConfigurationController', function ($scope, $element, $route, $window, $http, createNotifier, backendAPI) {

    $scope.errorMessage = "";

    $scope.title = "Security";

    $scope.clearCache = function() {
        backendAPI.clearCache();
    }

});
