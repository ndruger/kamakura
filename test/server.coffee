express = require('express')
server = express()
http = require('http')

server.configure( ->
  server.use(express.static(__dirname + '/public'))
)



module.exports = () ->
  server.listen().address()
  

