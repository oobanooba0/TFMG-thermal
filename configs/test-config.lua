data.raw["assembling-machine"]["assembling-machine-2"].thermal_system = true
data.raw["assembling-machine"]["assembling-machine-3"].thermal_system = true
data.raw["assembling-machine"]["chemical-plant"].thermal_system = true
data.raw["assembling-machine"]["centrifuge"].thermal_system = true
data.raw["assembling-machine"]["oil-refinery"].thermal_system = true
data.raw["furnace"]["electric-furnace"].thermal_system = true
data.raw["furnace"]["steel-furnace"].thermal_system = true
data.raw["furnace"]["stone-furnace"].thermal_system = true

--assembling machine 1
  local ass1 = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  ass1.thermal_system = true
  ass1.thermal_system_connections = {
    { position = {0, -1}, direction = defines.direction.north },
    { position = {1, 0}, direction = defines.direction.east },
    { position = {0, 1}, direction = defines.direction.south },
    { position = {-1, 0}, direction = defines.direction.west },
  }
  data.raw["assembling-machine"]["assembling-machine-1"] = ass1