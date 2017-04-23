
rfrecv = {
  -- Protocol specification
  -- ORNO: PULSE=400, SIGMA=200, PREAMBLE=6, LONG=3, SHORT=1, BITS=24
  -- TEMP: PULSE=350, SIGMA=175, PREAMBLE=31, LONG=3, SHORT=1, BITS=24
  PREAMBLE  = 7000, -- length of preamble
  BITS      = 24,   -- number of bits

  -- Public state
  pin = GPIO13,    -- pin to listen for incoming pulses
  led = GPIO2,      -- led that will go on/off on edge change (for debugging, built-in led)
  enabled = false,  -- receiver state
  code = 0,         -- last received code (0 if none)
  callback = nil,   -- callback to be called when a code is successfuly retrieved

  -- start receiving pulses
  start = function(pin, led, callback)
    rfrecv.pin = pin
    rfrecv.led = led
    rfrecv.callback = callback
    rfrecv.enabled = true

    rfrecv._state = STATE_WAIT_PREAMBLE

    gpio.mode(rfrecv.led, gpio.OUTPUT)
    rfrecv._led = true

    gpio.mode(rfrecv.pin, gpio.INT, gpio.PULLUP)
    gpio.trig(rfrecv.pin, "both", rfrecv.pincb)

    gpio.write(rfrecv.led, 0)
    print("Receiver: started")
  end,

  -- stop receiving pulses
  stop = function()
    rfrecv.enabled = false
    gpio.trig(rfrecv.pin)

    rfrecv._state = STATE_WAIT_PREAMBLE

    gpio.write(rfrecv.led, 1)
    print("Receiver: stopped")
  end,

  -- Internal state
  _value  = 0,
  _bit    = 0,
  _nibble = 0,
  _prevts = 0,
  _state  = 0,

  STATE_WAIT_PREAMBLE      = 0,
  STATE_READ_WIRE_BIT_HIGH = 1,
  STATE_READ_WIRE_BIT_LOW  = 2,

  pincb = function(level, ts)
--    gpio.write(rfrecv.led, level)

    local len = ts - rfrecv._prevts
    rfrecv._prevts = ts

    if rfrecv._state == rfrecv.STATE_WAIT_PREAMBLE then
      -- receive preamble
      if len > rfrecv.PREAMBLE then
        rfrecv._value = 0
        rfrecv._bits  = 0
        rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
        rfrecv.SHORT = len/31
        rfrecv.LONG  = len/11
      end
    elseif rfrecv._state == rfrecv.STATE_READ_WIRE_BIT_HIGH then
      -- read higher wire bit
      if math.abs(len - rfrecv.LONG) < (rfrecv.LONG*10)/25 then
        rfrecv._nibble = 30
        rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_LOW
      elseif math.abs(len - rfrecv.SHORT) < (rfrecv.SHORT*10)/15 then
        rfrecv._nibble = 10
        rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_LOW
      else
        rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
      end
    elseif rfrecv._state == rfrecv.STATE_READ_WIRE_BIT_LOW then
      -- read lower wire bit
      if math.abs(len - rfrecv.LONG) < rfrecv.LONG/3 then
        rfrecv._nibble = rfrecv._nibble + 3
        rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
      elseif math.abs(len - rfrecv.SHORT) < rfrecv.SHORT/2 then
        rfrecv._nibble = rfrecv._nibble + 1
        rfrecv._state = rfrecv.STATE_READ_WIRE_BIT_HIGH
      else
        rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
      end

      -- decode wire bits to data bits
      if rfrecv._state == rfrecv.STATE_READ_WIRE_BIT_HIGH then
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
    else
      rfrecv._state = rfrecv.STATE_WAIT_PREAMBLE
    end
  end
}
