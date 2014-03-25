relational-model
===========

Allows for one-to-one and one-to-many relations to automatically be established upon instantiation of your models.

The only dependency of this library is [Bacon.js](github.com/baconjs/bacon.js). A `Bacon.Bus` is used to pass created/updated/destroyed notifications between related models.

# Example

```coffeescript

class Person extends RelationalModel
  @initialize()
  @hasMany 'messages', 'Message'

  constructor: ( @id, notifications ) ->
    super Person, notifications

class Message extends RelationalModel
  @initialize()
  @belongsTo 'person', 'Person'

  constructor: ( @id, @personID, notifications ) ->
    super Message, notifications

bus = new Bacon.Bus()

ruben = new Person( 'x', bus )
message1 = new Message( 'a', 'x', bus )
message2 = new Message( 'b', 'x', bus )

ruben.messages # returns { a: message1, b: message2 }
message1.person # returns ruben
message2.person # returns ruben
```

# Install

Using [Bower](http://bower.io):

```
bower install relational-model
```

# API

Extending the RelationaModel class in CoffeeScript will add the following static methods to your subclass:

## initialize

`initialize()`

Initializes your class with it's own relational index. Make a habit of calling this for every RelationaModel-subclass. If you forget to call this method for subclasses of classes with associations, the subclasses its associations will be made on its superclass. *tl;dr*: unexpectedbehaviorocalypse.

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
