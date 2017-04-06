#!/usr/bin/env node

const log = require('winston').log;
const express = require('express')
const app = express()
const fs = require('fs')
const path = require('path')
const mime = require('mime')

const devices = {
  'rf-gateway': {
    version: '15',
    files: [ 'temp.lua', 'application.lua', 'rfrecv.lua', 'rfsender.lua' ]
  }
}

app.get('/:type', function(req, resp) {
  const version = devices[req.params.type] ? devices[req.params.type].version : '?'
  log("info", "GET " + req.params.type + "/" + version)

  if (devices[req.params.type]) {
    resp.send(devices[req.params.type])
  } else {
    resp.writeHead(404)
    resp.end("Unknow device type")
  }
})

app.get('/:type/:file', function(req, resp) {
  const version = devices[req.params.type] ? devices[req.params.type].version : '?'
  log("info", "GET " + req.params.type + "/" + version + "#" + req.params.file)

  if (devices[req.params.type]) {
    const filePath = path.join(__dirname, '../devices/' + req.params.type + '/' + req.params.file);

    if (fs.existsSync(filePath)) {
      const stat = fs.statSync(filePath);
      resp.writeHead(200, {
        'Content-Type': mime.lookup(req.params.file),
        'Content-Length': stat.size
      });
      fs.createReadStream(filePath).pipe(resp);
    } else {
      resp.writeHead(404)
      resp.end("File not found")
    }
  } else {
    resp.writeHead(404)
    resp.end("Unknown device type")
  }
})


app.listen(3000, function () {
  log("info", 'Example app listening on port 3000!')
})
