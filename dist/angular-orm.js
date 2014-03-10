var module;

module = angular.module('angular-orm', []);

var module,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

module = angular.module('angular-orm');

module.factory('RelationalIndex', function($q) {
  var RelationalIndex;
  return RelationalIndex = (function() {
    RelationalIndex.MANY = 'many';

    RelationalIndex.ONE = 'one';

    function RelationalIndex(data) {
      this.isEmpty = __bind(this.isEmpty, this);
      this.all = __bind(this.all, this);
      this.find = __bind(this.find, this);
      this.get = __bind(this.get, this);
      this.has = __bind(this.has, this);
      this.add = __bind(this.add, this);
      this.clone = __bind(this.clone, this);
      if (data) {
        this.relations = Object.clone(data, true);
      } else {
        this.relations = {};
      }
    }

    RelationalIndex.prototype.clone = function() {
      return new RelationalIndex(this.relations);
    };

    RelationalIndex.prototype.add = function(property, modelName, type, key, keyInSelf) {
      if (keyInSelf == null) {
        keyInSelf = false;
      }
      return this.relations[modelName] = {
        model: modelName,
        property: property,
        type: type,
        key: key,
        keyInSelf: keyInSelf
      };
    };

    RelationalIndex.prototype.has = function(modelName) {
      return this.relations[modelName] != null;
    };

    RelationalIndex.prototype.get = function(modelName) {
      return this.relations[modelName];
    };

    RelationalIndex.prototype.find = function(options) {
      return this.relations[Object.find(this.relations, options)];
    };

    RelationalIndex.prototype.all = function(options) {
      var keys, matches, model, relation, subset, values, _ref;
      if (!options) {
        return _.values(this.relations);
      }
      values = [];
      keys = _.keys(options);
      _ref = this.relations;
      for (model in _ref) {
        relation = _ref[model];
        subset = _.pick.apply(_, [relation].concat(__slice.call(keys)));
        matches = _.isEqual(subset, options);
        if (matches) {
          values.push(relation);
        }
      }
      return values;
    };

    RelationalIndex.prototype.isEmpty = function() {
      return !_.keys(this.relations).length;
    };

    return RelationalIndex;

  })();
});

var module,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

module = angular.module('angular-orm', module.factory('Model', [
  'RelationalIndex', function(RelationalIndex) {
    var Model;
    return Model = (function() {
      Model.CREATED = 'created';

      Model.UPDATED = 'updated';

      function Model(staticSelf, data, eventStream) {
        this.staticSelf = staticSelf;
        this.eventStream = eventStream;
        this.pushEvent = __bind(this.pushEvent, this);
        this.hasRelationalChanges = __bind(this.hasRelationalChanges, this);
        this.update = __bind(this.update, this);
        this.storeAssociatedModel = __bind(this.storeAssociatedModel, this);
        this.filterModelStream = __bind(this.filterModelStream, this);
        this.update(data, true);
        if (this.eventStream) {
          this.associatedModelStream = this.eventStream.filter(this.filterModelStream);
          this.associatedModelStream.onValue(this.storeAssociatedModel);
          if (!this.staticSelf.relationalIndex.isEmpty()) {
            this.pushEvent(Model.CREATED);
          }
        }
      }

      Model.prototype.filterModelStream = function(data) {
        var relation;
        if (!(relation = this.staticSelf.relationalIndex.get(data.model))) {
          return false;
        }
        if (relation.keyInSelf) {
          return data.object.id === this[relation.key];
        } else {
          return data.object[relation.key] === this.id;
        }
      };

      Model.prototype.storeAssociatedModel = function(data) {
        var inverse, relation;
        if (!(relation = this.staticSelf.relationalIndex.get(data.model))) {
          return;
        }
        this.staticSelf.setAssociatedModel(this, relation.property, data.object, relation.type);
        if (!(inverse = data.object.staticSelf.relationalIndex.find({
          model: this.staticSelf.name,
          key: relation.key,
          keyInSelf: !relation.keyInSelf
        }))) {
          return;
        }
        return this.staticSelf.setAssociatedModel(data.object, inverse.property, this, inverse.type);
      };

      Model.prototype.update = function(data, silent) {
        var changed;
        if (silent == null) {
          silent = false;
        }
        changed = this.hasRelationalChanges(data);
        angular.extend(this, data);
        if (!silent && changed) {
          return this.pushEvent(Model.UPDATED);
        }
      };

      Model.prototype.hasRelationalChanges = function(data) {
        var changed, hasRelation, property, value;
        for (property in data) {
          value = data[property];
          changed = this[property] !== value;
          if (!changed) {
            continue;
          }
          hasRelation = this.staticSelf.relationalIndex.find({
            key: property,
            keyInSelf: true
          }) != null;
          if (hasRelation) {
            return true;
          }
        }
        return false;
      };

      Model.prototype.pushEvent = function(type) {
        var _ref;
        return (_ref = this.eventStream) != null ? _ref.push({
          event: type,
          model: this.staticSelf.name,
          id: this.id,
          object: this
        }) : void 0;
      };

      Model.initialize = function(name) {
        if (name == null) {
          name = this.name;
        }
        this.name = name;
        this.defaultKey = this.generateKeyFromModelName(this.name);
        if (this.relationalIndex) {
          return this.relationalIndex = this.relationalIndex.clone();
        } else {
          return this.relationalIndex = new RelationalIndex;
        }
      };

      Model.generateKeyFromModelName = function(modelName) {
        return "" + (modelName.charAt(0).toLowerCase()) + (modelName.slice(1)) + "ID";
      };

      Model.hasMany = function(property, modelName, options) {
        var key;
        if (options == null) {
          options = {};
        }
        if (!this.relationalIndex) {
          throw new Error("Cannot add relations to uninitialized class, call initialize() first.");
        }
        key = options.key || this.generateKeyFromModelName(this.name);
        return this.relationalIndex.add(property, modelName, RelationalIndex.MANY, key, false);
      };

      Model.hasOne = function(property, modelName, options) {
        var key, keyInSelf, nameForKey;
        if (options == null) {
          options = {};
        }
        if (!this.relationalIndex) {
          throw new Error("Cannot add relations to uninitialized class, call initialize() first.");
        }
        keyInSelf = options.keyInSelf !== false;
        nameForKey = keyInSelf ? modelName : this.name;
        key = options.key || this.generateKeyFromModelName(nameForKey);
        return this.relationalIndex.add(property, modelName, RelationalIndex.ONE, key, keyInSelf);
      };

      Model.belongsTo = function(property, modelName, options) {
        if (options == null) {
          options = {};
        }
        options = Object.clone(options);
        if (options.keyInSelf !== false) {
          options.keyInSelf = true;
        }
        return this.hasOne(property, modelName, options);
      };

      Model.setAssociatedModel = function(object, property, value, type) {
        switch (type) {
          case RelationalIndex.ONE:
            return object[property] = value;
          case RelationalIndex.MANY:
            object[property] || (object[property] = {});
            return object[property][value.id] = value;
          default:
            throw "Uknown relation-type";
        }
      };

      return Model;

    })();
  }
]));
