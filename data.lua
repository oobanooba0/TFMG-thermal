require("prototypes.prototypes")
require("prototypes.custom-inputs")

local pump = data.raw["pump"]["pump"]

pump.TFMG_thermal = {
  connections = {
    { position = {0, 0.5}, direction = 4},
  },
}

local wpump = data.raw["offshore-pump"]["offshore-pump"]

wpump.TFMG_thermal = {
  connections = {
    { position = {0, -0.5}, direction = 4},
  },


}

