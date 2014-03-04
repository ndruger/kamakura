kamakura = require('../lib/kamakura')
address = require('./server')()
km = kamakura.create()

km.run((next) =>
  km.goto("http://#{address.address}:#{address.port}");
  km.find('button').click();
  km.find('.result').shouldHaveText('pushed');
)

