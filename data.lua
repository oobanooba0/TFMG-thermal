require("prototypes.prototypes")
require("prototypes.custom-inputs")

--data.raw["assembling-machine"]["assembling-machine-1"].thermal_system = {}
--data.raw["mining-drill"]["electric-mining-drill"].thermal_system = {}
--data.raw["mining-drill"]["pumpjack"].thermal_system = {}

for name, prototype in pairs(data.raw["assembling-machine"]) do
  prototype.thermal_system = {}
end