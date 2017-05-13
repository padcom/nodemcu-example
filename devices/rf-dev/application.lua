-- Clear prompt
print("\n")

local BUFFER_SIZE = 1024
local timings = { }
local write = 0
local read = 0
local max = 0

local function count()
  if write == read then
    return 0
  elseif write > read then
    return write - read
  else
    return BUFFER_SIZE + write - read;
  end
end

local prev_ts = 0

function capture(level, ts)
  local len = math.abs(prev_ts - ts)
  prev_ts = ts

  if count() < BUFFER_SIZE - 1 then
    write = (write + 1) % BUFFER_SIZE
    timings[write] = len
  end
end

local STATE_PREAMBLE = 0
local STATE_BIT_HIGH = 1
local STATE_BIT_LOW  = 2
local STATE_WS_PAUSE = 3

local state  = 0
local preamb = 0
local long   = 0
local short  = 0
local bits   = 24
local nibble = 0
local bit    = 0
local code   = 0
local callback = function(code, bits, preamble, short, long) end

local function process()
  local t1 = tmr.now()
  local c = count()
  while count() > 0 do
    -- advance to next available byte
    read = (read + 1) % BUFFER_SIZE
    if state == STATE_PREAMBLE then
      if timings[read] > 6000 then
        preamble = timings[read]
        long     = (preamble * 3) / 31
        short    = (preamble * 1) / 31
        bit      = 0
        code     = 0
        state    = STATE_BIT_HIGH
        -- print('P:', timings[read], long, short, 24)
      end
    elseif state == STATE_BIT_HIGH then
      -- print('H:', timings[read])
      if math.abs(timings[read] - long) < (long * 10) / 25 then
        nibble = 30
        state  = STATE_BIT_LOW
      elseif math.abs(timings[read] - short) < (short * 10) / 15 then
        nibble = 10
        state = STATE_BIT_LOW
      else
        state = STATE_PREAMBLE
        -- print('E')
      end
    elseif state == STATE_BIT_LOW then
      -- print('L:', timings[read])
      if math.abs(timings[read] - long) < (long * 10) / 25 then
        nibble = nibble + 3
        state  = STATE_BIT_HIGH
      elseif math.abs(timings[read] - short) < (short * 10) / 15 then
        nibble = nibble + 1
        state = STATE_BIT_HIGH
      else
        state = STATE_PREAMBLE
        -- print('E')
      end

      if state == STATE_BIT_HIGH then
        -- print('C:', bit, nibble)
        if nibble == 13 then
          code = code * 2
          bit = bit + 1
        elseif nibble == 31 then
          code = code * 2 + 1
          bit = bit + 1
        else
          state = STATE_PREAMBLE
          -- print('E')
        end
      end

      if state == STATE_BIT_HIGH and bit == bits then
        callback(code, bits, preamble, short, long)
        state = STATE_PREAMBLE
      end
    else
      state = STATE_PREAMBLE
    end
  end

--  print(c, (tmr.now() - t1))
end

function init(pin, led, cb)
  for i = 0, BUFFER_SIZE - 1 do
    timings[i] = 0
  end

  callback = cb

  gpio.mode(pin, gpio.INT, gpio.PULLUP)
  gpio.trig(pin, "both", capture)

  tmr.create():alarm(10, tmr.ALARM_AUTO, process)

  gpio.mode(led, gpio.OUTPUT)
  gpio.write(led, 0)
end

rfrecv = {
  init = init,
  run  = process
}

rfrecv.init(GPIO4, GPIO2, function(code, bits, preamble, short, long)
  print('CODE: ', code, bits, preamble, short, long)
end)

print("Receiver: started")
