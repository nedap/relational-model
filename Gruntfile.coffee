
module.exports = ( grunt ) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'bower.json'

    coffee:
      default:
        files:
          'dist/<%= pkg.name %>.js': [ 'src/angular_orm.coffee',
                                       'src/relational_index.coffee',
                                       'src/model.coffee' ]
        options:
          bare: false

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.registerTask "default", ["coffee"]
