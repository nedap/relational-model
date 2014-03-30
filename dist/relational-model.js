var RelationalIndex,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

RelationalIndex = (function() {
  RelationalIndex.MANY = 'many';

  RelationalIndex.ONE = 'one';

  function RelationalIndex(data) {
    this.isEmpty = __bind(this.isEmpty, this);
    this.all = __bind(this.all, this);
    this.find = __bind(this.find, this);
    this.has = __bind(this.has, this);
    this.add = __bind(this.add, this);
    this.clone = __bind(this.clone, this);
    var model, rel;
    this.relations = {};
    if (data) {
      for (model in data) {
        rel = data[model];
        this.relations[model] = rel.slice();
      }
    }
  }

  RelationalIndex.prototype.clone = function() {
    return new RelationalIndex(this.relations);
  };

  RelationalIndex.prototype.add = function(property, modelName, type, key, keyInSelf) {
    var _base;
    if (keyInSelf == null) {
      keyInSelf = false;
    }
    (_base = this.relations)[modelName] || (_base[modelName] = []);
    return this.relations[modelName].push({
      model: modelName,
      property: property,
      type: type,
      key: key,
      keyInSelf: keyInSelf
    });
  };

  RelationalIndex.prototype.has = function(options) {
    var model, relation, rels, _i, _len, _ref, _ref1;
    if (!options) {
      throw new Error("Missing argument");
    }
    if (typeof options === 'string') {
      return ((_ref = this.relations[options]) != null ? _ref.length : void 0) > 0;
    }
    _ref1 = this.relations;
    for (model in _ref1) {
      rels = _ref1[model];
      for (_i = 0, _len = rels.length; _i < _len; _i++) {
        relation = rels[_i];
        if (RelationalIndex.matches(relation, options)) {
          return true;
        }
      }
    }
    return false;
  };

  RelationalIndex.prototype.find = function(options) {
    var model, relation, rels, values, _i, _len, _ref;
    if (!options) {
      return this.all();
    }
    if (typeof options === 'string') {
      return this.relations[options] || [];
    }
    values = [];
    _ref = this.relations;
    for (model in _ref) {
      rels = _ref[model];
      for (_i = 0, _len = rels.length; _i < _len; _i++) {
        relation = rels[_i];
        if (RelationalIndex.matches(relation, options)) {
          values.push(relation);
        }
      }
    }
    return values;
  };

  RelationalIndex.prototype.all = function() {
    var model, rels, values, _ref;
    values = [];
    _ref = this.relations;
    for (model in _ref) {
      rels = _ref[model];
      values.push.apply(values, rels);
    }
    return values;
  };

  RelationalIndex.prototype.isEmpty = function() {
    var model;
    for (model in this.relations) {
      return false;
    }
    return true;
  };

  RelationalIndex.matches = function(relation, criteria) {
    var criteriaEmpty, key, value;
    criteriaEmpty = true;
    for (key in criteria) {
      value = criteria[key];
      criteriaEmpty = false;
      if (relation[key] !== value) {
        return false;
      }
    }
    if (!criteriaEmpty) {
      return true;
    }
    for (key in relation) {
      value = relation[key];
      return false;
    }
    return true;
  };

  return RelationalIndex;

})();

var RelationalModel,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

RelationalModel = (function() {
  RelationalModel.CREATED = 'created';

  RelationalModel.UPDATED = 'updated';

  function RelationalModel(data, staticSelf, eventStream) {
    this.staticSelf = staticSelf;
    this.eventStream = eventStream;
    this.pushEvent = __bind(this.pushEvent, this);
    this.hasRelationalChanges = __bind(this.hasRelationalChanges, this);
    this.update = __bind(this.update, this);
    this.storeAssociatedModel = __bind(this.storeAssociatedModel, this);
    this.filterModelStream = __bind(this.filterModelStream, this);
    if (data) {
      this.update(data, true);
    }
    if (!this.eventStream) {
      throw new Error("eventStream missing");
    }
    this.defineRelationProperties();
    this.associatedModelStream = this.eventStream.filter(this.filterModelStream);
    this.associatedModelStream.onValue(this.storeAssociatedModel);
    if (!this.staticSelf.relationalIndex.isEmpty()) {
      this.pushEvent(RelationalModel.CREATED);
    }
  }

  RelationalModel.prototype.filterModelStream = function(data) {
    var relation, _i, _len, _ref;
    _ref = this.staticSelf.relationalIndex.find(data.model);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      relation = _ref[_i];
      if (relation.keyInSelf) {
        if (data.object.id === this[relation.key]) {
          return true;
        }
      } else {
        if (data.object[relation.key] === this.id) {
          return true;
        }
      }
    }
    return false;
  };

  RelationalModel.prototype.defineRelationProperties = function() {
    var relation, _i, _len, _name, _ref, _results;
    _ref = this.staticSelf.relationalIndex.all();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      relation = _ref[_i];
      _results.push(this[_name = relation.property] || (this[_name] = {}));
    }
    return _results;
  };

  RelationalModel.prototype.storeAssociatedModel = function(data) {
    var inverse, relation, relations, _i, _j, _len, _len1, _results;
    relations = this.staticSelf.relationalIndex.find(data.model);
    if (!relations.length) {
      return;
    }
    for (_i = 0, _len = relations.length; _i < _len; _i++) {
      relation = relations[_i];
      this.staticSelf.setAssociatedModel(this, relation.property, data.object, relation.type);
    }
    inverse = data.object.staticSelf.relationalIndex.find({
      model: this.staticSelf.name,
      key: relation.key,
      keyInSelf: !relation.keyInSelf
    });
    if (!inverse.length) {
      return;
    }
    _results = [];
    for (_j = 0, _len1 = inverse.length; _j < _len1; _j++) {
      relation = inverse[_j];
      _results.push(this.staticSelf.setAssociatedModel(data.object, relation.property, this, relation.type));
    }
    return _results;
  };

  RelationalModel.prototype.update = function(data, silent) {
    var changed, property, relation, value, _i, _len, _ref;
    if (silent == null) {
      silent = false;
    }
    changed = this.hasRelationalChanges(data);
    for (property in data) {
      value = data[property];
      this[property] = value;
    }
    _ref = this.staticSelf.relationalIndex.all();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      relation = _ref[_i];
      for (property in data) {
        value = data[property];
        if (relation.property === property) {
          this[relation.key] = value.id;
        }
      }
    }
    if (!silent && changed) {
      return this.pushEvent(RelationalModel.UPDATED);
    }
  };

  RelationalModel.prototype.hasRelationalChanges = function(data) {
    var changed, property, value;
    for (property in data) {
      value = data[property];
      changed = this[property] !== value;
      if (!changed) {
        continue;
      }
      if (this.staticSelf.relationalIndex.has({
        key: property,
        keyInSelf: true
      })) {
        return true;
      }
    }
    return false;
  };

  RelationalModel.prototype.pushEvent = function(type) {
    var _ref;
    return (_ref = this.eventStream) != null ? _ref.push({
      event: type,
      model: this.staticSelf.name,
      id: this.id,
      object: this
    }) : void 0;
  };

  RelationalModel.initialize = function(name) {
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

  RelationalModel.generateKeyFromModelName = function(modelName) {
    return "" + (modelName.charAt(0).toLowerCase()) + (modelName.slice(1)) + "ID";
  };

  RelationalModel.hasMany = function(property, modelName, options) {
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

  RelationalModel.hasOne = function(property, modelName, options) {
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

  RelationalModel.belongsTo = function(property, modelName, options) {
    var clonedOptions, key, value;
    if (options == null) {
      options = {};
    }
    clonedOptions = {};
    for (key in options) {
      value = options[key];
      clonedOptions[key] = value;
    }
    if (options.keyInSelf !== false) {
      clonedOptions.keyInSelf = true;
    }
    return this.hasOne(property, modelName, clonedOptions);
  };

  RelationalModel.setAssociatedModel = function(object, property, value, type) {
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

  return RelationalModel;

})();
