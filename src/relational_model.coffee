
class RelationalModel
  @CREATED: 'created'
  @UPDATED: 'updated'

  constructor: ( data, @staticSelf, @eventStream ) ->
    @update data, true if data

    throw new Error "eventStream missing" unless @eventStream

    @associatedModelStream = @eventStream.filter @filterModelStream
    @associatedModelStream.onValue @storeAssociatedModel

    unless @staticSelf.relationalIndex.isEmpty()
      @initializeRelationalProperties()
      @pushEvent RelationalModel.CREATED

  initializeRelationalProperties: ->
    for relation in @staticSelf.relationalIndex.all()
      @staticSelf.initializeAssociation this, relation.property, relation.type

  filterModelStream: ( data ) =>
    for relation in @staticSelf.relationalIndex.find data.model
      if relation.keyInSelf
        return true if data.object.id == @[relation.key]
      else
        return true if data.object[ relation.key ] == @id
    return false

  storeAssociatedModel: ( data ) =>
    relations = @staticSelf.relationalIndex.find data.model
    return unless relations.length
    @staticSelf.setAssociatedModel this, relation.property, data.object, relation.type for relation in relations

    inverse = data.object.staticSelf.relationalIndex.find model: @staticSelf.name, key: relation.key, keyInSelf: !relation.keyInSelf
    return unless inverse.length
    @staticSelf.setAssociatedModel data.object, relation.property, this, relation.type for relation in inverse

  update: ( data, silent=false ) =>
    changed = @hasRelationalChanges data
    @[property] = value for property, value of data
    # if instead of the key, the model is given, assign the key
    for relation in @staticSelf.relationalIndex.all()
      for property, value of data
        if relation.property == property
          @[relation.key] = value.id
    if !silent && changed
      @pushEvent RelationalModel.UPDATED

  hasRelationalChanges: ( data ) =>
    for property, value of data
      changed = @[property] != value
      continue unless changed
      return true if @staticSelf.relationalIndex.has key: property, keyInSelf: true
    return false

  pushEvent: ( type ) =>
    @eventStream?.push event: type, model: @staticSelf.name, id: @id, object: this

  @initialize: ( name=@name ) ->
    @name = name
    @defaultKey = @generateKeyFromModelName @name
    if @relationalIndex
      @relationalIndex = @relationalIndex.clone()
    else
      @relationalIndex = new RelationalIndex

  @generateKeyFromModelName: ( modelName ) ->
    "#{ modelName.charAt(0).toLowerCase() }#{ modelName.slice(1) }ID"

  @hasMany: ( property, modelName, options={} ) ->
    throw new Error "Cannot add relations to uninitialized class, call initialize() first." unless @relationalIndex
    key = options.key || @generateKeyFromModelName @name
    @relationalIndex.add property, modelName, RelationalIndex.MANY, key, false

  @hasOne: ( property, modelName, options={} ) ->
    throw new Error "Cannot add relations to uninitialized class, call initialize() first." unless @relationalIndex
    keyInSelf = options.keyInSelf != false
    nameForKey = if keyInSelf then modelName else @name
    key = options.key || @generateKeyFromModelName nameForKey
    @relationalIndex.add property, modelName, RelationalIndex.ONE, key, keyInSelf

  @belongsTo: ( property, modelName, options={} ) ->
    clonedOptions = {}
    clonedOptions[key] = value for key, value of options
    clonedOptions.keyInSelf = true unless options.keyInSelf == false
    @hasOne property, modelName, clonedOptions

  @setAssociatedModel: ( object, property, value, type ) =>
    switch type
      when RelationalIndex.ONE
        object[property] = value
      when RelationalIndex.MANY
        object[property] ||= {}
        object[property][value.id] = value
      else
        throw new Error "Uknown relation-type"

  @initializeAssociation: ( object, property, type ) =>
    switch type
      when RelationalIndex.ONE
        break
      when RelationalIndex.MANY
        object[property] ||= {}
      else
        throw new Error "Uknown relation-type"
