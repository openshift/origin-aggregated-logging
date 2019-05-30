(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/*!
 * jclass v1.0.1
 * https://github.com/riga/jclass
 *
 * Marcel Rieger, 2014
 * MIT licensed, http://www.opensource.org/licenses/mit-license
 */

(function(factory) {
  if (typeof define === "function" && define.amd) {
    // AMD
    define([], factory);
  } else if (typeof exports === "object") {
    // CommonJS
    exports = factory();
    if (typeof module === "object") {
      // nodejs
      module.exports = exports;
    }
  } else if (window) {
    // Browser
    window.Class = factory();
  } else if (typeof console === "object" && console.error instanceof Function) {
    // error case
    console.error("cannot determine environment");
  }

})(function() {

  // helpers
  var isFn = function(obj) {
    return obj instanceof Function;
  };
  var isUndef = function(obj) {
    return obj === undefined;
  };
  var isObj = function(obj) {
    return typeof obj === "object";
  };
  var extend = function(target) {
    var objs = Array.prototype.slice.call(arguments, 1);
    var i, obj, key, originalValue;
    for (i in objs) {
      obj = objs[i];
      if (!isObj(obj)) return;
      for (key in obj) {
        originalValue = target[key];
        if (isUndef(originalValue)) target[key] = obj[key];
      }
    }
    return target;
  };

  // default options
  var defaultOptions = {
    _isClassObject: false
  };

  // flag to distinguish between prototype and class instantiation 
  var initializing = false;

  // empty BaseClass implementation
  var BaseClass = function(){};

  // add the _subClasses entry
  BaseClass._subClasses = [];

  // extend mechanism
  BaseClass._extend = function(instanceMembers, classMembers, options) {

    // default arguments
    if (isUndef(instanceMembers)) instanceMembers = {};
    if (isUndef(classMembers))    classMembers    = {};
    if (isUndef(options))         options         = {};

    // mixin default options
    extend(options, defaultOptions);

    // alias for readability
    var SuperClass = this;

    // sub class dummy constructor
    var Class = function() {
      // nothing happens here when we are initializing
      if (initializing) return;

      // store a reference to the class itself
      this._class = Class;

      // all construction is actually done in the init method
      if (this.init) this.init.apply(this, arguments);
    };

    // create an instance of the super class via new
    // the flag sandwich prevents a call to the init method
    initializing = true;
    var prototype = new SuperClass();
    initializing = false;

    // get the prototype of the super class
    var superPrototype = SuperClass.prototype;

    // the instance of the super class is our new prototype
    Class.prototype = prototype;

    // enforce the constructor to be what we expect
    // this will invoke the init method (see above)
    Class.prototype.constructor = Class;

    // store a reference to the super class
    Class._superClass = SuperClass;

    // store references to all extending classes
    Class._subClasses = [];
    SuperClass._subClasses.push(Class);

    // make this class extendable
    Class._extend = SuperClass._extend;

    // propagate instance members directly to the created protoype
    var key, member, superMember;
    for (key in instanceMembers) {
      member      = instanceMembers[key];
      superMember = superPrototype[key];

      // simply set the member
      prototype[key] = member;

      // if both member and superMember are distinct functions
      // add the superMember to the member as "_super"
      if (isFn(member) && isFn(superMember) && member !== superMember) {
        member._super = superMember;
      }
    }

    // propagate class members to the _members instance
    if (!options._isClassObject) {
      // find the super class of the _members instance 
      var ClassMembersSuperClass = isUndef(SuperClass._members) ?
        BaseClass : SuperClass._members._class;

      // create the actual class of the _members instance
      var opts = { _isClassObject: true };
      var ClassMembersClass = ClassMembersSuperClass._extend(classMembers, {}, opts);

      // create the instance
      Class._members = new ClassMembersClass();
    }

    // _extends returns true if the class itself extended "target"
    // in any hierarchy, e.g. every class inherits "Class" itself
    Class._extends = function(target) {
      if (this._superClass == BaseClass) return false;
      if (target == this._superClass) return true;
      return this._superClass._extends(target);
    };

    return Class;
  };


  // converts arbitrary protoype-style classes to our Class definition
  BaseClass._convert = function(cls, options) {

    // create properties, starting with the init function required by Class
    var instanceMembers = {
      init: function() {
        // simply create an instance of our target class
        this._prototype = BaseClass._construct(cls, arguments);
      }
    };

    // create wrappers for all members and bind them
    var key, member;
    for (key in cls.prototype) {
      // ensure that the init function is not overwritten
      if (key === "init") return;

      // member mapping, unfortunately we cannot avoid method wrapping here
      member = cls.prototype[key];
      instanceMembers[key] = !isFn(member) ? member : (function(fn) {
        return function() {
          return fn.apply(this._prototype, arguments);
        };
      })(member);
    }

    // finally, create and return our new class
    return BaseClass._extend(instanceMembers, {}, options);
  };


  // returns an instance of a class with a list of arguments
  // that are passed to the constructor 
  // this provides an apply-like constructor usage
  BaseClass._construct = function(cls, args) {
    var Class = function() {
      return cls.apply(this, args || []);
    };

    Class.prototype = cls.prototype;

    return new Class();
  };

  return BaseClass;
});

},{}],2:[function(require,module,exports){
/*===========================================================================*\
 * Requires
\*===========================================================================*/
var JClass = require('jclass');

/*===========================================================================*\
 * HashArray
\*===========================================================================*/
var HashArray = JClass._extend({
  //-----------------------------------
  // Constructor
  //-----------------------------------
  init: function(keyFields, callback, options) {
    keyFields = keyFields instanceof Array ? keyFields : [keyFields];

    this._map = {};
    this._list = [];
    this.callback = callback;

    this.keyFields = keyFields;

    this.isHashArray = true;
    
    this.options = options || {
      ignoreDuplicates: false
    };

    if (callback) {
      callback('construct');
    }
  },
  //-----------------------------------
  // add()
  //-----------------------------------
  addOne: function (obj) {
    var needsDupCheck = false;
    for (var key in this.keyFields) {
      key = this.keyFields[key];
      var inst = this.objectAt(obj, key);
      if (inst) {
        if (this._map[inst]) {
          if (this.options.ignoreDuplicates)
            return;
          if (this._map[inst].indexOf(obj) != -1) {
            // Cannot add the same item twice
            needsDupCheck = true;
            continue;
          }
          this._map[inst].push(obj);
        }
        else this._map[inst] = [obj];
      }
    }

    if (!needsDupCheck || this._list.indexOf(obj) == -1)
      this._list.push(obj);
  },
  add: function() {
    for (var i = 0; i < arguments.length; i++) {
      this.addOne(arguments[i]);
    }

    if (this.callback) {
      this.callback('add', Array.prototype.slice.call(arguments, 0));
    }
    
    return this;
  },
  addAll: function (arr) {
    if (arr.length < 100)
      this.add.apply(this, arr);
    else {
      for (var i = 0; i < arr.length; i++)
        this.add(arr[i]);
    }
    
    return this;
  },
  addMap: function(key, obj) {
    this._map[key] = obj;
    if (this.callback) {
      this.callback('addMap', {
        key: key,
        obj: obj
      });
    }
    
    return this;
  },
  //-----------------------------------
  // Intersection, union, etc.
  //-----------------------------------
  /**
   * Returns a new HashArray that contains the intersection between this (A) and the hasharray passed in (B). Returns A ^ B.
   */
  intersection: function (other) {
    var self = this;

    if (!other || !other.isHashArray)
      throw Error('Cannot HashArray.intersection() on a non-hasharray object. You passed in: ', other);

    var ret = this.clone(null, true),
      allItems = this.clone(null, true).addAll(this.all.concat(other.all));

    allItems.all.forEach(function (item) {
      if (self.collides(item) && other.collides(item))
        ret.add(item);
    });

    return ret;
  },
  /**
   * Returns a new HashArray that contains the complement (difference) between this hash array (A) and the hasharray passed in (B). Returns A - B.
   */
  complement: function (other) {
    var self = this;

    if (!other || !other.isHashArray)
      throw Error('Cannot HashArray.complement() on a non-hasharray object. You passed in: ', other);

    var ret = this.clone(null, true);

    this.all.forEach(function (item) {
      if (!other.collides(item))
        ret.add(item);
    });

    return ret;
  },
  //-----------------------------------
  // Retrieval
  //-----------------------------------
  get: function(key) {
    return (!(this._map[key] instanceof Array) || this._map[key].length != 1) ? this._map[key] : this._map[key][0];
  },
  getAll: function(keys) {
    keys = keys instanceof Array ? keys : [keys];

    if (keys[0] == '*')
      return this.all;

    var res = new HashArray(this.keyFields);
    for (var key in keys)
      res.add.apply(res, this.getAsArray(keys[key]));

    return res.all;
  },
  getAsArray: function(key) {
    return this._map[key] || [];
  },
  getUniqueRandomIntegers: function (count, min, max) {
    var res = [], map = {};

    count = Math.min(Math.max(max - min, 1), count);
    
    while (res.length < count)
    {
      var r = Math.floor(min + (Math.random() * (max + 1)));
      if (map[r]) continue;
      map[r] = true;
      res.push(r);
    }

    return res;
  },
  sample: function (count, keys) {
    // http://en.wikipedia.org/wiki/Image_(mathematics)
    var image = this.all,
      ixs = {},
      res = [];

    if (keys)
      image = this.getAll(keys);

    var rand = this.getUniqueRandomIntegers(count, 0, image.length - 1);

    for (var i = 0; i < rand.length; i++)
      res.push(image[rand[i]]);

    return res;
  },
  //-----------------------------------
  // Peeking
  //-----------------------------------
  has: function(key) {
    return this._map.hasOwnProperty(key);
  },
  collides: function (item) {
    for (var k in this.keyFields)
      if (this.has(this.objectAt(item, this.keyFields[k])))
        return true;
    
    return false;
  },
  hasMultiple: function(key) {
    return this._map[key] instanceof Array;
  },
  //-----------------------------------
  // Removal
  //-----------------------------------
  removeByKey: function() {
    var removed = [];
    for (var i = 0; i < arguments.length; i++) {
      var key = arguments[i];
      var items = this._map[key].concat();
      if (items) {
        removed = removed.concat(items);
        for (var j in items) {
          var item = items[j];
          for (var ix in this.keyFields) {
            var key2 = this.objectAt(item, this.keyFields[ix]);
            if (key2 && this._map[key2]) {
              var ix = this._map[key2].indexOf(item);
              if (ix != -1) {
                this._map[key2].splice(ix, 1);
              }

              if (this._map[key2].length == 0)
                delete this._map[key2];
            }
          }

          this._list.splice(this._list.indexOf(item), 1);
        }
      }
      delete this._map[key];
    }

    if (this.callback) {
      this.callback('removeByKey', removed);
    }
    
    return this;
  },
  remove: function() {
    for (var i = 0; i < arguments.length; i++) {
      var item = arguments[i];
      for (var ix in this.keyFields) {
        var key = this.objectAt(item, this.keyFields[ix]);
        if (key) {
          var ix = this._map[key].indexOf(item);
          if (ix != -1)
            this._map[key].splice(ix, 1);

          if (this._map[key].length == 0)
            delete this._map[key];
        }
      }

      this._list.splice(this._list.indexOf(item), 1);
    }

    if (this.callback) {
      this.callback('remove', arguments);
    }
    
    return this;
  },
  removeAll: function() {
    var old = this._list.concat();
    this._map = {};
    this._list = [];

    if (this.callback) {
      this.callback('remove', old);
    }
    
    return this;
  },
  //-----------------------------------
  // Utility
  //-----------------------------------
  objectAt: function(obj, path) {
    if (typeof path === 'string') {
      return obj[path];
    }

    var dup = path.concat();
    // else assume array.
    while (dup.length && obj) {
      obj = obj[dup.shift()];
    }

    return obj;
  },
  //-----------------------------------
  // Iteration
  //-----------------------------------
  forEach: function(keys, callback) {
    keys = keys instanceof Array ? keys : [keys];

    var objs = this.getAll(keys);

    objs.forEach(callback);
    
    return this;
  },
  forEachDeep: function(keys, key, callback) {
    keys = keys instanceof Array ? keys : [keys];

    var self = this,
      objs = this.getAll(keys);

    objs.forEach(function (item) {
      callback(self.objectAt(item, key), item);
    });
    
    return this;
  },
  //-----------------------------------
  // Cloning
  //-----------------------------------
  clone: function(callback, ignoreItems) {
    var n = new HashArray(this.keyFields.concat(), callback ? callback : this.callback);
    if (!ignoreItems)
      n.add.apply(n, this.all.concat());
    return n;
  },
  //-----------------------------------
  // Mathematical
  //-----------------------------------
  sum: function(keys, key, weightKey) {
    var self = this,
      ret = 0;
    this.forEachDeep(keys, key, function (value, item) {
      if (weightKey !== undefined)
        value *= self.objectAt(item, weightKey);

      ret += value;
    });
    return ret;
  },
  average: function(keys, key, weightKey) {
    var ret = 0,
      tot = 0,
      weightsTotal = 0,
      self = this;

    if (weightKey !== undefined)
      this.forEachDeep(keys, weightKey, function (value) {
        weightsTotal += value;
      })

    this.forEachDeep(keys, key, function (value, item) {
      if (weightKey !== undefined)
        value *= (self.objectAt(item, weightKey) / weightsTotal);

      ret += value;
      tot++;
    });

    return weightKey !== undefined ? ret : ret / tot;
  },
  //-----------------------------------
  // Filtering
  //-----------------------------------
  filter: function (keys, callbackOrKey) {
    var self = this;
    
    var callback = (typeof(callbackOrKey) == 'function') ? callbackOrKey : defaultCallback;

    var ha = new HashArray(this.keyFields);
    ha.addAll(this.getAll(keys).filter(callback));
    return ha;
    
    function defaultCallback(item) {
      var val = self.objectAt(item, callbackOrKey);
      return val !== undefined && val !== false;
    }
  }
});

//-----------------------------------
// Operators
//-----------------------------------
Object.defineProperty(HashArray.prototype, 'all', {
  get: function () {
    return this._list;
  }
});

Object.defineProperty(HashArray.prototype, 'map', {
  get: function () {
    return this._map;
  }
});

module.exports = HashArray;

//-----------------------------------
// Browser
//-----------------------------------
if (typeof window !== 'undefined')
  window.HashArray = HashArray;
},{"jclass":1}]},{},[2]);
