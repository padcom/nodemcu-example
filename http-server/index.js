#!/usr/bin/env node

const express = require('express')
const app = express()
const fs = require('fs')
const path = require('path')

app.get('/', function(req, resp) {
  resp.send('Hello, world!')
})

app.get('/:type', function(req, resp) {
  console.log(new Date())
  resp.send({ type: req.params.type, version: '8', files: [ 'application.lua', 'rfrecv.lua' ] })
})

app.get('/alamakota/:file', function(req, resp) {
  console.log("Getting " + req.params.file)

  const filePath = path.join(__dirname, '../' + req.params.file);
  const stat = fs.statSync(filePath);

  resp.writeHead(200, {
    'Content-Type': 'application/lua',
    'Content-Length': stat.size
  });

  fs.createReadStream(filePath).pipe(resp);
})


app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
