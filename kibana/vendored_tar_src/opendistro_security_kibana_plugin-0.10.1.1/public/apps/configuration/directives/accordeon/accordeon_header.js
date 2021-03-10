import { uiModules } from 'ui/modules';
import template from './accordeon_header.html';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('accordeonHeader', function () {
  return {
    restrict: 'E',
    replace: true,
    template: template,
    scope: {
      title: '@',
      isCollapsed: '=',
      onClick: '=',
      additionalClass: '@'
    },
    controllerAs: 'accordeonHeader',
    bindToController: true,
    controller: class ToggleButtonController {
    }
  };
});
