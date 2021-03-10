import { uiModules } from 'ui/modules';
import template from './accordeon.html';
import './accordeon_header';

const app = uiModules.get('apps/opendistro_security/configuration', []);

app.directive('accordeon', function () {
  return {
    restrict: 'E',
    replace: true,
    transclude: true,
    template: template,
    scope: {
      accordeonId: '@',
      title: '@',
      isCollapsed: '=',
      additionalClass: '@'
    },
    controllerAs: 'accordeon',
    bindToController: true,
    controller: class AccordeonController {
      toggle = () => {
        this.isCollapsed = !this.isCollapsed;
        //this.onToggle(this.togglePanelId);
      };
    }
  };
});
