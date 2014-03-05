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
    @_driver = new webdriver.Builder().
      withCapabilities(webdriver.Capabilities.chrome()).
      build()
    @_okProc = (opt_params && opt_params.ok)
  destroy: ->
    @_driver.quit()
  ok: (result, msg) ->
    if @_okProc
      @_okProc(result, msg)
    console.log("result = #{result}: #{msg}")
    result
  goto: (url) ->
    @_driver.get(url)
  run: (f) ->
    fiber = Fiber(() =>
      next = (x) => fiber.run(x)
      @next = next
      f(next)
    )
    fiber.run()
  find: (css, opt_next) ->
    next = opt_next || @next
    
    one = () => 
      @_driver.findElement(webdriver.By.css(css)).then((el) =>
        next(new KamakuraElement(el, @))
      , (e) =>
        one()
      )
    one()
    
    Fiber.yield()

Kamakura.Capabilities = webdriver.Capabilities


class KamakuraElement
  constructor: (webdriverElement, km) ->
    # webdriver.WebElement
    @_orig = webdriverElement
    @_km = km
    @_chain = []
    
  ok: (result, msg) ->
    @_km.ok(result, msg)
  getText: (opt_next) ->
    next = opt_next || @_km.next
  
    @_orig.getText().then((t) => 
      next(t)
    )
    Fiber.yield()
  containsText: (expected, opt_next) ->
    next = opt_next || @_km.next

    one = () =>
      run((aNext) =>
        t = @getText(aNext)
        console.log(t)
        if !expected.match(t)
          one()
          return
        next(@ok(true, "containsText: #{expected}")))
    one()
    
    Fiber.yield()

_.each([
  "click",
  "sendKeys",
  "submit",
  "clear",
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    @_orig[name].apply(@_orig, arguments)
)

KamakuraElement._chainMethods = [{
  names: ['text', 'contains']
  method: 'containsText'
}]

_.each(KamakuraElement._chainMethods, (method) ->
  _.each(method.names, (name) ->
    f = ->
      @_chain.push(name)
      found = _.find(KamakuraElement._chainMethods, (m) =>
        _.all(m.names, (n, i) =>
          @_chain[@_chain.length - (m.names.length - i)] == n
        )
      )
      if found
        return this[found.method].apply(this, arguments)
      this
    if name == method.names[method.names.length - 1]
      KamakuraElement.prototype[name] = f
    else
      KamakuraElement.prototype.__defineGetter__(name, f)
  )
)

module.exports = {
  create: (params) ->
    new Kamakura(params)
}
