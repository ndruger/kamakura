"use strict"
kamakura = require("../lib/kamakura")
address = require("./server")()

assert = require("chai").assert

km = kamakura.create({
  okProc: assert.ok
})

describe("Kaminari", ->
  this.timeout(10000)
  km.setTimeoutVal(0)

  describe("find()", ->
    it('should wait and find result element', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=find.js")
        km.find("button").click()
        assert.ok(km.find(".result_text"))
        done()
      )
    )
  )
  
  describe("containsText()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=containsText.js")
        km.find("button").click()
        km.find(".result_text").containsText("pushed")
        km.find(".result_text").text.contains("push")
        done()
      )
    )
  )

  describe("isEnabled()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=isEnabled.js")
        km.find("button").click()
        km.find(".result_button").isEnabled()
        done()
      )
    )
  )

  describe("isSelected()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=isSelected.js")
        km.find("button").click()
        km.find(".result_option").isSelected()
        done()
      )
    )
  )
  
  after(->
    km.destroy()
  )
)
