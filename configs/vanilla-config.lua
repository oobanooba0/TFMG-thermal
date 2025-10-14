if settings.startup["use-config"].value == "vanilla" then

--assembling machine 3
local ass3 =data.raw["assembling-machine"]["assembling-machine-3"]
ass3.thermal_system = {
  connections = {
    { position = {-1, -1}, direction = defines.direction.north },
    { position = {1, -1}, direction = defines.direction.east },
    { position = {1, 1}, direction = defines.direction.south },
    { position = {-1, 1}, direction = defines.direction.west },
  },
}

end