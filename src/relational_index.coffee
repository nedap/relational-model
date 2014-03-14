
class RelationalIndex
  @MANY: 'many'
  @ONE:  'one'

  constructor: ( data ) ->
    @relations = {}
    @relations[model] = rel.slice() for model, rel of data if data

  clone: =>
    new RelationalIndex @relations

  add: ( property, modelName, type, key, keyInSelf=false ) =>
    @relations[modelName] ||= []
    @relations[modelName].push { model: modelName, property: property, type: type, key: key, keyInSelf: keyInSelf }

  has: ( options ) =>
    throw new Error "Missing argument" unless options
    if typeof options == 'string'
      return @relations[options]?.length > 0
    for model, rels of @relations
      for relation in rels
        return true if RelationalIndex.matches relation, options
    return false

  find: ( options ) =>
    return @all() unless options
    if typeof options == 'string'
      return @relations[ options ] || []
    values = []
    for model, rels of @relations
      for relation in rels
        values.push relation if RelationalIndex.matches relation, options
    return values

  all: =>
    values = []
    values.push rels... for model, rels of @relations
    return values

  isEmpty: =>
    return false for model of @relations
    return true

  @matches: ( relation, criteria ) =>
    criteriaEmpty = true
    for key, value of criteria
      criteriaEmpty = false
      return false unless relation[key] == value
    return true unless criteriaEmpty
    for key, value of relation
      return false
    return true
