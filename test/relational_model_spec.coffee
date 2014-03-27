#= require spec_helper

describe 'RelationalModel', ->

  beforeEach ->
    @id = 'abc123'

    @fakeEventStream = {}
    @fakeEventStream.push = ->
    @fakeEventStream.onValue = ->
    @fakeEventStream.filter = => @fakeEventStream

    class @SubClass extends RelationalModel
      @initialize()
      constructor: ( data, stream ) ->
        super data, SubClass, stream

    @data = { id: @id, childID: '33', someProperty: 'what' }
    @subject = new @SubClass( @data, @fakeEventStream )

  describe "its constructor", ->
    beforeEach ->
      class @SomeClass extends RelationalModel
        @initialize()
        constructor: ( data={}, eventStream ) ->
          super data, SomeClass, eventStream

    it "constructor its eventStream-parameter is required", ->
      expect( => new @SomeClass( null )).toThrow()

    it 'defines its model properties', ->
      @SomeClass.hasOne 'child1', 'Child'
      @SomeClass.hasOne 'child2', 'Child'
      instance = new @SomeClass( {}, @fakeEventStream )
      expect( instance.child1 ).toBeDefined()
      expect( instance.child2 ).toBeDefined()

  it "extends data", ->
    expect( @subject.id ).toEqual @data.id
    expect( @subject.childID ).toEqual @data.childID
    expect( @subject.someProperty ).toEqual @data.someProperty

  it "knows if updates involve relational changes", ->
    @SubClass.hasOne 'child', 'Child'
    expect( @subject.hasRelationalChanges someProperty: 'something else' ).toEqual false
    expect( @subject.hasRelationalChanges childID: @subject.childID ).toEqual false
    expect( @subject.hasRelationalChanges childID: '77' ).toEqual true

  it "pushes events", ->
    spyOn @fakeEventStream, 'push'
    type = 'something'
    @subject.pushEvent type
    expect( @fakeEventStream.push ).toHaveBeenCalledWith { event: type, model: @SubClass.name, id: @subject.id, object: @subject }

  it "filters other models", ->
    @SubClass.hasMany 'children', 'Child', key: 'someID'
    expect( @subject.filterModelStream( model: 'Child', object: { someID: @id })).toEqual true
    expect( @subject.filterModelStream( model: 'Child', object: { someID: 'bla' })).toEqual false
    expect( @subject.filterModelStream( model: 'Other', object: { someID: @id })).toEqual false

  it "its model-stream is filtered", ->
    spyOn( @fakeEventStream, 'filter' ).and.callThrough()
    obj = new @SubClass( id: @id, @fakeEventStream )
    expect( @fakeEventStream.filter ).toHaveBeenCalledWith obj.filterModelStream

  it "watches model-stream for newly created models", ->
    spyOn @fakeEventStream, 'onValue'
    expect( @fakeEventStream.onValue ).not.toHaveBeenCalled()
    obj = new @SubClass( id: @id, @fakeEventStream )
    expect( @fakeEventStream.onValue ).toHaveBeenCalledWith obj.storeAssociatedModel



  describe "in regards to events", ->
    beforeEach ->
      @SubClass.hasOne 'child', 'Child'
      spyOn @subject, 'pushEvent'

    it "notifies on creation", ->
      @data.pushEvent = ( type ) ->
      spyOn @data, 'pushEvent'
      obj = new @SubClass( @data, @fakeEventStream )
      expect( obj.pushEvent ).toHaveBeenCalledWith RelationalModel.CREATED

    it "doesn't notify on creation without any relations", ->
      class OtherClass extends RelationalModel
        constructor: -> super

      @data.pushEvent = ( type ) ->
      spyOn @data, 'pushEvent'
      OtherClass.initialize()
      obj = new OtherClass( @data, OtherClass, @fakeEventStream )
      expect( obj.pushEvent ).not.toHaveBeenCalled()

    it "updates", ->
      @subject.update someProperty: 'yeah'
      expect( @subject.someProperty ).toEqual 'yeah'

    it "notifies on updates involving relations", ->
      @subject.update childID: '66'
      expect( @subject.pushEvent ).toHaveBeenCalledWith RelationalModel.UPDATED

    it "doesn't notify on updates not involving relations", ->
      @subject.update someProperty: 'something else'
      expect( @subject.pushEvent ).not.toHaveBeenCalled()

    it "doesn't notify on silent updates", ->
      @subject.update childID: '66', true
      expect( @subject.pushEvent ).not.toHaveBeenCalled()



  describe "its relational-index", ->
    beforeEach ->
      spyOn @SubClass.relationalIndex, 'add'

    it "is created on a class-level", ->
      class Organism extends RelationalModel
        @initialize()

      class Amoeba extends Organism
        @initialize()
        @hasMany 'children', 'Child'

      expect( Organism.relationalIndex.relations ).not.toEqual Amoeba.relationalIndex.relations

    it "is cloned from the super-class", ->
      class Organism extends RelationalModel
        @initialize()
        @hasMany 'children', 'Child'

      class Amoeba extends Organism
        @initialize()

      expect( Amoeba.relationalIndex.relations ).toEqual Organism.relationalIndex.relations

      Amoeba.hasOne 'job', 'Job'
      expect( Amoeba.relationalIndex.relations ).not.toEqual Organism.relationalIndex.relations

    it "is invoked for has-many relations", ->
      property  = 'children'
      modelName = 'Child'
      key       = 'some_id'

      @SubClass.hasMany property, modelName, key: key, keyInSelf: true
      expect( @SubClass.relationalIndex.add ).toHaveBeenCalledWith property, modelName, RelationalIndex.MANY, key, false # keyInSelf needs to be false for one-to-many relations

    it "is invoked for has-one relations", ->
      property  = 'child'
      modelName = 'Child'
      key       = 'some_id'
      keyInSelf = false

      @SubClass.hasOne property, modelName, key: key, keyInSelf: keyInSelf
      expect( @SubClass.relationalIndex.add ).toHaveBeenCalledWith property, modelName, RelationalIndex.ONE, key, keyInSelf

    it "is invoked for belongs-to relations", ->
      property  = 'child'
      modelName = 'Child'
      key       = 'some_id'
      keyInSelf = true

      @SubClass.belongsTo property, modelName, key: key, keyInSelf: keyInSelf
      expect( @SubClass.relationalIndex.add ).toHaveBeenCalledWith property, modelName, RelationalIndex.ONE, key, keyInSelf

    it "isn't invoked before relations are made", ->
      expect( @SubClass.relationalIndex.add ).not.toHaveBeenCalled()

    it "throws an error when uninitialized", ->
      class UninitializedClass extends RelationalModel
      expect( -> UninitializedClass.hasMany 'children', 'Child' ).toThrow()
      expect( -> UninitializedClass.hasOne     'child', 'Child' ).toThrow()
      expect( -> UninitializedClass.belongsTo  'child', 'Child' ).toThrow()



  describe "its storeAssociatedModel() method", ->
    beforeEach ->
      spyOn @SubClass, 'setAssociatedModel'
      @relatedModel = { id: '33', staticSelf: { relationalIndex: { find: -> []}}}

    it "attempts to retrieve relations", ->
      modelName = 'Child'

      spyOn( @SubClass.relationalIndex, 'find' ).and.returnValue []
      @subject.storeAssociatedModel model: modelName, id: @relatedModel.id, object: @relatedModel

      expect( @SubClass.relationalIndex.find ).toHaveBeenCalledWith modelName
      expect( @SubClass.setAssociatedModel ).not.toHaveBeenCalled() # .relationalIndex.get() was stubbed to return nothing, so setAssociatedModel shouldn't be called

    it "calls setAssociatedModel() for relations", ->
      modelName = 'Child'
      property = 'children'

      spyOn( @SubClass.relationalIndex, 'find' ).and.returnValue [{ model: modelName, property: property, type: RelationalIndex.MANY }]
      @subject.storeAssociatedModel model: modelName, object: @relatedModel

      expect( @SubClass.setAssociatedModel ).toHaveBeenCalledWith @subject, property, @relatedModel, RelationalIndex.MANY

    it "attempts to retrieve inverse relations", ->
      modelName = 'Child'
      key = 'otherModelID'

      spyOn( @SubClass.relationalIndex, 'find' ).and.returnValue [{ key: key, keyInSelf: false }]
      spyOn( @relatedModel.staticSelf.relationalIndex, 'find' ).and.returnValue []
      @subject.storeAssociatedModel model: modelName, object: @relatedModel

      expect( @relatedModel.staticSelf.relationalIndex.find ).toHaveBeenCalledWith { model: @SubClass.name, key: key, keyInSelf: true }
      expect( @SubClass.setAssociatedModel.calls.count() ).toEqual 1 # related object its relationalIndex.get() was stubbed to return nothing, so setAssociatedModel should've only been called for @subject itself

    it "calls setAssociatedModel() for inverse relations", ->
      modelName = 'Child'
      key = 'otherModelID'
      property = 'otherModel'

      spyOn( @SubClass.relationalIndex, 'find' ).and.returnValue [{ key: key, keyInSelf: false }]
      spyOn( @relatedModel.staticSelf.relationalIndex, 'find' ).and.returnValue [{ property: property, type: RelationalIndex.ONE }]
      @subject.storeAssociatedModel model: modelName, object: @relatedModel

      expect( @SubClass.setAssociatedModel ).toHaveBeenCalledWith @relatedModel, property, @subject, RelationalIndex.ONE



  describe "its setAssociatedModel() method", ->
    it "sets properties for one-to-one relations", ->
      property = 'prop'
      value = 'value'
      obj = {}
      obj[property] = 'something else'

      RelationalModel.setAssociatedModel obj, property, value, RelationalIndex.ONE
      expect( obj[property] ).toEqual value

    it "sets properties for one-to-many relations", ->
      property = 'prop'
      value1 = { id: 66, value: 'one' }
      value2 = { id: 99, value: 'two' }
      obj = {}

      RelationalModel.setAssociatedModel obj, property, value1, RelationalIndex.MANY
      expect( obj[property] ).toBeDefined()
      expect( obj[property][value1.id] ).toEqual value1

      obj[property][value2.id] = { id: value2.id, value: 'pre-existing value' }
      RelationalModel.setAssociatedModel obj, property, value2, RelationalIndex.MANY
      expect( obj[property][value2.id] ).toEqual value2

    it "throws an error for unknown relation-types", ->
      expect( -> RelationalModel.setAssociatedModel {}, 'prop', 'value', 'bullshit' ).toThrow()
