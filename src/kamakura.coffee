require('source-map-support').install()
Fiber = require("fibers")
webdriver = require("selenium-webdriver")
_ = require("lodash")

LOG = console.log.bind(console);
DP = console.log.bind(console);

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
          ret = this[found.method].apply(this, arguments)
          @_not = false
          return ret
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
    @driver = new webdriver.Builder().
      withCapabilities(capabilities).
      build()
    @_okProc = (opt_params && opt_params.okProc)
    @timeout = 3000
  destroy: ->
    @driver.quit()
  startTimer: ->
    Date.now()
  isTimeout: (t) ->
    Date.now() - t > @timeout
  ok: (result, msg) ->
    if @_okProc
      @_okProc(result, msg)
    result
  goto: (url) ->
    @driver.get(url)
  run: (f) ->
    fiber = Fiber(() =>
      next = (x) => fiber.run(x)
      @next = next
      f(next)
    )
    fiber.run()
  find: (css, opt_next) ->
    return new KamakuraElement(css, @)
  findAll: (css, opt_next) ->
    new KamakuraElements(css, @)
  setTimeoutValue: (@timeout) ->
  forceDisplayInlineBlockMode: (selector) ->
    @_forceDisplayStyleMode(selector, 'inline-block')
  forceDisplayBlockMode: (selector) ->
    @_forceDisplayStyleMode(selector, 'block')
  test: (selector, value) ->
    script = "return 'neko'"
    @driver.executeScript(script)
      .then((a) =>
        DP('neko', a)
      )
  _forceDisplayStyleMode: (selector, value) ->
    style = "" +
      "  #{selector} {" +
      "    display: #{value}!important;" +
      "  }" +
      ""
    script = ";" +
      "var el = document.createElement('style');" +
      "var style = '#{style}';" +
      "el.textContent = style;" +
      "document.head.appendChild(el);"
    @driver.executeScript(script)
  pause: (opt_next) ->
    next = opt_next || @next
    t = t || 10000;
    
    one = () => 
      setTimeout(() ->
        next()
      , t)
    one()
    Fiber.yield()
  # takeScreenshot: () ->
    # don't work
    # @driver.takeScreenshot()

Kamakura.Capabilities = webdriver.Capabilities


class KamakuraBaseElement
  ok: (result, msg) ->
#    LOG(result, msg)
    @_km.ok(result, msg)
  startTimer: ->
    @_km.startTimer()
  isTimeout: (t) ->
    @_km.isTimeout(t)

class KamakuraElements extends KamakuraBaseElement
  constructor: (css, km) ->
    @_css = css
    @_km = km
  findOrigs: (opt_next) ->
    next = opt_next || @_km.next
    
    t = @startTimer()
    one = () =>
      @_km.driver.findElements(webdriver.By.css(@_css)).then((els) =>
#        LOG("Find: Found: #{@_css}: ", els);
        next(els)
      , (e) =>
        if @isTimeout(t)
#          LOG("Find: Not Found: #{css}");
          throw TimeoutError("timeout on currentFindAll: #{@_css}")
        one()
      )
    one()
    Fiber.yield()
  getCount: (opt_next) ->
    @findOrigs().length 
  shouldCountEqual: (expected, opt_next) ->
    @_shouldX(
      name: 'shouldCountEqual',
      matchProc: (current) =>
        current == expected
      next: opt_next
    )
  _shouldX: (params) ->
    next = params.next || @_km.next
    t = @startTimer()
    one = () => 
      run((aNext) =>
        current = @findOrigs(aNext).length
        if @isTimeout(t)
          throw TimeoutError("timeout on #{params.name}: #{current}")
        if !params.matchProc(current)
          one()
          return
        next((@ok(true, "#{params.name}: #{current}")))
      )
    one()
    Fiber.yield()
    

class KamakuraElement extends KamakuraBaseElement
  constructor: (css, km) ->
    # webdriver.WebElement
    @_css = css
    @_not = false
    @_km = km
    @_chain = []
  _getX: (params) ->
    next = params.next || @_km.next
    t = @startTimer()
    one = () => 
      params.proc().then((v) => 
#        LOG("#{params.name}: v: ", v)
        if v == ''  # TODO: Is this a bug of selenium-webdriver?
          one()
          return
        next(v)
      , (e) =>
        if @isTimeout(t)
          LOG(!params.name, "e", e)
          throw TimeoutError("timeout on #{!params.name}")
        one()
      )
    one()
    Fiber.yield()
  findOrig: (opt_next) ->
    next = opt_next || @_km.next
    
    t = @startTimer()
    one = () =>
      run((aNext) =>
        @_km.driver.findElement(webdriver.By.css(@_css)).then((el) =>
#          LOG("Find: Found: #{@_css}: ", el);
          next(el)
        , (e) =>
          if @isTimeout(t)
  #          LOG("Find: Not Found: #{css}");
            throw TimeoutError("timeout on findOrig: #{@_css}")
          one()
        )
      )
    one()
    Fiber.yield()
  getCss: (property, opt_next) ->
    @_getX(
      name: 'getCss',
      proc: (aNext) =>
        @findOrig(aNext).getCssValue(property)
      next: opt_next  
    )
  getHtml: (opt_next) ->
    @_getX(
      name: 'getHtml',
      proc: (aNext) =>
        @findOrig(aNext).getInnerHtml()
      next: opt_next  
    )
  getAttribute: (property, opt_next) ->
    @_getX(
      name: 'getAttribute',
      proc: (aNext) =>
        @findOrig(aNext).getAttribute(property)
      next: opt_next  
    )
  shouldContainText: (expected, opt_next) ->
    @_shouldX(
      name: "shouldContainText",
      proc: (aNext) =>
        @findOrig(aNext).getText()
      matchProc: (current) =>
        current.indexOf(expected) != -1
      next: opt_next
    )
  shouldBeX: (name, method, opt_next) ->
    @_shouldX(
      name: name,
      proc: (aNext) =>
        @findOrig(aNext)[method]()
      matchProc: (current) =>
        current
      next: opt_next
    )
  shouldBeDisplayed: (opt_next) ->
    @shouldBeX("shouldBeDisplayed", "isDisplayed", opt_next)
  shouldBeEnabled: (opt_next) ->
    @shouldBeX("shouldBeEnabled", "isEnabled", opt_next)
  shouldBeSelected: (opt_next) ->
    @shouldBeX("shouldBeSelected", "isSelected", opt_next)
  shouldContainHtml: (expected, opt_next) ->
    @_shouldX(
      name: "shouldContainHtml",
      proc: (aNext) =>
        @findOrig(aNext).getInnerHtml()
      matchProc: (current) =>
        current.indexOf(expected) != -1
      next: opt_next
    )
  shouldHaveCss: (css, expected, opt_next) ->
    @_shouldHaveX("shouldHaveCss", "getCssValue", css, expected, opt_next)
  shouldHaveAttr: (attr, expected, opt_next) ->
    @_shouldHaveX("shouldHaveAttr", "getAttribute", attr, expected, opt_next)
  _shouldHaveX: (name, method, property, expected, opt_next) ->
    @_shouldX(
      name: name,
      proc: (aNext) =>
        @findOrig(aNext)[method](property)
      matchProc: (current) =>
        current == expected
      next: opt_next
    )
  _shouldX: (params) ->
    next = params.next || @_km.next
    t = @startTimer()
    one = () => 
      run((aNext) =>
        params.proc(aNext).then((current) => 
#          LOG("#{params.name}: current: ", current)
          if @isTimeout(t)
            throw TimeoutError("timeout on #{params.name}: #{current}")
          res = params.matchProc(current)
          if @_not
            res = !res
            @_not = false
          if !res
            one()
            return
          next((@ok(true, "#{!params.name}: #{current}")))
        , (e) =>
          if @isTimeout(t)
            throw TimeoutError("timeout on #{!params.name}")
  #        LOG(!params.name, "e", e)
          one()
        )
      )
    one()
    Fiber.yield()

KamakuraElement.prototype.__defineGetter__('not', ->
  @_not = true
  @
)

_.each([
  "startTimer",
  "isTimeout"
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    @_km[name].apply(@_km, arguments)
)

# getter
_.each([
  'getText',
  'isEnabled',
  'isSelected',
  'isDisplayed'
], (name) ->
  KamakuraElement.prototype[name] = (opt_next) ->
    @_getX(
      name: name,
      proc: =>
        @findOrig()[name]()
      next: opt_next  
    )
)

# action
_.each([
  "click",
  "sendKeys",
  "submit",
  "clear",
], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    orig = @findOrig()
    orig[name].apply(orig, arguments)
)

# chain methods
setChainMethod(KamakuraElement, [{
  names: ["should", "contain", "text"]
  method: "shouldContainText"
},{
  names: ["should", "contain", "html"]
  method: "shouldContainHtml"
},{
  names: ["should", "have", "css"]
  method: "shouldHaveCss"
},{
  names: ["should", "have", "attr"]
  method: "shouldHaveAttr"
},{
  names: ["should", "be", "enabled"]
  method: "shouldBeEnabled"
},{
  names: ["should", "be", "selected"]
  method: "shouldBeSelected"
},{
  names: ["should", "be", "displayed"]
  method: "shouldBeDisplayed"
}])

# add shouldNotX
for origName of KamakuraElement.prototype
  ((orig) ->
    if !orig.match(/^should(.)+/)
      return
    name = orig.replace('should', 'shouldNot')
    KamakuraElement.prototype[name] = (args) ->
      @_not = true
      ret = @[orig].apply(@, arguments)
      @_not = false
      ret
  )(origName)
  
module.exports = {
  create: (params) ->
    new Kamakura(params)
  capabilities: Kamakura.Capabilities
}
