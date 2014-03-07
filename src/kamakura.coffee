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
  cls_chainMethods = methods
  _.each(methods, (method) ->
    _.each(method.names, (name) ->
      f = ->
        @_chain.push(name)
        found = _.find(cls._chainMethods, (m) =>
          _.all(m.names, (n, i) =>
            @_chain[@_chain.length - (m.names.length - i)] == n
          )
        )
        if found
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
    
    @startTimer()
    one = () => 
      @_driver.findElement(webdriver.By.css(css)).then((el) =>
#        LOG("Find: Found: #{css}: ", el);
        next(new KamakuraElement(el, @))
      , (e) =>
        if @isTimeout()
          throw TimeoutError('timeout on find')
#        LOG("Find: Not Found: #{css}");
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
  getText: (opt_next) ->
    next = opt_next || @_km.next
  
    @_orig.getText().then((t) => 
      next(t)
    )
    Fiber.yield()
  containsText: (expected, opt_next) ->
    next = opt_next || @_km.next

    @startTimer()
    one = () =>
      run((aNext) =>
        if @isTimeout()
          throw TimeoutError('timeout on #{containsText}')
        t = @getText(aNext)
#        console.log(t)
        if !expected.match(t)
          one()
          return
        next(@ok(true, "containsText: #{expected}")))
    one()
    
    Fiber.yield()
  isX: (name, opt_next) ->
    next = opt_next || @_km.next

    @startTimer()
    one = () => 
      @_orig[name]().then((result) => 
        #LOG("#{name}: result: ", result)
        if @isTimeout()
          throw TimeoutError("timeout on #{name}")
        if !result
          one()
          return
        next((@ok(result, "#{name}: #{result}")))
      , (e) =>
        console.log(name, 'e', e)
        one()
      )
    one()
    Fiber.yield()
  isEnabled: (opt_next) ->
    @isX('isEnabled', opt_next)
  isSelected: (opt_next) ->
    @isX('isSelected', opt_next)

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
  names: ['text', 'contains']
  method: 'containsText'
}])

module.exports = {
  create: (params) ->
    new Kamakura(params)
}
