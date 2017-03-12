LED_PIN = 8

gpio.mode(LED_PIN, gpio.OUTPUT)
led_value = true

function led_toggle()
  gpio.write(LED_PIN, led_value and gpio.HIGH or gpio.LOW)
  led_value = not led_value
end

receiver = {
  -- Protocol specification
  PULSE     = 400,  -- pulse length (in ms)
  SIGMA     = 300,  -- pulse tolerance (50% of the pulse)
  PREAMBLE  = 31,   -- length of preamble
  LONG      = 3,    -- length of long pulse
  SHORT     = 1,    -- length of short pulse
  BITS      = 24,   -- number of bits

  -- Public state
  pin = 7,          -- pin to listen for incoming pulses
  enabled = false,  -- receiver state
  code = 0,         -- last received code (0 if none)

  -- start receiving pulses
  start = function(pin)
    receiver.pin = pin
    receiver.enabled = true

    receiver._state = receiver.STATE_WAIT_PREAMBLE

    gpio.mode(receiver.pin, gpio.INT, gpio.PULLUP)
    gpio.trig(receiver.pin, "down", receiver.pincb)

    print("Receiver: started")
  end,

  -- stop receiving pulses
  stop = function()
    receiver.enabled = false
    gpio.trig(receiver.pin)

    receiver._state = receiver.STATE_IDLE

    print("Receiver: stopped")
  end,

  -- Internal state
  _value  = 0,
  _bit    = 0,
  _nibble = 0,
  _prevts = 0,
  _state  = function(len) end,

  pincb = function(level, ts)
    led_toggle()
    local len = ts - receiver._prevts
--    print(level, len, ts)
    print(level, len, ts)
    receiver._prevts = ts
    receiver._state(len)
    gpio.trig(receiver.pin, level == gpio.HIGH and "down" or "up")
  end,

  STATE_IDLE = function(len)
  end,

  STATE_WAIT_PREAMBLE = function(len)
    if math.abs(len - (receiver.PULSE * receiver.PREAMBLE)) < receiver.SIGMA then
      receiver._value = 0
      receiver._bits  = 0
      receiver._state = receiver.STATE_READ_WIRE_BIT_HIGH
    end
  end,

  STATE_READ_WIRE_BIT_HIGH = function(len)
    -- read higher wire bit
    if math.abs(len - (receiver.PULSE * receiver.LONG)) < receiver.SIGMA then
      receiver._nibble = 30
      receiver._state = receiver.STATE_READ_WIRE_BIT_LOW
    elseif math.abs(len - (receiver.PULSE * receiver.SHORT)) < receiver.SIGMA then
      receiver._nibble = 10
      receiver._state = receiver.STATE_READ_WIRE_BIT_LOW
    else
      print("ERROR: STATE_READ_WIRE_BIT_HIGH -> STATE_WAIT_PREAMBLE", receiver._bits, len)
      receiver._state = receiver.STATE_WAIT_PREAMBLE
    end
  end,

  STATE_READ_WIRE_BIT_LOW = function(len)
    -- read lower wire bit
    if (math.abs(len - (receiver.PULSE * receiver.LONG)) < receiver.SIGMA) then
      receiver._nibble = receiver._nibble + 3
      receiver._state = receiver.STATE_READ_WIRE_BIT_HIGH
    elseif math.abs(len - (receiver.PULSE * receiver.SHORT)) < receiver.SIGMA then
      receiver._nibble = receiver._nibble + 1
      receiver._state = receiver.STATE_READ_WIRE_BIT_HIGH
    else
      print("ERROR: STATE_READ_WIRE_BIT_LOW -> STATE_WAIT_PREAMBLE", receiver._bits, len)
      receiver._state = receiver.STATE_WAIT_PREAMBLE
    end

    -- decode wire bits to data bits
    if receiver._state == receiver.STATE_READ_WIRE_BIT_HIGH then
      receiver._value = receiver._value * 2
      receiver._bits = receiver._bits + 1
      if receiver._nibble == 13 then
        receiver._value = receiver._value * 2
        receiver._bits = receiver._bits + 1
      elseif receiver._nibble == 31 then
        receiver._value = (receiver._value * 2) + 1
        receiver._bits = receiver._bits + 1
      else
        print("ERROR: STATE_READ_WIRE_BIT_LOW2 -> STATE_WAIT_PREAMBLE", receiver._bits, len)
        receiver._state = receiver.STATE_WAIT_PREAMBLE
      end
    end

    -- entire value has been read
    if receiver._state == receiver.STATE_READ_WIRE_BIT_HIGH and receiver._bits == receiver.BITS then
      receiver.found = true
      receiver.code = receiver._value
      print(receiver.code)
      receiver._state = receiver.STATE_WAIT_PREAMBLE
    end
  end
}
