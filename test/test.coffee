"use strict"
kamakura = require("../lib/kamakura")
address = require("./server")()
origin = "http://#{address.address}:#{address.port}"

assert = require("chai").assert

DP = console.log.bind(console)

km = kamakura.create(
  okProc: assert.ok
  capabilities: kamakura.capabilities.chrome()
)

describe("Kaminari", ->
  this.timeout(10000)
  km.setTimeoutValue(2000)

  describe("find()", ->
    it("should wait and find result element", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        assert.ok(km.find(".result_text"))
        done()
      )
    )
  )

  describe("findAll()", ->
    it("should find result elements", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find("button").click()
        assert.equal(km.findAll(".result_text").getCount(), 0)  # it doesn't wait
        km.findAll(".result_text").shouldCountEqual(2);
        assert.equal(km.findAll(".result_text").getCount(), 2)
        done()
      )
    )
  )


  describe("shouldBeEnabled()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=shouldBeEnabled.js")
        km.find("button").click()
        km.find(".result_button").shouldBeEnabled()
#        km.find(".result_button").should.be.enabled()
#        km.find(".disabled_button").shouldNotBeEnabled()
#        km.find(".disabled_button").should.not.be.enabled()
#        assert.equal(km.find(".result_button").isEnabled(), true)
        done()
      )
    )
  )

  describe("shouldBeSelected()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=shouldBeSelected.js")
        km.find("button").click()
        km.find(".result_option").shouldBeSelected()
        km.find(".result_option").should.be.selected()
        km.find(".default_option").shouldNotBeSelected()
        km.find(".default_option").should.not.be.selected()
        assert.equal(km.find(".result_option").isSelected(), true)
        done()
      )
    )
  )

  describe("shouldBeDisplayed()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldBeDisplayed()
        km.find(".result_text").should.be.displayed()
        km.find(".hidden_text").shouldNotBeDisplayed()
        km.find(".hidden_text").should.not.be.displayed()
        assert.equal(km.find(".result_text").isDisplayed(), true)
        done()
      )
    )
  )
  
  describe("shouldContainText()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldContainText("push")
        km.find(".result_text").shouldNotContainText("push?")
        km.find(".result_text").should.contain.text("push")
        km.find(".result_text").should.not.contain.text("push?")
        assert.equal(km.find(".result_text").getText(), "pushed")
        done()
      )
    )
  )

  describe("shouldContainHtml()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldContainHtml("push")
        km.find(".result_text").shouldNotContainHtml("push?")
        km.find(".result_text").should.contain.html("push")
        km.find(".result_text").should.not.contain.html("push?")
        assert.equal(km.find(".result_text").getHtml(), "pushed")
        done()
      )
    )
  )

  describe("shouldHaveCss()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldHaveCss("display", "inline-block")
        km.find(".result_text").shouldNotHaveCss("display", "block")
        km.find(".result_text").should.have.css("display", "inline-block")
        km.find(".result_text").should.not.have.css("display", "block")
        assert.equal(km.find(".result_text").getCss("display"), "inline-block")
        done()
      )
    )
  )

  describe("shouldHaveAttr()", ->
    it("should wait result", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=common.js")
        km.find("button").click()
        km.find(".result_text").shouldHaveAttr("name", "name_value")
        km.find(".result_text").shouldNotHaveAttr("name", "name_value?")
        km.find(".result_text").should.have.attr("name", "name_value")
        km.find(".result_text").should.not.have.attr("name", "name_value?")
        assert.equal(km.find(".result_text").getAttribute("name"), "name_value")
        done()
      )
    )
  )

  describe("forceDisplayInlineBlockMode() / forceDisplayBlockMode()", ->
    it("should change style", (done) ->
      km.run((next) =>
        km.goto("#{origin}?js=forceDisplayInlineBlockMode.js")
        km.find("button").click()
        km.forceDisplayInlineBlockMode('.result_text');
        km.find(".result_text").shouldHaveCss("display", "inline-block")
        km.forceDisplayBlockMode('.result_text');
        km.find(".result_text").shouldHaveCss("display", "block")
        km.find(".result_text").shouldContainText("pushed")
        done()
      )
    )
  )

  # describe("test", ->
    # it("should change style", (done) ->
      # km.run((next) =>
        # km.goto("#{origin}?js=forceDisplayInlineBlockMode.js")
        # DP(km.test())
      # )
    # )
  # )
  
  after(->
    km.destroy()
  )
)
