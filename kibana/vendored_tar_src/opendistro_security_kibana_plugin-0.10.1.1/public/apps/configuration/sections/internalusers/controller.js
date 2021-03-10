import { uiModules } from 'ui/modules';
import { get } from 'lodash';
import '../../backend_api/internalusers';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.controller('securityInternalUsersController', function ($scope, $element, $route, createNotifier, backendInternalUsers, kbnUrl) {

    $scope.endpoint = "INTERNALUSERS";
    $scope.$parent.endpoint = "INTERNALUSERS";

    $scope.service = backendInternalUsers;
    $scope.$parent.service = backendInternalUsers;

    $scope.title = "Manage Internal User";

    $scope.resources = {};

    $scope.service.list().then(function (response) {
        $scope.resourcenames = Object.keys(response.data).sort();

        $scope.resourcenames.forEach(function (entry) {
            $scope.resources[entry] = $scope.service.postFetch(response.data[entry]);
        });

        $scope.numresources = response.total;
        $scope.loaded = true;
    });

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

app.controller('securityEditInternalUsersController', function ($scope, $element, $route, $location, $routeParams, createNotifier, backendInternalUsers, kbnUrl) {

    $scope.endpoint = "INTERNALUSERS";
    $scope.$parent.endpoint = "INTERNALUSERS";

    $scope.service = backendInternalUsers;
    $scope.$parent.service = backendInternalUsers;

    $scope.resourcelabel = "Internal User";

    $scope.resource = {};
    $scope.resourcename = "";
    $scope.resourcenames = [];
    $scope.isNew = false;

    $scope.title = function () {
        return $scope.isNew? "New Internal User" : "Edit Internal User '" + $scope.resourcename+"'";
    }

    // get all usernames and load pre-existing user, if any
    $scope.service.list().then((response) => {

        $scope.resourcenames = Object.keys(response.data);

        var username = $routeParams.resourcename;

        if (username) {
            $scope.service.get(username)
                .then((response) => {
                    $scope.service.postFetch(response);
                    $scope.resource = response;
                    $scope.resourcename = username;
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

        const form = $element.find('form[name="objectForm"]');

        if ($scope.isNew && $scope.resourcenames.indexOf($scope.resourcename) != -1) {
            $scope.errorMessage = 'Username already exists, please choose another one.';
            return;
        }

        if ($scope.resourcename.indexOf(".") != -1 || $scope.resourcename.indexOf("*") != -1) {
            $scope.errorMessage = "Username must not contain '.' or '*'";
            return;
        }

        if (form.hasClass('ng-invalid-required')) {
            $scope.errorMessage = 'Please fill in all the required parameters.';
            return;
        }

        if (!form.hasClass('ng-valid')) {
            $scope.errorMessage = 'Please correct all errors and try again.';
            return;
        }

        if(! $scope.isNew) {
            if ($scope.resource.password.trim().length == 0) {
                $scope.resource.passwordConfirmation = "";
            }
        }

        if ($scope.resource.password !== $scope.resource.passwordConfirmation) {
            $scope.errorMessage = 'Passwords do not match.';
            return;
        }

        $scope.service.save($scope.resourcename, $scope.resource)
          .then(
            () => kbnUrl.change(`/internalusers/`),
            (error) => {$scope.errorMessage = error.data.message}
          );

        $scope.errorMessage = null;

    };
});
