import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('fileModel', ['$parse',  function ($parse) {

    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            //var fileReader = new $window.FileReader();
            var reader = new FileReader();
            var model = $parse(attrs.fileModel);
            var modelSetter = model.assign;

            element.bind('change', function(){
                scope.$apply(function(){
                    var file = element[0].files[0];
                    reader.readAsText(file);
                    reader.onload = function (evt) {
                        modelSetter(scope, reader.result);
                    }
                });
            });
        }
    };
}]);
