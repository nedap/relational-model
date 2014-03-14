#= require spec_helper

describe 'RelationalIndex', ->

  beforeEach ->
    @subject = new RelationalIndex

    @rel1 = { property: 'one', model: 'A', type: RelationalIndex.ONE,  key: 'one_id', keyInSelf: false }
    @rel2 = { property: 'two', model: 'B', type: RelationalIndex.MANY, key: 'two_id', keyInSelf: true }

    @add = ( rel ) -> @subject.add rel.property, rel.model, rel.type, rel.key, rel.keyInSelf

  it "has relations", ->
    relations = {}
    relations[ @rel1.model ] = [ @rel1 ]
    @subject = new RelationalIndex( relations )

    expect( @subject.has @rel1.model ).toEqual true
    expect( @subject.has property: @rel1.property ).toEqual true
    expect( @subject.has 'non-existent' ).toEqual false
    expect( @subject.has property: 'nothing' ).toEqual false

  it "adds relations", ->
    expect( @subject.has @rel1.model ).toEqual false
    @add( @rel1 )
    expect( @subject.has @rel1.model ).toEqual true

  it "finds relations by model-name", ->
    expect( @subject.find @rel1.model ).toEqual []
    @add( @rel1 )
    expect( @subject.find @rel1.model ).toEqual [ jasmine.objectContaining( @rel1 ) ]

    @rel2.model = @rel1.model
    @add( @rel2 )
    expect( @subject.find @rel1.model ).toEqual [ jasmine.objectContaining( @rel1 ), jasmine.objectContaining( @rel2 )]

  it "finds relations by properties", ->
    expect( @subject.find property: @rel1.property, type: @rel1.type ).toEqual []
    @add( @rel1 )
    expect( @subject.find property: @rel1.property, type: @rel1.type ).toEqual [ jasmine.objectContaining @rel1 ]
    @add( @rel2 )
    expect( @subject.find property: @rel1.property, type: @rel1.type ).toEqual [ jasmine.objectContaining @rel1 ]

  it "gets all relations", ->
    expect( @subject.all() ).toEqual []
    @add( @rel1 )
    @add( @rel2 )
    expect( @subject.all() ).toEqual [ jasmine.objectContaining( @rel1 ), jasmine.objectContaining( @rel2 )]

  it "clones", ->
    @add( @rel1 )
    clone = @subject.clone()
    expect( clone.has @rel1.model ).toEqual true

  it "knows when its empty", ->
    expect( @subject.isEmpty() ).toEqual true
    @subject.add @property, @modelName, @type, @key, @keyInSelf
    expect( @subject.isEmpty() ).toEqual false

  it "recognizes partial matches", ->
    obj = { a: 'aye', b: 'bee', one: 1 }
    one1 = { one: 1 }
    one2 = { one: 2 }
    aAyeBBee = { a: 'aye', b: 'bee' }
    aCeeBDee = { a: 'cee', b: 'dee' }
    empty = {}

    expect( RelationalIndex.matches obj, obj ).toEqual true
    expect( RelationalIndex.matches obj, one1 ).toEqual true
    expect( RelationalIndex.matches obj, one2 ).toEqual false
    expect( RelationalIndex.matches obj, aAyeBBee ).toEqual true
    expect( RelationalIndex.matches obj, aCeeBDee ).toEqual false
    expect( RelationalIndex.matches obj, empty ).toEqual false
    expect( RelationalIndex.matches empty, obj ).toEqual false
