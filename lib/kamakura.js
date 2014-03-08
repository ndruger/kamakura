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
    cls._chainMethods = methods;
    return _.each(methods, function(method) {
      return _.each(method.names, function(name) {
        var f;
        f = function() {
          var found;
          this._chain.push(name);
          if (this._chain.length === 3) {
            throw 'chain matcher fialed';
          }
          found = _.find(cls._chainMethods, (function(_this) {
            return function(m) {
              return _.all(m.names, function(n, i) {
                return _this._chain[_this._chain.length - (m.names.length - i)] === n;
              });
            };
          })(this));
          if (found) {
            this._chain = [];
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

    KamakuraElement.prototype.containsText = function(expected, opt_next) {
      return this.doOrigMethod({
        name: 'containsText',
        proc: (function(_this) {
          return function() {
            return _this._orig.getText();
          };
        })(this),
        matchProc: (function(_this) {
          return function(current) {
            return expected.match(current);
          };
        })(this),
        next: opt_next
      });
    };

    KamakuraElement.prototype.isX = function(name, opt_next) {
      return this.doOrigMethod({
        name: name,
        proc: (function(_this) {
          return function() {
            return _this._orig[name]();
          };
        })(this),
        matchProc: (function(_this) {
          return function(current) {
            return current;
          };
        })(this),
        next: opt_next
      });
    };

    KamakuraElement.prototype.isEnabled = function(opt_next) {
      return this.isX('isEnabled', opt_next);
    };

    KamakuraElement.prototype.isSelected = function(opt_next) {
      return this.isX('isSelected', opt_next);
    };

    KamakuraElement.prototype.containsHtml = function(expected, opt_next) {
      return this.doOrigMethod({
        name: 'containsHtml',
        proc: (function(_this) {
          return function() {
            return _this._orig.getInnerHtml();
          };
        })(this),
        matchProc: (function(_this) {
          return function(current) {
            return current.match(expected);
          };
        })(this),
        next: opt_next
      });
    };

    KamakuraElement.prototype.hasCss = function(css, expected, opt_next) {
      return this.hasX('hasCss', 'getCssValue', css, expected, opt_next);
    };

    KamakuraElement.prototype.hasAttr = function(attr, expected, opt_next) {
      return this.hasX('hasAttr', 'getAttribute', attr, expected, opt_next);
    };

    KamakuraElement.prototype.hasX = function(name, method, property, expected, opt_next) {
      return this.doOrigMethod({
        name: name,
        proc: (function(_this) {
          return function() {
            return _this._orig[method](property);
          };
        })(this),
        matchProc: (function(_this) {
          return function(current) {
            return current === expected;
          };
        })(this),
        next: opt_next
      });
    };

    KamakuraElement.prototype.doOrigMethod = function(params) {
      var next, one;
      next = params.next || this._km.next;
      this.startTimer();
      one = (function(_this) {
        return function() {
          return params.proc().then(function(current) {
            if (_this.isTimeout()) {
              throw TimeoutError("timeout on " + name + ": " + current);
            }
            if (!params.matchProc(current)) {
              one();
              return;
            }
            return next(_this.ok(true, "" + (!params.name) + ": " + current));
          }, function(e) {
            if (_this.isTimeout()) {
              throw TimeoutError("timeout on " + (!params.name));
            }
            console.log(!params.name, 'e', e);
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
    }, {
      names: ['neko', 'has'],
      method: 'hasAttr'
    }
  ]);

  module.exports = {
    create: function(params) {
      return new Kamakura(params);
    }
  };

}).call(this);
