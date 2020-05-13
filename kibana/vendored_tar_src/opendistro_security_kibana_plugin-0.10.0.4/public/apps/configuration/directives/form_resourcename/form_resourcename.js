import { uiModules } from 'ui/modules';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('securitycFormResourceName', function () {
    return {
        template: require('./form_resourcename.html'),
        replace: true,
        restrict: 'E'
    };
});
