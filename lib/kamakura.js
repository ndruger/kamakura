(function() {
  var Fiber, Kamakura, KamakuraElement, LOG, TimeoutError, run, setChainMethod, webdriver, _;

  Fiber = require("fibers");

  webdriver = require("selenium-webdriver");

  _ = require("lodash");

  LOG = console.log.bind(console);

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

  TimeoutError = function(msg) {
    var err;
    err = Error.call(this, msg);
    err.name = "TimeoutError";
    return err;
  };

  setChainMethod = function(cls, methods) {
    var cls_chainMethods;
    cls_chainMethods = methods;
    return _.each(methods, function(method) {
      return _.each(method.names, function(name) {
        var f;
        f = function() {
          var found;
          this._chain.push(name);
          found = _.find(cls._chainMethods, (function(_this) {
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
          return cls.prototype[name] = f;
        } else {
          return cls.prototype.__defineGetter__(name, f);
        }
      });
    });
  };

  Kamakura = (function() {
    function Kamakura(opt_params) {
      var capabilities;
      capabilities = (opt_params && opt_params.capabilities) || Kamakura.Capabilities.chrome();
      this._driver = new webdriver.Builder().withCapabilities(capabilities).build();
      this._okProc = opt_params && opt_params.okProc;
      this.timeout = 3000;
    }

    Kamakura.prototype.destroy = function() {
      return this._driver.quit();
    };

    Kamakura.prototype.startTimer = function() {
      return this.startTime = Date.now();
    };

    Kamakura.prototype.isTimeout = function() {
      return Date.now() - this.startTime > this.timeout;
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
      this.startTimer();
      one = (function(_this) {
        return function() {
          return _this._driver.findElement(webdriver.By.css(css)).then(function(el) {
            return next(new KamakuraElement(el, _this));
          }, function(e) {
            if (_this.isTimeout()) {
              throw TimeoutError('timeout on find');
            }
            return one();
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    Kamakura.prototype.setTimeoutVal = function(timeout) {
      this.timeout = timeout;
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
      this.startTimer();
      one = (function(_this) {
        return function() {
          return run(function(aNext) {
            var t;
            if (_this.isTimeout()) {
              throw TimeoutError('timeout on #{containsText}');
            }
            t = _this.getText(aNext);
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

    KamakuraElement.prototype.isX = function(name, opt_next) {
      var next, one;
      next = opt_next || this._km.next;
      this.startTimer();
      one = (function(_this) {
        return function() {
          return _this._orig[name]().then(function(result) {
            if (_this.isTimeout()) {
              throw TimeoutError("timeout on " + name);
            }
            if (!result) {
              one();
              return;
            }
            return next(_this.ok(result, "" + name + ": " + result));
          }, function(e) {
            console.log(name, 'e', e);
            return one();
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    KamakuraElement.prototype.isEnabled = function(opt_next) {
      return this.isX('isEnabled', opt_next);
    };

    KamakuraElement.prototype.isSelected = function(opt_next) {
      return this.isX('isSelected', opt_next);
    };

    KamakuraElement.prototype.containsHtml = function(expected, opt_next) {
      var next, one;
      next = opt_next || this._km.next;
      this.startTimer();
      one = (function(_this) {
        return function() {
          return _this._orig.getInnerHtml().then(function(html) {
            if (_this.isTimeout()) {
              throw TimeoutError("timeout on containsHtml");
            }
            if (!expected.match(html)) {
              one();
              return;
            }
            return next(_this.ok(true, "containsHtml: " + html));
          }, function(e) {
            console.log(name, 'e', e);
            return one();
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    KamakuraElement.prototype.hasCss = function(css, expected, opt_next) {
      var next, one;
      next = opt_next || this._km.next;
      this.startTimer();
      one = (function(_this) {
        return function() {
          return _this._orig.getCssValue(css).then(function(value) {
            if (_this.isTimeout()) {
              throw TimeoutError("timeout on containsHtml");
            }
            if (!(value === expected)) {
              one();
              return;
            }
            return next(_this.ok(true, "hasCss: " + value));
          }, function(e) {
            console.log('hasCss', 'e', e);
            return one();
          });
        };
      })(this);
      one();
      return Fiber["yield"]();
    };

    return KamakuraElement;

  })();

  _.each(["startTimer", "isTimeout"], function(name) {
    return KamakuraElement.prototype[name] = function(args) {
      return this._km[name].apply(this._km, arguments);
    };
  });

  _.each(["click", "sendKeys", "submit", "clear"], function(name) {
    return KamakuraElement.prototype[name] = function(args) {
      return this._orig[name].apply(this._orig, arguments);
    };
  });

  setChainMethod(KamakuraElement, [
    {
      names: ['text', 'contains'],
      method: 'containsText'
    }, {
      names: ['html', 'contains'],
      method: 'containsHtml'
    }, {
      names: ['css', 'has'],
      method: 'hasCss'
    }
  ]);

  module.exports = {
    create: function(params) {
      return new Kamakura(params);
    }
  };

}).call(this);
