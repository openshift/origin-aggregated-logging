define(['require'], function(require){
   const plugin = require('ui/modules').get('kibana');
   plugin.directive('body', ['$compile', function($compile) {
      const html = angular.element(require('./templates/header.html'));
      const linkFn = $compile(html);
      return {
        restrict: 'E',
        link: function(scope, element, attrs) {
          element.prepend(linkFn(scope));
          if (element.hasClass('subnav')) {
            return;
          }
          element.addClass('navbar-pf');
          element.removeClass('navbar');
          element.removeClass('navbar-default');
          element.find('.nav.navbar-nav').addClass('navbar-primary');
        }
      }
    }]);
    plugin.directive('subnav', function() {
      return {
        restrict: 'C',
        link: function (scope, element, attrs) {
          element.removeClass('navbar');
          element.removeClass('navbar-default');
          element.find('.container-fluid').removeClass('container-fluid');
          element.find('.nav.navbar-nav').addClass('navbar-persistent');
        }
      }
    });
});
