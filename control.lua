TFMG_thermal_core = require("scripts.TFMG-thermal-core")
--handles the core behaviour of thermal entities (heating, overheating, lag)
TFMG_thermal_compound = require("scripts.TFMG-thermal-compound")
--handles everything relating to assembling, rotating, and destorying compound entities
TFMG_thermal_gui = require("scripts.TFMG-thermal-gui")
--handles everything relating to the gui
TFMG_thermal_util = require("scripts.TFMG-thermal-util")
--handles making my life easier by declaring a handfull of handy functions that I will only use once, but I will totally swear were worth making.
require("scripts.on-events")
--triggers various scripts based on events.