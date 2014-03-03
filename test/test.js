var kamakura = require('../lib/kamakura');
var km = kamakura.create();

km.run(function(next) {
  km.goTo('http://127.0.0.1/');
  km.find('.test').click();
  km.find('.result').shouldHaveText('result');
});
