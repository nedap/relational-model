
angular.module 'angular-orm'
.factory 'RelationalIndex', ->

  class RelationalIndex
    @MANY: 'many'
    @ONE:  'one'

    constructor: ( data ) ->
      if data
        @relations = Object.clone data, true
      else
        @relations = {}

    clone: =>
      new RelationalIndex @relations

    add: ( property, modelName, type, key, keyInSelf=false ) =>
      @relations[ modelName ] = { model: modelName, property: property, type: type, key: key, keyInSelf: keyInSelf }

    has: ( modelName ) =>
      @relations[ modelName ]?

    get: ( modelName ) =>
      @relations[ modelName ]

    find: ( options ) =>
      @relations[ Object.find @relations, options ]

    all: ( options ) =>
      return _.values @relations unless options

      values = []
      keys = _.keys options

      for model, relation of @relations
        subset  = _.pick relation, keys...
        matches = _.isEqual subset, options
        values.push relation if matches

      return values

    isEmpty: =>
      !_.keys( @relations ).length
