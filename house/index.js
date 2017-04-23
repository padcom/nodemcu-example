#!/usr/bin/env node

console.log("Hello")

const mqtt = require('mqtt')
const client  = mqtt.connect('mqtt://192.168.32.2', { clientId: 'house' })

const express = require('express')
const app = express()

app.use(express.static('public'))
app.use(require('body-parser').json())

const switches = {
  'bathroom1': { on: '5575697', off: '5575700' },
  'bathroom2': { on: '5575745', off: '5575748' },
  'big-room-right': { on: 5576017, off: 5576020 },
  'big-room-left': { on: 5576001, off: 5576004 },
  'kitchen': { on: 5575953, off: 5575956 },
  'garderoba': { on: 5575937, off: 5575940 },
  'restroom': { on: 5575761, off: 5575764 },
  'czarek': { on: 7864320, off: 5592404 },
  'adas': { on: 5574993, off: 5574996 },
}

app.post('/api/switch/:switch', function(req, res) {
  const sw = req.params.switch
  const state  = req.body.state
  if (switches[sw]) {
    if (switches[sw][state]) {
      client.publish('bus/rf/433/out', `1,350,6,${switches[req.params.switch][req.body.state]},24`)
      res.status(202).send("OK")
    } else {
      res.status(400).send("Operation on switch not available")
    }
  } else {
    res.status(404).send("Switch not found")
  }
})

app.listen(3001, function () {
  console.log('Example app listening on port 3001!')
})
