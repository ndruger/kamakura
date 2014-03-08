"use strict"
express = require("express")
server = express()

server.configure( ->
  server.use(express.static(__dirname + "/public"))
)

module.exports = () ->
  server.listen().address()

