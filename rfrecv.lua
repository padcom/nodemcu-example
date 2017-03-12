rfrecv = {
  -- Protocol specification
  -- ORNO: PULSE=400, SIGMA=200, PREAMBLE=6, LONG=3, SHORT=1, BITS=30
  -- TEMP: PULSE=350, SIGMA=175, PREAMBLE=31, LONG=3, SHORT=1, BITS=24
  PULSE     = 400,  -- pulse length (in ms)
  SIGMA     = 200,  -- pulse tolerance (50% of the pulse)
  PREAMBLE  = 6,    -- length of preamble
  LONG      = 3,    -- length of long pulse
  SHORT     = 1,    -- length of short pulse
  BITS      = 30,   -- number of bits

  -- Public state
  pin = 7,          -- pin to listen for incoming pulses
  led = 4,
  enabled = false,  -- receiver state
  code = 0,         -- last received code (0 if none)
  callback = nil,

  -- start receiving pulses
  start = function(pin, led, callback)
    rfrecv.pin = pin
    rfrecv.led = led
    rfrecv.callback = callback
    rfrecv.enabled = true

    rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE

    gpio.mode(rfrecv.led, gpio.OUTPUT)
    rfrecv._led = true

    gpio.mode(rfrecv.pin, gpio.INT, gpio.PULLUP)
    gpio.trig(rfrecv.pin, "both", rfrecv.pincb)

    print("Receiver: started")
  end,

  -- stop receiving pulses
  stop = function()
    rfrecv.enabled = false
    gpio.trig(rfrecv.pin)

    rfrecv._state = rfrecv.STATE_IDLE

    print("Receiver: stopped")
  end,

  -- Internal state
  _value  = 0,
  _bit    = 0,
  _nibble = 0,
  _prevts = 0,
  _state  = function(len) end,
  _led    = true,

  toggle_led = function()
    gpio.write(rfrecv.led, rfrecv._led and gpio.HIGH or gpio.LOW)
    rfrecv._led = not rfrecv._led
  end,

  pincb = function(level, ts)
    rfrecv.toggle_led()

    local len = ts - rfrecv._prevts
    rfrecv._prevts = ts
    rfrecv._state(len)
  end,

  STATE_IDLE = function(len)
  end,

  STATE_WAIT_PREAMBLE = function(len)
    if math.abs(len - (rfrecv.PULSE * rfrecv.PREAMBLE)) < rfrecv.SIGMA then
      rfrecv._value = 0
      rfrecv._bits  = 0
      rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
    end
  end,

  STATE_READ_WIRE_BIT_HIGH = function(len)
    -- read higher wire bit
    if math.abs(len - (rfrecv.PULSE * rfrecv.LONG)) < rfrecv.SIGMA then
      rfrecv._nibble = 30
      rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_LOW
    elseif math.abs(len - (rfrecv.PULSE * rfrecv.SHORT)) < rfrecv.SIGMA then
      rfrecv._nibble = 10
      rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_LOW
    else
      rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
    end
  end,

  STATE_READ_WIRE_BIT_LOW = function(len)
    -- read lower wire bit
    if (math.abs(len - (rfrecv.PULSE * rfrecv.LONG)) < rfrecv.SIGMA) then
      rfrecv._nibble = rfrecv._nibble + 3
      rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
    elseif math.abs(len - (rfrecv.PULSE * rfrecv.SHORT)) < rfrecv.SIGMA then
      rfrecv._nibble = rfrecv._nibble + 1
      rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
    else
      rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
    end

    -- decode wire bits to data bits
    if rfrecv._state == rfrecv.STATE_READ_WIRE_BIT_HIGH then
      rfrecv._value = rfrecv._value * 2
      rfrecv._bits = rfrecv._bits + 1
      if rfrecv._nibble == 13 then
        rfrecv._value = rfrecv._value * 2
        rfrecv._bits = rfrecv._bits + 1
      elseif rfrecv._nibble == 31 then
        rfrecv._value = (rfrecv._value * 2) + 1
        rfrecv._bits = rfrecv._bits + 1
      else
        rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
      end
    end

    -- entire value has been read
    if rfrecv._state == rfrecv.STATE_READ_WIRE_BIT_HIGH and rfrecv._bits == rfrecv.BITS then
      rfrecv.found = true
      rfrecv.code = rfrecv._value
      rfrecv.callback(rfrecv.code, rfrecv._bits)
      rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
    end
  end
}
