local TFMG_thermal_compound = {}

---basic build events
  function TFMG_thermal_compound.handle_build_event(event)
    local machine = event.entity
    if not machine.valid then game.print("tried to build invalid machine") return end

    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data

    game.print(serpent.block(thermal_prototype))
    if not thermal_prototype then game.print("no thermal prototype data?") return end

    local surface = machine.surface
    --Some other additional information needed here, in the case that an entity that is not rotatable, needs to be placed
    --can i find a better method?
    --basically I want to redo direction management from scratch, which is why im ommitting all the code rn. (the old shit is a mess)

    ---surface condition check
    local conditions = thermal_prototype.surface_conditions
    if TFMG_thermal_util.surface_condition_compare(surface,conditions) == false then return end

    local interface = surface.create_entity({
      name = machine.name.."-thermal-interface", 
      direction = machine.direction,
      position = machine.position,
      mirror = machine.mirroring,
    })
    --game.print(serpent.block(interface))

    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine)

    interface.disabled_by_script = true
    interface.destructible = false
    interface.rotatable = false

    storage.interfaces[machine.name][unit_number] = {machine = machine, interface = interface}--it looks like we probably will still need to save direction, but lets hold off on it now
    storage.registered_entities[unit_number] = machine.name--we use this so we can know what interface table the entity belongs to when we destroy it, since we can't get this info from a destoryed entity
  end

  function TFMG_thermal_compound.handle_destroy_event(event)
    if not storage.registered_entities then return end
    local unit_number = event.useful_id
    local machine_name = storage.registered_entities[unit_number]--recall what kind of machine we destroyed
    if machine_name and storage.interfaces[machine_name] and storage.interfaces[machine_name][unit_number] then
  		local v = storage.interfaces[machine_name][unit_number]
  		if v.interface.destroy() == true then
  		  storage.interfaces[machine_name][unit_number] = nil
        storage.registered_entities[unit_number] = nil --Clear the entry, as its irrelevant now
        game.print("deconstruction"..unit_number)
      else
        game.print("destruction failed")
      end
    else game.print("no storage entry here")
    end
  end

--rotation handlers
  function TFMG_thermal_compound.handle_transform(event,transform) --note that the input event occurs before the game actually does anything.
    local v = TFMG_thermal_util.get_entry_from_input_event(event)
    if not v then game.print("no interface entry found from input event") return end

    --gather rotation rules
    local rotation_ruleset = prototypes.mod_data["TFMG-thermal-"..event.selected_prototype.name].data.rotation_ruleset_world
    if rotation_ruleset == "_01" then return end --dont rotate if not rotatable.

    --apply rotation, generic method.
    TFMG_thermal_util.advanced_rotate(v.interface,transform,rotation_ruleset) --flawed in the sense that non rotatalbe entitys that can become rotatable can be broken
  end

return TFMG_thermal_compound