import { uiModules } from 'ui/modules'
import { get } from 'lodash';
import { forEach } from 'lodash';
import client from '../../backend_api/securityconfiguration';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.controller('securityConfigController', function ($scope, $element, $route, createNotifier, securityConfiguration, kbnUrl) {

    $scope.endpoint = "SECURITYCONFIG";

    $scope.service = securityConfiguration;
    $scope.sortedAuthc = [];
    $scope.sortedAuthz = [];
    $scope.resource = {};

    $scope.title = "Authentication / Authorization configuration";
    $scope.service.list().then(function (response) {
        $scope.resource = $scope.service.postFetch(response.data);
        forEach(response.data.opendistro_security.dynamic.authc, function(value, key) {
            value["name"] = key;
            $scope.sortedAuthc.push(value);
        });

        forEach(response.data.opendistro_security.dynamic.authz, function(value, key) {
            value["name"] = key;
            $scope.sortedAuthz.push(value);
        });

        $scope.sortedAuthc = $scope.sortedAuthc.sort(function(a, b) {
            return a.order - b.order;
        });

        $scope.sortedAuthz = $scope.sortedAuthz.sort(function(a, b) {
            return a.order - b.order;
        });

    });

    $scope.authctitle = function(authc)  {
        var title = authc.order + ": " + authc.name;
        var enabled = $scope.authczEnabled(authc);
        if(!enabled) {
            title += " (disabled)";
        }
        return title;
    }

    $scope.authcclass = function(authc)  {
        var enabled = $scope.authczEnabled(authc);
        if(!enabled) {
            return "authc-disabled";
        }
    }

    $scope.authztitle = function(authz)  {
        var title = authz.name;
        var enabled = $scope.authczEnabled(authz);
        if(!enabled) {
            title += " (disabled)";
        }
        return title;
    }

    $scope.authzlass = function(authz)  {
        var enabled = $scope.authczEnabled(authz);
        if(!enabled) {
            return "authc-disabled";
        }
    }

    $scope.authczEnabled = function(authcz)  {
        if (authcz.enabled && authcz.enabled == 'true') {
            return true;
        }
        if (authcz.http_enabled && authcz.http_enabled == "true") {
            return true;
        }
        if (authcz.transport_enabled && authcz.transport_enabled == "true") {
            return true;
        }

        return false;
    }

    $scope.stringifyJson = function(config)  {
        return JSON.stringify(config, undefined, 2);
    }
});
