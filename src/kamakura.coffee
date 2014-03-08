Fiber = require("fibers")
webdriver = require("selenium-webdriver")
_ = require("lodash")

LOG = console.log.bind(console);

run = (f) ->
  fiber = Fiber(() =>
    next = (x) => fiber.run(x)
    f(next)
  )
  fiber.run()

TimeoutError = (msg) ->
  err = Error.call(this, msg)
  err.name = "TimeoutError"
  err
      
setChainMethod = (cls, methods) ->
  maxLen = _.map(methods, (m) ->
    m.names.length
  )
  
  cls._chainMethods = methods
  _.each(methods, (method) ->
    _.each(method.names, (name) ->
      f = ->
        @_chain.push(name)
        if @_chain.length == maxLen + 1
          throw "chain matcher failed: maxLen"
        found = _.find(cls._chainMethods, (m) =>
           _.all(m.names, (n, i) =>
            @_chain[@_chain.length - (m.names.length - i)] == n
          )
        )
        if found
          @_chain = []
          return this[found.method].apply(this, arguments)
        this
      if name == method.names[method.names.length - 1]
        cls.prototype[name] = f
      else
        cls.prototype.__defineGetter__(name, f)
    )
  )

class Kamakura
  constructor: (opt_params) ->
    capabilities = (opt_params && opt_params.capabilities) || Kamakura.Capabilities.chrome()
    @_driver = new webdriver.Builder().
      withCapabilities(capabilities).
      build()
    @_okProc = (opt_params && opt_params.okProc)
    @timeout = 3000
  destroy: ->
    @_driver.quit()
  startTimer: ->
    @startTime = Date.now()
  isTimeout: ->
    Date.now() - @startTime > @timeout
  ok: (result, msg) ->
    if @_okProc
      @_okProc(result, msg)
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
    
    @startTimer()
    one = () => 
      @_driver.findElement(webdriver.By.css(css)).then((el) =>
#        LOG("Find: Found: #{css}: ", el);
        next(new KamakuraElement(el, @))
      , (e) =>
        if @isTimeout()
          LOG("Find: Not Found: #{css}");
          throw TimeoutError("timeout on find: #{css}")
        one()
      )
    one()
    Fiber.yield()
  setTimeoutVal: (@timeout) ->

Kamakura.Capabilities = webdriver.Capabilities


class KamakuraElement
  constructor: (webdriverElement, km) ->
    # webdriver.WebElement
    @_orig = webdriverElement
    @_km = km
    @_chain = []
  ok: (result, msg) ->
    @_km.ok(result, msg)
  shouldContainText: (expected, opt_next) ->
    @_shouldX(
      name: "shouldContainText",
      proc: =>
        @_orig.getText()
      matchProc: (current) =>
        expected.match(current)
      next: opt_next
    )
  shouldBeX: (name, method, opt_next) ->
    @_shouldX(
      name: name,
      proc: =>
        @_orig[method]()
      matchProc: (current) =>
        current
      next: opt_next
    )
  shouldBeEnabled: (opt_next) ->
    @shouldBeX("shouldBeEnabled", "isEnabled", opt_next)
  shouldBeSelected: (opt_next) ->
    @shouldBeX("shouldBeSelected", "isSelected", opt_next)
  shouldContainHtml: (expected, opt_next) ->
    @_shouldX(
      name: "shouldContainHtml",
      proc: =>
        @_orig.getInnerHtml()
      matchProc: (current) =>
        current.match(expected)
      next: opt_next
    )
  shouldHaveCss: (css, expected, opt_next) ->
    @_shouldHaveX("shouldHaveCss", "getCssValue", css, expected, opt_next)
  shouldHaveAttr: (attr, expected, opt_next) ->
    @_shouldHaveX("shouldHaveAttr", "getAttribute", attr, expected, opt_next)
  _shouldHaveX: (name, method, property, expected, opt_next) ->
    @_shouldX(
      name: name,
      proc: =>
        @_orig[method](property)
      matchProc: (current) =>
        current == expected
      next: opt_next
    )
  _shouldX: (params) ->
    next = params.next || @_km.next
    @startTimer()
    one = () => 
      params.proc().then((current) => 
        #LOG("#{name}: result: ", result)
        if @isTimeout()
          throw TimeoutError("timeout on #{params.name}: #{current}")
        if !params.matchProc(current)
          one()
          return
        next((@ok(true, "#{!params.name}: #{current}")))
      , (e) =>
        if @isTimeout()
          throw TimeoutError("timeout on #{!params.name}")
#        console.log(!params.name, "e", e)
        one()
      )
    one()
    Fiber.yield()

_.each([
  "startTimer",
  "isTimeout"
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    @_km[name].apply(@_km, arguments)
)

_.each([
  "click",
  "sendKeys",
  "submit",
  "clear",
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    @_orig[name].apply(@_orig, arguments)
)

setChainMethod(KamakuraElement, [{
  names: ["text", "should", "contain"]
  method: "shouldContainText"
},{
  names: ["html", "should", "contain"]
  method: "shouldContainHtml"
},{
  names: ["css", "should", "have"]
  method: "shouldHaveCss"
},{
  names: ["attr", "should", "have"]
  method: "shouldHasAttr"
}])

module.exports = {
  create: (params) ->
    new Kamakura(params)
}
