(function() {
  var Fiber, Kamakura, KamakuraElement, run, webdriver, _;

  Fiber = require('fibers');

  webdriver = require('selenium-webdriver');

  _ = require('lodash');

  run = function(f) {
    var fiber;
    fiber = Fiber((function(_this) {
      return function() {
        var next;
        next = function(x) {
          return fiber.run(x);
        };
        return f(next);
      };
    })(this));
    return fiber.run();
  };

  Kamakura = (function() {
    function Kamakura(opt_params) {
      var Capabilities;
      Capabilities = (opt_params && opt_params.capabilities) || Kamakura.Capabilities.chrome();
      this._driver = new webdriver.Builder().withCapabilities(webdriver.Capabilities.chrome()).build();
    }

    Kamakura.prototype.goTo = function(url) {
      console.log(url);
      return this._driver.get(url);
    };

    Kamakura.prototype.run = function(f) {
      var fiber;
      fiber = Fiber((function(_this) {
        return function() {
          var next;
          next = function(x) {
            return fiber.run(x);
          };
          _this.next = next;
          return f(next);
        };
      })(this));
      return fiber.run();
    };

    Kamakura.prototype.find = function(css, opt_next) {
      var next;
      next = opt_next || this.next;
      this._driver.findElement(webdriver.By.css(css)).then((function(_this) {
        return function(el) {
          return next(new KamakuraElement(el, _this));
        };
      })(this));
      return Fiber["yield"]();
    };

    Kamakura.prototype.destroy = function() {
      return this._driver.quit();
    };

    return Kamakura;

  })();

  Kamakura.Capabilities = webdriver.Capabilities;

  KamakuraElement = (function() {
    function KamakuraElement(webdriverElement, km) {
      this._orig = webdriverElement;
      this._km = km;
    }

    KamakuraElement.prototype.getText = function(opt_next) {
      var next;
      next = opt_next || this._km.next;
      this._orig.getText().then((function(_this) {
        return function(t) {
          return next(t);
        };
      })(this));
      return Fiber["yield"]();
    };

    KamakuraElement.prototype.shouldHaveText = function(text, opt_next) {
      var next, timer;
      next = opt_next || this._km.next;
      console.log('shouldHaveText');
      timer = setInterval((function(_this) {
        return function() {
          return run(function(aNext) {
            var t;
            t = _this.getText(aNext);
            console.log(t, text);
            if (t !== text) {
              return;
            }
            clearInterval(timer);
            return next(true);
          });
        };
      })(this), KamakuraElement.interval);
      return Fiber["yield"]();
    };

    return KamakuraElement;

  })();

  _.each(['click'], function(name) {
    return KamakuraElement.prototype[name] = function(args) {
      return this._orig[name].apply(this._orig, arguments);
    };
  });

  KamakuraElement.interval = 100;

  module.exports = {
    create: function(params) {
      return new Kamakura(params);
    }
  };

}).call(this);
