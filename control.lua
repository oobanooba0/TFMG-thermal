--grab my TFMG lib functions
TFMG = require("__TFMG-lib__.control.util") --a few of my utility/debug functions.
TFMG_table = require("__TFMG-lib__.control.table") --table functions

TFMG_thermal_util = require("scripts.TFMG-thermal-util")--thermal specific utility functions

TFMG_thermal_core = require("scripts.TFMG-thermal-core")
--handles the core behaviour of thermal entities (heating, overheating, lag)
TFMG_thermal_compound = require("scripts.TFMG-thermal-compound")
--handles everything relating to assembling, rotating, and destorying compound entities
TFMG_thermal_gui = require("scripts.TFMG-thermal-gui")
--handles everything relating to the gui

require("scripts.on-events")
--triggers various scripts based on events.
require("scripts.TFMG-remote")