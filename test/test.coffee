"use strict"
kamakura = require("../lib/kamakura")
address = require("./server")()

assert = require("chai").assert

km = kamakura.create({
  okProc: assert.ok
})

describe("Kaminari", ->
  this.timeout(10000)
  km.setTimeoutVal(3000)

  describe("find()", ->
    it('should wait and find result element', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=common.js")
        km.find("button").click()
        assert.ok(km.find(".result_text"))
        done()
      )
    )
  )
  
  describe("containsText()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=common.js")
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

  describe("hasHtml()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=common.js")
        km.find("button").click()
        km.find(".result_text").containsHtml("pushed")
        km.find(".result_text").html.contains("pushed")
        done()
      )
    )
  )

  describe("hasCss()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=common.js")
        km.find("button").click()
        km.find(".result_text").hasCss("display", "inline-block")
        km.find(".result_text").css.has("display", "inline-block")
        done()
      )
    )
  )

  describe("hasAttr()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("http://#{address.address}:#{address.port}?js=common.js")
        km.find("button").click()
        km.find(".result_text").hasAttr("name", "name_value")
        km.find(".result_text").attr.has("name", "name_value")
        done()
      )
    )
  )
  
  after(->
    km.destroy()
  )
)
