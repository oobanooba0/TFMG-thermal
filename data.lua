require("prototypes.prototypes")
require("prototypes.custom-inputs")

for _ , entity in pairs(data.raw["furnace"]) do
  entity.TFMG_thermal = {}
end

data.raw["thruster"]["thruster"].TFMG_thermal = {}