remote.add_interface("TFMG-thermal",
  {
    ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
    ---@param pause boolean #weather this entity should be paused or not.
    ---Sets a thermal interfaces pause property, paused interfaces will not produce heat.
    set_interface_pause = function(machine,pause) TFMG_thermal_util.set_interface_pause(machine,pause) end,

    ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
    ---@return boolean|nil #returns the current paused state of the thermal interface, nil if no thermal interface is found
    ---reads a thermal interfaces current pause status
    get_interface_pause = function(machine) return TFMG_thermal_util.read_interface_pause(machine) end,

    ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
    ---@return boolean|nil #returns the paused state of the thermal interface (after toggling), nil if no thermal interface is found
    ---toggles weather a thermal interface is paused.
    toggle_interface_pause = function(machine) return TFMG_thermal_util.toggle_interface_pause(machine) end,
  }
)


