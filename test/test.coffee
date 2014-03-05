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
# TODO: create test sample of todo mvc 
# TODO: error case
# TODO: .dont.

assert = require("chai").assert

km = kamakura.create({
  ok: assert.ok
})

describe("Kaminari", ->
  this.timeout(10000)

  describe("find()", ->
    it('should wait and find result element', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=find.js")
        km.find("button").click()
        assert.ok(km.find(".result"))
        done()
      )
    )
  )
  
  describe("containsText()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=containsText.js")
        km.find("button").click()
        km.find(".result").containsText("pushed")
        km.find(".result").text.contains("push")
        done()
      )
    )
  )
  
  after(->
    km.destroy()
  )
)
