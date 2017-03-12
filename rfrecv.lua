rfrecv = {
  _pin = 5,
  _adr = 8,
  _len = 8,

  start = function(pin, sda, scl, address)
    rfrecv._adr = address
    rfrecv._pin = pin
    i2c.setup(0, sda, scl, i2c.SLOW)
    gpio.mode(rfrecv._pin, gpio.INT, gpio.PULLUP)
    gpio.trig(rfrecv._pin, "down", rfrecv.read)
  end,

  stop = function()
    gpio.trig(rfrecv._pin)
  end,

  read = function(level, ts)
    pcall(function()
      i2c.start(0)
      i2c.address(0, rfrecv._adr, i2c.RECEIVER)
      local code = 0
      code = tonumber(i2c.read(0, rfrecv._len))
      i2c.stop(0)
      if code and code > 0 then
        log("Switch received", { code = code })
        publish("bus/rf/433/in", code .. ",24", 0, 0)
      end
    end)
  end
}

