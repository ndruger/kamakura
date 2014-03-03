var Fiber = require('fibers');
var webdriver = require('selenium-webdriver');
var _ = require('lodash');

var env = {};

function Kamakura(params) {
  var self = this;
  var Capabilities = params.capabilities || Kamakura.Capabilities.chrome();
  self._driver = new webdriver.Builder().
    withCapabilities(webdriver.Capabilities.chrome()).
    build();
}
Kamakura.Capabilities = webdriver.Capabilities;
Kamakura.prototype.goTo = function(url) {
  var self = this;
  self._driver.get(url);
};

var run = function(f) {
  var fiber = Fiber(function() {
    var next = function(x) { fiber.run(x); };
    f(next);
  });
  fiber.run();
};

Kamakura.prototype.run = function(f) {
  var self = this;
  var fiber = Fiber(function() {
    var next = function(x) { fiber.run(x); };
    self.next = next;
    f(next);
  });
  fiber.run();
};
Kamakura.prototype.find = function(css, opt_next) {
  var self = this;
  next = opt_next || self.next;

  self._driver.findElement(webdriver.By.css(css)).then(function(el) {
    next(new KamakuraElement(el, self));
  });

  return Fiber.yield();
};
Kamakura.prototype.destroy = function() {
};

function KamakuraElement(webdriverElement, km) {
  var self = this;
  // webdriver.WebElement
  self._orig = webdriverElement;
  self._km = km;
}
_.each(['click'], function(name) {
  KamakuraElement.prototype[name] = function(args) {
    return this._orig[name].apply(this._orig, arguments);
  };
});
// TODO: fix
KamakuraElement.prototype.getText = function(opt_next) {
  var self = this;
  var next = opt_next || self._km.next;

  self._orig.getText().then(function(t) {
    next(t);
  });

  return Fiber.yield();
};
KamakuraElement.prototype.shouldHaveText = function(text, opt_next) {
  var self = this;
  var next = opt_next || self._km.next;
  console.log('shouldHaveText');
  
  var timer = setInterval(function() {
    run(function(aNext) {
      var t = self.getText(aNext);
      console.log(t, text);
      if (t !== text) {
        return;
      }
      clearInterval(timer);
      next(true);
    });
  }, 100);
  
  return Fiber.yield();
};

module.exports = {
  create: function(params) {
    return new Kamakura(params);
  }
};
