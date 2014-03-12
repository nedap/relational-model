
class AngularMock
  module: => return this
  extend: ( args... ) => _.extend args...
  factory: ( name, definition ) =>
    if definition
      definition = [ definition ] unless Array.isArray definition
      @factories ||= {}
      @factories[ name ] = definition
    else
      if definition = @factories?[ name ]
        dependencies = []
        dependencies.push @factory dependency for dependency in definition.slice 0, definition.length-1
        f = definition[ definition.length-1 ]
        return f.apply this, dependencies
    return null

angular = new AngularMock

beforeEach ->
  @factory = angular.factory
  @module  = angular.module
  @isArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
  @inspect = ( obj, recursive=true, newlines=true ) =>
    if @isArray obj
      '[ '+( "#{ @inspect value, false }" for value in obj ).join(", #{ if newlines then '\n    ' else ' ' }")+" ]"
    else if obj?.toString?() == '[object Object]'
      '{ '+( "#{prop}: #{ if recursive || typeof( obj[prop] ) == 'function' then @inspect obj[prop] else obj[prop] }" for prop of obj ).join(", #{ if newlines then '\n    ' else ' ' }")+" }"
    else if typeof( obj ) == 'function'
      'function(){...}'
    else
      obj
