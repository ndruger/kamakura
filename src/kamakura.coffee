Fiber = require('fibers')
webdriver = require('selenium-webdriver')
_ = require('lodash')

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
    
    this._driver.findElement(webdriver.By.css(css)).then((el) =>
      next(new KamakuraElement(el, this))
    )
    
    Fiber.yield()
  destroy: ->
    this._driver.quit()

Kamakura.Capabilities = webdriver.Capabilities


class KamakuraElement
  constructor: (webdriverElement, km) ->
    # webdriver.WebElement
    this._orig = webdriverElement
    this._km = km
  getText: (opt_next) ->
    next = opt_next || this._km.next
  
    this._orig.getText().then((t) => 
      next(t)
    )
    Fiber.yield()
  shouldHaveText: (text, opt_next) ->
    next = opt_next || this._km.next
    console.log('shouldHaveText')
    
    timer = setInterval(=>
      run((aNext) =>
        t = this.getText(aNext)
        console.log(t, text)
        if t != text
          return
        clearInterval(timer)
        next(true))
    , KamakuraElement.interval)
    
    Fiber.yield()

_.each(['click'], (name) ->
  KamakuraElement.prototype[name] = (args) ->
    this._orig[name].apply(this._orig, arguments)
)
KamakuraElement.interval = 100


module.exports = {
  create: (params) ->
    new Kamakura(params)
}
