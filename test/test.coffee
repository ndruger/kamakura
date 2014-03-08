"use strict"
kamakura = require("../lib/kamakura")
address = require("./server")()
origin = "http://#{address.address}:#{address.port}"

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
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        assert.ok(km.find(".result_text"))
        done()
      )
    )
  )
  
  describe("shouldContainText()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldContainText("pushed")
        km.find(".result_text").text.should.contain("push")
        done()
      )
    )
  )

  describe("shouldBeEnabled()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=shouldBeEnabled.js")
        km.find("button").click()
        km.find(".result_button").shouldBeEnabled()
        done()
      )
    )
  )

  describe("shouldBeSelected()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=shouldBeSelected.js")
        km.find("button").click()
        km.find(".result_option").shouldBeSelected()
        done()
      )
    )
  )

  describe("shouldContainHtml()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldContainHtml("pushed")
        km.find(".result_text").html.should.contain("pushed")
        done()
      )
    )
  )

  describe("shouldHaveCss()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldHaveCss("display", "inline-block")
        km.find(".result_text").css.should.have("display", "inline-block")
        done()
      )
    )
  )

  describe("shouldHaveAttr()", ->
    it('should wait result', (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldHaveAttr("name", "name_value")
        km.find(".result_text").attr.should.have("name", "name_value")
        done()
      )
    )
  )
  
  after(->
    km.destroy()
  )
)
