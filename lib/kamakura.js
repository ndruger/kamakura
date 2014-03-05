(function() {
  "use strict";
  var Fiber, Kamakura, KamakuraElement, run, webdriver, _;

  Fiber = require("fibers");

  webdriver = require("selenium-webdriver");

  _ = require("lodash");

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
      this._okProc = opt_params && opt_params.ok;
    }

    Kamakura.prototype.destroy = function() {
      return this._driver.quit();
    };

    Kamakura.prototype.ok = function(result, msg) {
      if (this._okProc) {
        this._okProc(result, msg);
      }
      console.log("result = " + result + ": " + msg);
      return result;
    };

    Kamakura.prototype.goto = function(url) {
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
      var next, one;
      next = opt_next || this.next;
      one = (function(_this) {
        return function() {
          return _this._driver.findElement(webdriver.By.css(css)).then(function(el) {
            return next(new KamakuraElement(el, _this));
          }, function(e) {
            return one();
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    return Kamakura;

  })();

  Kamakura.Capabilities = webdriver.Capabilities;

  KamakuraElement = (function() {
    function KamakuraElement(webdriverElement, km) {
      this._orig = webdriverElement;
      this._km = km;
      this._chain = [];
    }

    KamakuraElement.prototype.ok = function(result, msg) {
      return this._km.ok(result, msg);
    };

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

    KamakuraElement.prototype.containsText = function(expected, opt_next) {
      var next, one;
      next = opt_next || this._km.next;
      one = (function(_this) {
        return function() {
          return run(function(aNext) {
            var t;
            t = _this.getText(aNext);
            console.log(t);
            if (!expected.match(t)) {
              one();
              return;
            }
            return next(_this.ok(true, "containsText: " + expected));
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    return KamakuraElement;

  })();

  _.each(["click", "sendKeys", "submit", "clear"], function(name) {
    return KamakuraElement.prototype[name] = function(args) {
      return this._orig[name].apply(this._orig, arguments);
    };
  });

  KamakuraElement._chainMethods = [
    {
      names: ['text', 'contains'],
      method: 'containsText'
    }
  ];

  _.each(KamakuraElement._chainMethods, function(method) {
    return _.each(method.names, function(name) {
      var f;
      f = function() {
        var found;
        this._chain.push(name);
        found = _.find(KamakuraElement._chainMethods, (function(_this) {
          return function(m) {
            return _.all(m.names, function(n, i) {
              return _this._chain[_this._chain.length - (m.names.length - i)] === n;
            });
          };
        })(this));
        if (found) {
          return this[found.method].apply(this, arguments);
        }
        return this;
      };
      if (name === method.names[method.names.length - 1]) {
        return KamakuraElement.prototype[name] = f;
      } else {
        return KamakuraElement.prototype.__defineGetter__(name, f);
      }
    });
  });

  module.exports = {
    create: function(params) {
      return new Kamakura(params);
    }
  };

}).call(this);
