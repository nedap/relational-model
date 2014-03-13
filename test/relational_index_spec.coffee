#= require spec_helper

describe 'RelationalIndex', ->

  beforeEach ->
    @subject = new RelationalIndex

    @modelName = 'SomeModel'
    @property  = 'myProperty'
    @key       = 'otherModelID'
    @keyInSelf = true
    @type      = RelationalIndex.ONE

    @storedObject = { property: @property, model: @modelName, type: @type, key: @key, keyInSelf: @keyInSelf }

  it "has relations", ->
    relations = {}
    relations[ @modelName ] = {}
    @subject = new RelationalIndex( relations )
    expect( @subject.has @modelName ).toEqual true

  it "adds relations", ->
    expect( @subject.has @modelName ).toEqual false
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    expect( @subject.has @modelName ).toEqual true

  it "gets relations", ->
    expect( @subject.get @modelName ).toBeUndefined()
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    expect( @subject.get @modelName ).toEqual jasmine.objectContaining @storedObject

  it "gets all relations", ->

    expect( @subject.all() ).toEqual []

    one   = { property: 'one',   model: 'A', type: RelationalIndex.ONE,  key: 'one_id',   keyInSelf: false }
    two   = { property: 'one',   model: 'B', type: RelationalIndex.MANY, key: 'two_id',   keyInSelf: true }
    @subject.add one.property,   one.model,   one.type,   one.key,   one.keyInSelf
    @subject.add two.property,   two.model,   two.type,   two.key,   two.keyInSelf

    # TODO: NEEDS =~
    all = @subject.all()
    expect( all.length ).toEqual 2
    expect( all ).toContain one
    expect( all ).toContain two

  it "finds relations", ->
    expect( @subject.find model: @modelName ).toBeUndefined()
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    expect( @subject.find model: @modelName ).toEqual jasmine.objectContaining @storedObject

  it "finds all relations", ->
    expect( @subject.all() ).toEqual []

    one   = { property: 'one',   model: 'A', type: RelationalIndex.ONE,  key: 'one_id',   keyInSelf: false }
    two   = { property: 'two',   model: 'B', type: RelationalIndex.MANY, key: 'two_id',   keyInSelf: true }
    three = { property: 'three', model: 'C', type: RelationalIndex.ONE,  key: 'three_id', keyInSelf: true }

    @subject.add one.property,   one.model,   one.type,   one.key,   one.keyInSelf
    @subject.add two.property,   two.model,   two.type,   two.key,   two.keyInSelf
    @subject.add three.property, three.model, three.type, three.key, three.keyInSelf

    expect( @subject.all property: 'one'   ).toEqual [ one ]
    expect( @subject.all property: 'two'   ).toEqual [ two ]
    expect( @subject.all property: 'three' ).toEqual [ three ]

    expect( @subject.all keyInSelf: true ).toEqual [ two, three ]
    expect( @subject.all type: RelationalIndex.ONE ).toEqual [ one, three ]
    expect( @subject.all type: RelationalIndex.ONE, keyInSelf: true ).toEqual [ three ]

  it "clones", ->
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    clone = @subject.clone()
    clone.has @modelName

  it "knows when its empty", ->
    expect( @subject.isEmpty() ).toEqual true
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    expect( @subject.isEmpty() ).toEqual false
