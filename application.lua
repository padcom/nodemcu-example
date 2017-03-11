-- Initialize MQTT client
m = mqtt.Client()

-- Connect to MQTT server
m:connect("192.168.32.2", 1883, 0, 1, function(client)
  print("MQTT: connected");
  m:subscribe("switch", 0);
end)

-- Send log message
function log(message, params)
  -- define base GEFL structure
  local entry = {
    version = '1.1',
    source = 'NodeMCU-' .. node.chipid(),
    facility = "433-rf-gateway",
    short_message = message
  }
  -- add any custom parameters
  for k, v in pairs(params) do
    entry['_' .. k] = v
  end
  -- send the log entry
  pcall(function()
    m:publish("system/logs", cjson.encode(entry), 0, 0)
  end)
end

-- Process MQTT topic messages
m:on("message", function(c, topic, message)
  print("MQTT: topic=" .. topic .. "; message=" .. message)

  -- when a message is received on 'switch' queue send that code via RF transmitter
  if topic == "switch" then
    log("Switch toggle", { code = tonumber(message) })
    rfswitch.send(1, 350, 4, 6, tonumber(message), 24)
  end
end)

print("MQTT: setup completed")
