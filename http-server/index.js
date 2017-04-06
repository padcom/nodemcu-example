#!/usr/bin/env node

const express = require('express')
const app = express()

app.get('/', function(req, resp) {
  resp.send('Hello, world!')
})

app.get('/:type', function(req, resp) {
  console.log(new Date())
  resp.send({ type: req.params.type, version: '5', files: [ 'application.lua', 'interim.lua', 'message.lua' ] })
})

app.get('/alamakota/application.lua', function(req, resp) {
  console.log("Getting application.lua")
  resp.send('dofile("interim.lua")\n')
})

app.get('/alamakota/interim.lua', function(req, resp) {
  console.log("Getting interim.lua")
  resp.send('dofile("message.lua")\n')
})

app.get('/alamakota/message.lua', function(req, resp) {
  console.log("Getting message.lua")
  resp.send('print("Hello, world!")\n')
})


app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
