define(['require'], function (require) {
  const plugin = require('ui/modules').get('kibana');
  plugin.controller('OSHeaderController', ['$scope', 'UserStore', function ($scope, UserStore) {
    const user = UserStore.getUser();
    $scope.containerName = user.container_name;
    $scope.goBack = user.back_url;
  }]);
});
