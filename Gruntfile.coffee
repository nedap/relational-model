
module.exports = ( grunt ) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    filename: '<% pkg.name %>'

    coffee:
      default:
        options:
          bare: true
        files:
          'dist/<%= pkg.name %>.js': [ 'src/angular_orm.coffee', 'src/relational_index.coffee', 'src/model.coffee' ]
      test:
        expand: true
        src: [ 'src/**/*.coffee', 'test/**/*.coffee' ]
        dest: 'tmp'
        ext: '.js'
        options:
          bare: true

    clean: [ 'tmp' ]

    jasmine:
      default:
        src: [ 'lib/**/*.js', 'tmp/src/**/*.js' ]
        options:
          specs: 'tmp/test/**/*_spec.js'
          helpers: [ 'tmp/test/**/*_helper.js' ]

    bower:
      install: {}

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'build',   [ 'coffee' ]
  grunt.registerTask 'test',    [ 'coffee:test', 'jasmine', 'clean' ]
  grunt.registerTask 'install', [ 'bower:install' ]
