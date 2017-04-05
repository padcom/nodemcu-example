#!/usr/bin/env node

const express = require('express')
const app = express()

app.get('/', function(req, resp) {
  resp.send('Hello, world!')
})

app.get('/:type', function(req, resp) {
  resp.send({ type: req.params.type, version: '3' })
})

app.get('/alamakota/application.lua', function(req, resp) {
  resp.send('print("Hello, world!")')
})


app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
