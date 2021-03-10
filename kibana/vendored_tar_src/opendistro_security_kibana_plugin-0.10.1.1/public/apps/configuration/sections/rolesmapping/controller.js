import { uiModules } from 'ui/modules';
import { get } from 'lodash';
import '../../backend_api/rolesmapping';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.controller('securityRoleMappingsController', function ($scope, $element, $route, createNotifier, backendrolesmapping, kbnUrl) {

    $scope.endpoint = "rolesmapping";
    $scope.$parent.endpoint = "rolesmapping";

    $scope.service = backendrolesmapping;
    $scope.$parent.service = backendrolesmapping;

    $scope.resources = {};

    $scope.title = "Manage Role Mappings";

    $scope.service.list().then(function (response) {
        $scope.resourcenames = Object.keys(response.data).sort();

        $scope.resourcenames.forEach(function (entry) {
            $scope.resources[entry] = $scope.service.postFetch(response.data[entry]);
        });


        $scope.numresources = response.total;
        $scope.loaded = true;
    });

    $scope.securityRoleMissing = function(mappingname) {
        if ($scope.roleNames && $scope.roleNames.length > 0) {
            return $scope.roleNames.indexOf(mappingname) == -1 ? true : false;
        }
        return false;
    }

    $scope.newRole = function(rolename) {
        kbnUrl.change(`/roles/new?name=`+rolename);
    }

    /**
     * Holds table sorting info
     * @type {{byKey: string, descending: boolean}}
     */
    $scope.sortTable = {
        byKey: 'resourcename',
        descending: false
    };

    /**
     * Handle changed sorting conditions.
     * Since we only have one column sortable, changing the key doesn't really do anything.
     * Until we have more sortable columns, only the sort order is changed
     * @param {string} key
     */
    $scope.onSortChange = function(key) {
        if ($scope.sortTable.byKey === key) {
            $scope.sortTable.descending = ! $scope.sortTable.descending;
        } else {
            $scope.sortTable.byKey = key;
        }
    };


});

app.controller('securityEditRoleMappingsController', function ($scope, $element, $route, $location, $routeParams, createNotifier, backendrolesmapping, backendAPI, kbnUrl) {

    $scope.endpoint = "rolesmapping";
    $scope.$parent.endpoint = "rolesmapping";

    $scope.service = backendrolesmapping;
    $scope.$parent.service = backendrolesmapping;

    $scope.resourcelabel = "Role";
    $scope.resource = {};
    $scope.resourcename = "";
    $scope.resourcenames = [];
    $scope.isNew = false;
    $scope.query = "";

    $scope.resourceloaded = false;

    $scope.title = function () {
        return $scope.isNew? "New Role Mapping" : "Edit Role Mapping '" + $scope.resourcename+"'";
    }

    /**
     * Handle the selected item from the ui-select instance
     * @param event
     */
    $scope.onSelectedNewResourceName = function(event) {
        $scope.resourcename = event.item.name;
    };

    // get all usernames and load pre-existing user, if any
    $scope.service.list().then((response) => {
        $scope.resourcenames = Object.keys(response.data);

        var rolemapping = $routeParams.resourcename;
        if (rolemapping) {
            $scope.service.get(rolemapping)
                .then((response) => {
                    $scope.resource = $scope.service.postFetch(response);
                    $scope.resourcename = rolemapping;
                    $scope.resourceloaded = true;
                    if($location.path().indexOf("clone") == -1) {
                        $scope.isNew = false;
                    } else {
                        $scope.resourcename = $scope.resourcename + " (COPY)";
                        $scope.isNew = true;
                        delete($scope.resource.readonly);
                    }
                });
        } else {
            $scope.resource = $scope.service.emptyModel();
            if ($routeParams.name) {
                $scope.resourcename = $routeParams.name;
            }
            $scope.isNew = true;
        }
        $scope.loaded = true;
    });

    $scope.saveObject = (event) => {
        if (event) {
            event.preventDefault();
        }

        // not dots in keys allowed
        if ($scope.resourcename.indexOf('.') != -1) {
            $scope.errorMessage = 'Please do not use dots in the role mapping name.';
            return;
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

        if ($scope.isNew && $scope.resourcenames.indexOf($scope.resourcename) != -1) {
            $scope.errorMessage = 'Role mapping for Security group "'+$scope.resourcename+'"already exists, please choose another one.';
            return;
        }

        // check for empty arrays or undefined objects
        $scope.resource.users = backendAPI.cleanArray($scope.resource.users);
        $scope.resource.backendroles = backendAPI.cleanArray($scope.resource.backendroles);
        $scope.resource.hosts = backendAPI.cleanArray($scope.resource.hosts);

        if ($scope.resource.users.length == 0 && $scope.resource.backendroles.length == 0 && $scope.resource.hosts.length == 0) {
            $scope.errorMessage = 'Please configure at least one of users, backend roles or hosts.';
            return;
        }

        $scope.service.save($scope.resourcename, $scope.resource).then(() => kbnUrl.change(`/rolesmapping/`));

        $scope.errorMessage = null;

    };
});
