for name, machine in pairs(data.raw["assembling-machine"]) do
  machine.thermal_system = {}
end

for name, machine in pairs(data.raw["furnace"]) do
  machine.thermal_system = {}
end

for name, machine in pairs(data.raw["lab"]) do
  machine.thermal_system = {}
end

for name, machine in pairs(data.raw["beacon"]) do
  machine.thermal_system = {}
end

--assembling machine 1
  local ass1 =data.raw["assembling-machine"]["assembling-machine-1"]
  ass1.thermal_system = {
    connections = {
      { position = {0, -1}, direction = defines.direction.north },
      { position = {1, 0}, direction = defines.direction.east },
      { position = {0, 1}, direction = defines.direction.south },
      { position = {-1, 0}, direction = defines.direction.west },
    },
    max_safe_temperature = 500,
  }
--recylers goofy ass fucking layout
  local piss =data.raw["furnace"]["recycler"]
  piss.thermal_system = {
    connections = {
      { position = {0.5, -1.5}, direction = defines.direction.north },
      { position = {-0.5, -0.5}, direction = defines.direction.north },
      { position = {0.5, 1.5}, direction = defines.direction.south },
      { position = {-0.5, 0.5}, direction = defines.direction.west },
    },
  }