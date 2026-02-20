require("prototypes.prototypes")
require("prototypes.custom-inputs")

data.raw.furnace.recycler.TFMG_thermal = {
  max_working_temperature = 300,
  max_safe_temperature = 450,
  heat_ratio = 0.7,
  connections = {
    { position = {0.5, 1}, direction = 4},
    --{ position = {0.5, -1}, direction = 4},
    --{ position = {-0.5, 1}, direction = 12},
    --{ position = {-0.5, -1}, direction = 12},
  },
}

