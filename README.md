relational-model
===========

# Example

```coffeescript
class Person extends Model
  @initialize()
  @hasMany 'messages', 'Message'
  
  constructor: ->
    super Person

class Message extends Model
  @initialize()
  @belongsTo 'person', 'Person'
  
  constructor: ->
    super Message
```

# API

Extending the Model class in CoffeeScript will add the following static methods to your subclass:

## initialize

`initialize()`

Initializes your class with it's own relational index. Make a habit of calling this for every Model-subclass. If you forget to call this method for subclasses of classes with associations, the subclasses its associations will be made on its superclass. *tl;dr*: unexpectedbehaviorocalypse.

## hasOne()
`hasOne( property, modelName, options={} )`

* `property` is the name property that will be defined on your model.
* `modelName` is the name of the data-type that will fill this property.
* `options`:
  * `key` is the foreign key of the association
  * `keyInSelf` determines where the foreign key is. `true` (default) means on the model from which you call `hasOne()`. `false` means on the model that has `modelName` as its name.

## hasMany()

`hasMany( property, modelName, options={} )`

Same signature/options as `hasOne()`, except that `options.keyInSelf` is always `false`.

## belongsTo()

`belongsTo( property, modelName, options={} )`

*Alias for `hasOne()`.*
