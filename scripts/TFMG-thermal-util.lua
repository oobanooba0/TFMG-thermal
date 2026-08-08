local TFMG_thermal_util = {}

  TFMG_thermal_util.ruleset_lookup = {
  --rotation ruleset lookup table
  --R = Rotatable
  --r = Rotatable, but 180 degrees.
  --F = flippable,
  --08 = 8 unique variations.
  --01 = 1 unique variations.

  --we map each initial orientation, to next orientation.
  --rotations are formatted differently to the base game. 1-4 are NESW, and 5-8 are NESW (mirrored)
    RF_08 = {--Normal, free rotation, for square machines, and 8direction machines in hand
      rotate = {2,3,4,1,6,7,8,5},
      rotate_reverse = {4,1,2,3,8,5,6,7},
      flip_horizontal = {5,8,7,6,1,4,3,2},
      flip_vertical = {7,6,5,8,3,2,1,4},
    },
    rF_08 = {--restricted rotations for rectangular machines.
      rotate = {3,4,1,2,7,8,5,6},
      rotate_reverse = {3,4,1,2,7,8,5,6},
      flip_horizontal = {5,8,7,6,1,4,3,2},
      flip_vertical = {7,6,5,8,3,2,1,4},
    },
    _01 = {
      rotate = {1},
      rotate_reverse = {1},
      flip_horizontal = {1},
      flip_vertical = {1},
    },
  }

  TFMG_thermal_util.direction_to_orientation = {--provide direction, then mirroring, return orientation
    [defines.direction.north] = {[false] = 1, [true] = 5},
    [defines.direction.east] = {[false] = 2, [true] = 6},
    [defines.direction.south] = {[false] = 3, [true] = 7},
    [defines.direction.west] = {[false] = 4, [true] = 8},
  }

  TFMG_thermal_util.orientation_to_direction = {--provide orientation, return direction and mirroring
    [1] = {direction = defines.direction.north, mirroring = false},
    [2] = {direction = defines.direction.east, mirroring = false},
    [3] = {direction = defines.direction.south, mirroring = false},
    [4] = {direction = defines.direction.west, mirroring = false},
    [5] = {direction = defines.direction.north, mirroring = true},
    [6] = {direction = defines.direction.east, mirroring = true},
    [7] = {direction = defines.direction.south, mirroring = true},
    [8] = {direction = defines.direction.west, mirroring = true},
  }

  function TFMG_thermal_util.advanced_rotate(entity,transform,ruleset)
    if not ruleset then ruleset = "RF_08" end
    --lookup table madness
    local orientation = TFMG_thermal_util.direction_to_orientation[entity.direction][entity.mirroring]
    local new_orientation = TFMG_thermal_util.ruleset_lookup[ruleset][transform][orientation]
    local new_direction = TFMG_thermal_util.orientation_to_direction[new_orientation]
    entity.direction = new_direction.direction
    entity.mirroring = new_direction.mirroring
    --we should do something, to verify consistency between the interface and machine.
  end

  function TFMG_thermal_util.surface_condition_compare(surface,conditions)--conditions should be as table
    if conditions == nil then return true end
    for _ , condition in pairs(conditions) do
      local surface_condition_value = surface.get_property(prototypes.surface_property[condition.property])
      if condition.min > surface_condition_value or surface_condition_value > condition.max then return false end
    end
  return true end

  function TFMG_thermal_util.get_entry_from_input_event(event)

    --check if the thing we're hovering has a thermal prototype. if not, we can quit while we're ahead.
    if not event.selected_prototype or storage.interfaces[event.selected_prototype.name] == nil then return end

    --if you're holding a buildable item, blueprint, or ghost, then no rotation should happen.
    local player = game.players[event.player_index]
    if not player.is_cursor_empty() then
      local cursor_stack
      if player.cursor_stack and player.cursor_stack.valid_for_read then
        cursor_stack = player.cursor_stack.prototype
      elseif player.cursor_ghost then
        cursor_stack = player.cursor_ghost.name
      end
      if not cursor_stack then return end
      if cursor_stack.place_result then return end
    end

    --actually collect the specific interface entry
    local interface_table = storage.interfaces[event.selected_prototype.name]
    local machine_prototype = event.selected_prototype
    local surface = player.surface
    local machine = surface.find_entity(machine_prototype.name,event.cursor_position)
    if machine == nil then return end
    local v = interface_table[machine.unit_number]
  return v end
  --subtick abuse function, copied and modified from The lord thy god
  local INVISIBLE_LINE = {
	  color = { 0, 0, 0, 0 },
	  width = 0,
	  from = { 0, 0 },
	  to = { 0, 0 },
	  surface = 1,
  }


  function TFMG_thermal_util.subtick_trigger_abuse(data)--data should be a table, and contain a data type field, which will be used to identify what its used for.
    local obj = rendering.draw_line(INVISIBLE_LINE)
    --local fish = game.surfaces[1].create_entity({
    --  name = "fish",
    --  position = {0,0},
    --  player = (data.player_index or 1),
    --  undo_index = 0,
    --})
    --game.print(serpent.block(game.players[1].undo_redo_stack.get_undo_item(1)))

    --heres the issue, i can create the undo action, but if i destroy the fish, the undo action goes with it.
    --fuck me am i right.

	  local rn = script.register_on_object_destroyed(obj)
    if not storage.smuggled_data then storage.smuggled_data = {} end
    storage.smuggled_data[rn] = data
    obj.destroy()
  end

  function TFMG_thermal_util.generate_undo_item(player)--generates a new undo item, for when we need one
    local surface = player.surface
    local undo_proxy = surface.find_entity("TFMG-thermal-undo-redo-proxy",{0,0})
    if not undo_proxy then
      undo_proxy = surface.create_entity({name = "TFMG-thermal-undo-redo-proxy",position = {0,0},force = "player"})
    end
    undo_proxy.rotate({by_player = player})
    --game.print(serpent.block(game.players[1].undo_redo_stack.get_undo_item(1)))
  end
  function TFMG_thermal_util.get_entry_from_machine(machine)

    local interfaces = storage.interfaces
    local name
    local unit_number

    local type = type(machine)
    if type == "number" then
      unit_number = machine
      name = storage.registered_entities[unit_number]
      if not name then return end
    else
      name = machine.name
      unit_number = machine.unit_number
    end

    if not interfaces[name] then return end
  return interfaces[name][unit_number] end


  ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
  ---@param pause boolean #weather this entity should be paused or not.
  function TFMG_thermal_util.set_interface_pause(machine,pause)
    local entry = TFMG_thermal_util.get_entry_from_machine(machine)
    if not entry then return end
    entry.paused = pause
  end

  ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
  function TFMG_thermal_util.read_interface_pause(machine)
    local entry = TFMG_thermal_util.get_entry_from_machine(machine)
    if not entry then return end
    if entry.paused == nil then entry.paused = false end
  return entry.paused end

  ---@param machine LuaEntity|uint64 #can use unit number or a LuaEntity
  function TFMG_thermal_util.toggle_interface_pause(machine)
    local entry = TFMG_thermal_util.get_entry_from_machine(machine)
    if not entry then return end
    if entry.paused == nil then entry.paused = false end
    entry.paused = not entry.paused
  return entry.paused end


return TFMG_thermal_util