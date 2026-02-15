local TFMG_thermal_compound = {}

  function TFMG_thermal_compound.handle_build_event(event)
    local machine = event.entity
    if not machine.vald then game.print("tried to build invalid machine") return end

    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data

    game.print(serpent.block(thermal_prototype))
    if not thermal_prototype then game.print("no thermal prototype data?") return end

    local surface = machine.surface
    local direction = machine.direction
    local position = machine.position
    --Some other additional information needed here, in the case that an entity that is not rotatable, needs to be placed
    --can i find a better method?
    --basically I want to redo direction management from scratch, which is why im ommitting all the code rn. (the old shit is a mess)

    ---surface condition check
    local conditions = thermal_prototype.surface_conditions
    if TFMG_thermal_util.surface_condition_compare(surface,conditions) == false then return end

    local interface = surface.create_entity({name = machine.name.."thermal-interface", direction = direction, position})
    game.print(serpent.block(interface))

    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine)
    
    interface.disabled_by_script = true


    --storage management here, double check its all sane



  end

return TFMG_thermal_compound