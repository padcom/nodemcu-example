-- http://lua-users.org/wiki/ObjectOrientationTutorial

RfSender = {}
RfSender.__index = RfSender

setmetatable(RfSender, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

-- syntax equivalent to "MyClass.new = function..."
function RfSender.new(dataPin, powerPin, indicatorPin)
  local self = setmetatable({}, RfSender)
  self.dataPin = dataPin
  self.powerPin = powerPin
  self.indicatorPin = indicatorPin

  self:initialize()
  self:stop()

  return self
end

function RfSender:send(protocol, pulse, repetitions, code, length)
  self:start()
  rfswitch.send(protocol, pulse, repetitions, self.dataPin, code, length)
  self:stop()
end

function RfSender:initialize()
  gpio.mode(self.dataPin, gpio.OUTPUT)
  gpio.mode(self.powerPin, gpio.OUTPUT)
  gpio.mode(self.indicatorPin, gpio.OUTPUT)
end

function RfSender:start()
  if self.powerPin then
    gpio.write(self.powerPin, gpio.HIGH)
  end
  if self.indicatorPin then
    gpio.write(self.indicatorPin, gpio.HIGH)
  end
end

function RfSender:stop()
  if self.indicatorPin then
    gpio.write(self.indicatorPin, gpio.LOW)
  end
  if self.powerPin then
    gpio.write(self.powerPin, gpio.LOW)
  end
end
