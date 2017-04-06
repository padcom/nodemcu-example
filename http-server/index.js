#!/usr/bin/env node

const express = require('express')
const app = express()

app.get('/', function(req, resp) {
  resp.send('Hello, world!')
})

app.get('/:type', function(req, resp) {
  console.log(new Date())
  resp.send({ type: req.params.type, version: '3', files: [ 'application.lua' ] })
})

app.get('/alamakota/application.lua', function(req, resp) {
  console.log("Getting application.lua")
  resp.send('print("Hello, world!")\n')
})


app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
