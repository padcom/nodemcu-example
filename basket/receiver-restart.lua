status, err = pcall(function()
  receiver.stop()
  dofile('receiver.lua')
  receiver.start(8)
end)

if not status then
  print("ERROR: " .. err)
end
