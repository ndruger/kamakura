module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
      compile: {
        expand: true,
        bare: true,
        cwd: 'src/',
        src: '**/*.coffee',
        dest: 'lib',
        ext: '.js',
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');

  grunt.registerTask('default', 'coffee');
};
