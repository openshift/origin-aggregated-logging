import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycPermissions', function () {
    return {
        template: require('./permissions.html'),
        restrict: 'EA',
        scope: {
            "permissionsResource": "=permissionsresource",
            'onShouldConfirm': '&',
        },
        controller: 'securityBaseController',
        link: function(scope, elem, attr) {

            scope.showAdvanced = null;
            scope.actiongroupItems = [];

            scope.$watch('permissionsResource', function(newValue, oldValue){
                if(newValue && (scope.showAdvanced == null)) {
                    if (scope.permissionsResource.permissions && scope.permissionsResource.permissions.length > 0) {
                        scope.showAdvanced = true;
                    }
                }
            }, true)

            /**
             * Prepare values for the actiongroupsAutoComplete
             * We could probably change the data source to avoid
             * having to convert the data twice
             * @returns {Array|*}
             */
            scope.getActiongroupItems = function() {
                if (scope.actiongroupItems.length) {
                    return scope.actiongroupItems;
                }

                if (scope.actiongroupsAutoComplete) {
                    scope.actiongroupItems = scope.actiongroupsAutoComplete.map((item) => {
                        return item.name;
                    });
                }

                return scope.actiongroupItems;

            };

            // UI-Select seems to work best with a plain array in this case
            scope.permissionItems = scope.allpermissionsAutoComplete.map((item) => {
                return item;
            });

            /**
             * This is a helper for when the autocomplete was closed an item being explicitly selected (mouse, tab or enter).
             * When you e.g. type a custom value and then click somewhere outside of the autocomplete, it looks like the
             * custom value was selected, but it is never saved to the model. This function calls the "select" method
             * every time the autocomplete is closed, no matter how. This may mean that the select function is called
             * twice, so the select handler should mitigate that if necessary.
             * @param isOpen
             * @param $select
             */
            scope.onCloseNewSinglePermission = function(isOpen, $select, index) {
                if (isOpen || !$select.select || !$select.selected) {
                    return;
                }
                if ($select.selected.name) {
                    $select.select($select.selected.name);
                }
            };

            /**
             * Allow custom values for the single permission autocomplete
             *
             * @credit https://medium.com/angularjs-meetup-south-london/angular-extending-ui-select-to-accept-user-input-937bc925267c
             * @param $select
             */
            scope.refreshNewSinglePermission = function($select) {
                var search = $select.search,
                    list = angular.copy($select.items),
                    FLAG = -1; // Identifies the custom value

                // Clean up any previous custom input
                list = list.filter(function(item) {
                    return item.id !== FLAG;
                });

                if (!search) {
                    $select.items = list;
                } else {

                    if (typeof scope.application === 'undefined') {
                        // For "non-application" permissions, we need custom entries to start with cluster: or indices:
                        if (search.indexOf('cluster:') !== 0 && search.indexOf('indices:') !== 0) {
                            return;
                        }
                    }
                    // Add and select the custom value
                    let customItem = {
                        id: FLAG,
                        name: search
                    };
                    $select.items = [customItem].concat(list);

                    $select.selected = customItem;
                }
            };

            /**
             * This is a weird workaround for the autocomplete where
             * we have can't or don't want to use the model item
             * directly in the view. Instead, we use the on-select
             * event to set the target value
             * @type {{}}
             */
            /*
            scope.onSelectedActionGroup = function(event) {
                scope.permissionsResource.actiongroups[event.index] = event.item.name;
            };
            */

            /**
             * This is a weird workaround for the autocomplete where
             * we have can't or don't want to use the model item
             * directly in the view. Instead, we use the on-select
             * event to set the target value
             * @type {{}}
             */
            /*
            scope.onSelectedPermission = function(event) {
                scope.permissionsResource.permissions[event.index] = event.item.name;
            };
            */

            /**
             * Since we have an isolated scope, we can't modify the parent scope without breaking
             * the binding. Hence, we pass the parent scope's handler to this directive.
             *
             * An alternative could be to encapsulate the delete logic in a service.
             *
             * @param {array} source
             * @param {string} item
             */
            scope.confirmDeletePermission = function(source, item) {
                scope.onShouldConfirm()(source, item);
            };


        }
    }
});
