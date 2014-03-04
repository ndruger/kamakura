module.exports = (grunt) ->
  grunt.initConfig(
    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: 'coffee:src'
      test:
        files: ['test/**/*.coffee']
        tasks: 'coffee:test'
    coffee:
      src:
        files: [
          expand: true
          bare: true
          cwd: 'src/'
          src: '**/*.coffee'
          dest: 'lib'
          ext: '.js'
        ]
      test:
        files: [
          expand: true
          bare: true
          cwd: 'test/'
          src: '**/*.coffee'
          dest: 'test'
          ext: '.js'
        ]
  )
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.registerTask('default', ['watch'])


