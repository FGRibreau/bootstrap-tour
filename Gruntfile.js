/*global module:false*/
module.exports = function(grunt) {
  // grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-shell');

  // Project configuration.
  grunt.initConfig({
    pkg: '<json:package.json>',
    concat: {
      dist: {
        src: ['<banner:meta.banner>', 'lib/bootstrap-tour.js'],
        dest: 'dist/<%= pkg.name %>.js'
      }
    },
    min: {
      dist: {
        src: ['<banner:meta.banner>', '<config:concat.dist.dest>'],
        dest: 'dist/<%= pkg.name %>.min.js'
      }
    },
    qunit: {
      files: ['test/**/*.html']
    },
    coffee: {
      lib: {
        src: 'src/*.coffee',
        dest: 'lib/',
        options: {
            bare: true
        }
      },
      test: {
        src: 'test/*.coffee',
        dest: 'test/',
        options: {
            bare: true
        }
      }
    },
    shell: {
      dox:{
        command:'./node_modules/dox/bin/dox < lib/bootstrap-tour.js > docs/api.json',
        stdout:true,
        stderr:true
      },
      doxx:{//
        command:'./node_modules/doxx/bin/doxx --template docs/template.jade --source lib --target docs',
        stdout:true,
        stderr:true
      }
    },
    lint: {
      files: ['grunt.js', 'src/**/*.js']
    },
    watch: {
      files: ['docs/*.jade', 'src/*.coffee', 'test/*.coffee'], // lint qunit
      tasks: 'coffee:lib coffee:test shell:doxx shell:dox'
    },
    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        boss: true,
        eqnull: true,
        browser: true
      },
      globals: {
        Tour:true,
        jQuery: true,
        module:true,
        $:true,
        equal:true,
        test:true,
        ok:true,
        deepEqual:true,
        strictEqual:true
      }
    },
    uglify: {}
  });

  // Default task.
  grunt.registerTask('default', 'lint qunit concat min');
  grunt.registerTask('compile', 'coffee:lib coffee:test');

};
