define(['require'], function (require) {
  var plugin = require('ui/modules').get('kibana');
  var qs = require('ui/utils/query_string');
  //ref: https://github.com/openshift/origin/blob/master/assets/app/scripts/services/userstore.js
  plugin.provider('LocalStorageUserStore', function () {
    this.$get = function ($location, Logger) {
      var authLogger = Logger.get('auth');
      var userkey = 'LocalStorageUserStore.user';
      var tokenkey = 'LocalStorageUserStore.token';
      var hash = qs.decode($location.hash());
      var settings = {};
      if (userkey in localStorage) {
        try {
          settings = JSON.parse(localStorage[userkey]);
        } catch (e) {
          // corrupt entry, let's clear it...
          localStorage.removeItem(userkey);
        }
      }
      var regex = /^console_/;
      var toRemove = [];
      Object.getOwnPropertyNames(hash).forEach(function (propName) {
        if (propName.search(regex) !== -1) {
          console.log("found propName: ", propName);
          var settingName = propName.replace(regex, '');
          if (settingName.length > 0) {
            settings[settingName] = hash[propName];
            toRemove.push(propName);
          }
        }
      });
      toRemove.forEach(function (propName) {
        delete hash[propName];
      });
      localStorage[userkey] = JSON.stringify(settings);
      $location.hash(qs.encode(hash));
      $location.replace();
      var ttlKey = function (key) {
        return key + '.ttl';
      };
      var setTTL = function (key, ttl) {
        if (ttl) {
          var expires = new Date().getTime() + ttl * 1000;
          localStorage[ttlKey(key)] = expires;
          authLogger.log('LocalStorageUserStore.setTTL', key, ttl, new Date(expires).toString());
        } else {
          localStorage.removeItem(ttlKey(key));
          authLogger.log('LocalStorageUserStore.setTTL deleting', key);
        }
      };
      var isTTLExpired = function (key) {
        var ttl = localStorage[ttlKey(key)];
        if (!ttl) {
          return false;
        }
        var expired = parseInt(ttl) < new Date().getTime();
        authLogger.log('LocalStorageUserStore.isTTLExpired', key, expired);
        return expired;
      };
      return {
        available: function () {
          try {
            var x = String(new Date().getTime());
            localStorage['LocalStorageUserStore.test'] = x;
            var y = localStorage['LocalStorageUserStore.test'];
            localStorage.removeItem('LocalStorageUserStore.test');
            return x === y;
          } catch (e) {
            return false;
          }
        },
        getUser: function () {
          try {
            if (isTTLExpired(userkey)) {
              authLogger.log('LocalStorageUserStore.getUser expired');
              localStorage.removeItem(userkey);
              setTTL(userkey, null);
              return null;
            }
            var user = JSON.parse(localStorage[userkey]);
            authLogger.log('LocalStorageUserStore.getUser', user);
            return user;
          } catch (e) {
            authLogger.error('LocalStorageUserStore.getUser', e);
            return null;
          }
        },
        setUser: function (user, ttl) {
          if (user) {
            authLogger.log('LocalStorageUserStore.setUser', user, ttl);
            localStorage[userkey] = JSON.stringify(user);
            setTTL(userkey, ttl);
          } else {
            authLogger.log('LocalStorageUserStore.setUser', user, 'deleting');
            localStorage.removeItem(userkey);
            setTTL(userkey, null);
          }
        },
        getToken: function () {
          try {
            if (isTTLExpired(tokenkey)) {
              authLogger.log('LocalStorageUserStore.getToken expired');
              localStorage.removeItem(tokenkey);
              setTTL(tokenkey, null);
              return null;
            }
            var token = localStorage[tokenkey];
            authLogger.log('LocalStorageUserStore.getToken', token);
            return token;
          } catch (e) {
            authLogger.error('LocalStorageUserStore.getToken', e);
            return null;
          }
        },
        setToken: function (token, ttl) {
          if (token) {
            authLogger.log('LocalStorageUserStore.setToken', token, ttl);
            localStorage[tokenkey] = token;
            setTTL(tokenkey, ttl);
          } else {
            authLogger.log('LocalStorageUserStore.setToken', token, ttl, 'deleting');
            localStorage.removeItem(tokenkey);
            setTTL(tokenkey, null);
          }
        }
      };
    };
  });
  plugin.provider('UserStore', function () {
    this.$get = function (LocalStorageUserStore) {
      return LocalStorageUserStore;
    };
  });
});
