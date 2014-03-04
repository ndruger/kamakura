"use strict"
kamakura = require("../lib/kamakura")
address = require("./server")()

# shouldHaveText: text.contains()
# shouldHaveValue: val.contains()
# shouldHaveHtml: html.contains()

# shouldHaveCss: css.has()
# shouldHaveAttribute: attr.has()

# shouldBeEnabled: isEnabled()
# shouldBeSelected: isSelected()
# shouldBeDisplayed: isDisplayed()

# shouldBeCount: count.equals()

assert = require("chai").assert

km = kamakura.create({
  ok: assert.ok
})

describe("Kaminari", ->
  this.timeout(5000)

  describe("find()", ->
    it('should wait and find element', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=find.js")
        km.find("button").click()
        assert.ok(km.find(".result"))
        done()
      )
    )
  )
  
  describe("shouldHaveText()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=shouldHaveText.js")
        km.find("button").click()
        km.find(".result").shouldHaveText("pushed")
        done()
      )
    )
  )
  
  after(->
    km.destroy()
  )
)
