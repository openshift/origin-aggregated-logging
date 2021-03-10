import angular from 'angular';
import uiRoutes from 'ui/routes';
import sectionTemplate from './views/index.html';
import editTemplate from './views/edit.html';
import './controller';
import '../../directives/directives';

import 'ui/autoload/styles';
import 'plugins/opendistro_security/apps/configuration/configuration.less';

uiRoutes
    .when('/rolesmapping', {
      template: sectionTemplate
    })
    .when('/rolesmapping/edit/:resourcename', {
      template: editTemplate
    })
    .when('/rolesmapping/clone/:resourcename', {
        template: editTemplate
    })
    .when('/rolesmapping/new', {
      template: editTemplate
    });
