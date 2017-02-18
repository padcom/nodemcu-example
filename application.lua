clientId = "63159510-f108-11e6-a446-0d180dc59d42"
username = "9e6444c0-de9a-11e6-97cc-8758d0339dd8"
password = "e7c5e8247f9da1284ef3480fa7b55a547c22ae74"

nodeId   = "5e6fbbb0-f0b0-11e6-a971-4db18559717d"

m = mqtt.Client(clientId, 120, username, password, 1)
m_connected = false

function m_publish(device, data)
  if m_connected then
    m:publish("v1/" .. username .."/things/" .. clientId .. "/data/" .. device, data, 0, 0)
  else
    print("Not publising - disconnected (" .. device .. " / " .. data .. ")")
  end
end

m:on("offline", function(con)
  print("MQTT: disconnected (heap: " .. node.heap() .. ")")
  m_connected = false
end)

gniazdko = 0

m:on("message", function(client, topic, data)
  print("MQTT: " .. topic)
  if data ~= nil then
    print("  > " .. data)
  end

  if topic == "v1/" .. username .."/things/" .. clientId .. "/cmd/3" then
    if gniazdko == 0 then
      gniazdko = 1
      rfswitch.send(4, 400, 4, 6, 8305925, 24)
    else
      gniazdko = 0
      rfswitch.send(4, 400, 4, 6, 7952341, 24)
    end
    m_publish(3, "" .. gniazdko)
  end
end)

m:connect("mqtt.mydevices.com", 1883, 0, 1, function(client)
  m_connected = true
  print("MQTT: connected");
  m:subscribe("v1/".. username .. "/things/" .. nodeId .. "/cmd/1", 0, function()
    print("MQTT: subscribe successful")
  end)
  m:subscribe("v1/".. username .. "/things/" .. clientId .. "/cmd/3", 0, function()
    print("MQTT: subscribe successful")
  end)
end)

print("MQTT: setup completed")

bmp085.init(2, 1)
tmr.create():alarm(5000, tmr.ALARM_AUTO, function()
  local t = bmp085.temperature()
  local p = bmp085.pressure()
  m_publish(0, "temp,c=" .. string.format("%s.%s", t / 10, t % 10), 0, 0)
  m_publish(1, "press,hpa=" .. (p/100), 0, 0)
end)
print("BMP180: setup completed")

rotary.setup(0, 3, 4, 5)
rotaryUpdateTimer = tmr.create()
rotaryUpdateValue = 0
rotary.on(0, rotary.ALL, function(type, pos, when)
  if type == rotary.TURN then
    if rotaryUpdateTimer:state() ~= nil then
      rotaryUpdateTimer:stop()
    end
    rotaryUpdateTimer:register(100, tmr.ALARM_SINGLE, function()
      m_publish(2, "temp,c=" .. (pos/4), 0, 0)
    end)
    rotaryUpdateTimer:start()
  end
end)
print("ROTARY: setup completed")
