"use strict"
Fiber = require("fibers")
webdriver = require("selenium-webdriver")
_ = require("lodash")

run = (f) ->
  fiber = Fiber(() =>
    next = (x) => fiber.run(x)
    f(next)
  )
  fiber.run()

class Kamakura
  constructor: (opt_params) ->
    Capabilities = (opt_params && opt_params.capabilities) || Kamakura.Capabilities.chrome()
    this._driver = new webdriver.Builder().
      withCapabilities(webdriver.Capabilities.chrome()).
      build()
    this._okProc = (opt_params && opt_params.ok)
  destroy: ->
    this._driver.quit()
  ok: (result, msg) ->
    if this._okProc
      this._okProc(result, msg)
    console.log("result = #{result}: #{msg}")
    result
  goto: (url) ->
    this._driver.get(url)
  run: (f) ->
    fiber = Fiber(() =>
      next = (x) => fiber.run(x)
      this.next = next
      f(next)
    )
    fiber.run()
  find: (css, opt_next) ->
    next = opt_next || this.next
    
    one = () => 
      this._driver.findElement(webdriver.By.css(css)).then((el) =>
        next(new KamakuraElement(el, this))
      , (e) =>
        one()
      )
    one()
    
    Fiber.yield()

Kamakura.Capabilities = webdriver.Capabilities


class KamakuraElement
  constructor: (webdriverElement, km) ->
    # webdriver.WebElement
    this._orig = webdriverElement
    this._km = km
  ok: (result, msg) ->
    this._km.ok(result, msg)
  getText: (opt_next) ->
    next = opt_next || this._km.next
  
    this._orig.getText().then((t) => 
      next(t)
    )
    Fiber.yield()
  shouldHaveText: (text, opt_next) ->
    next = opt_next || this._km.next

    one = () =>
      run((aNext) =>
        t = this.getText(aNext)
        if t != text
          one()
          return
        next(this.ok(true, "shouldHaveText: #{text}")))
    one()
    
    Fiber.yield()

_.each([
  "click",
  "sendKeys",
  "submit",
  "clear",
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    this._orig[name].apply(this._orig, arguments)
)
KamakuraElement.interval = 100


module.exports = {
  create: (params) ->
    new Kamakura(params)
}
