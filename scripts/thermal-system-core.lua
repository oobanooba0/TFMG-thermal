--this file contains the major components of the runtime scripting of TFMG Thermal. You should not have to interact with this in any way, though the functions can be called on the off chance they are useful to you.
local bplib = require("__bplib__.blueprint")
local BlueprintBuild = bplib.BlueprintBuild
local BlueprintSetup = bplib.BlueprintSetup
local flib_table = require("__flib__/table")
 
--rotation ruleset lookup table
  --R = Rotatable
  --r = rotatable, only in hand
  --F = flippable,
  --f = flippable only in hand
  --08 = 8 unique directions

  --we index each sequence of orientations by initial orientation, to next orientation.

  ruleset_lookup = {
    RF_08 = {
      rotate = {2,3,4,1,6,7,8,5},
      rotate_reverse = {4,1,2,3,8,5,6,7},
      flip_horizontal = {5,8,7,6,1,4,3,2},
      flip_vertical = {7,6,5,8,3,2,1,4},
    },
    RF_04 = {--that means it is flippable, but flips are just 2 rotations --double check the correctness of this
      rotate = {2,3,4,1},
      rotate_reverse = {4,1,2,3},
      flip_horizontal = {3,4,1,2},
      flip_vertical = {3,4,1,2},
    }
  }



local thermal_system_core = {}

function thermal_system_core.surface_condition_compare(surface,conditions)--conditions should be as table
  if conditions == nil then return true end
    for _ , condition in pairs(conditions) do
      local surface_condition_value = surface.get_property(prototypes.surface_property[condition.property])
      if condition.min > surface_condition_value or surface_condition_value > condition.max then return false end
    end
  return true end

--Compound entity handlers
  function thermal_system_core.handle_build_event(event,entity,direction,temperature) -- create machines create machines create machines create machines create machines create machines create machines create
    --gather important data
    local machine = entity or event.entity
    --get direction information
    if direction == nil then --if no direction information is provided, we're gonna take it from the parent
     direction = machine.direction/4+1
      if machine.mirroring == true then direction = direction + 4 end
    end
    local surface = machine.surface
    --Deal with surface conditions
    local interface_prototype = prototypes.entity[machine.name .. "-thermal-interface"..direction]
    local conditions = interface_prototype.surface_conditions
    --deal with rotation ruleset
    local rotation_ruleset = "RF_08"

    if thermal_system_core.surface_condition_compare(surface,conditions) == false then return end --You shall not pass
   
    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine) --register destruction event
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
  	local interface = machine.surface.create_entity({name = machine.name .. "-thermal-interface"..direction,position = machine.position, force = machine.force })
  	interface.disabled_by_script = true
    local temperature = temperature or thermal_prototype.default_temperature
  	interface.temperature = temperature
  	interface.destructible = false
    --Store the entity in its table.
  	table.insert(storage.interfaces[machine.name], unit_number, { machine = machine, interface = interface, direction = direction, ruleset = rotation_ruleset})
    table.insert(storage.registered_entities,_reg_number,machine.name)--we need this to be able to recall information about the machine when destorying it
  end
  
  function thermal_system_core.handle_rotate_event(event)
    machine = event.entity
    if storage.interfaces[machine.name] == nil then return end -- since we cant 
  	local v = storage.interfaces[machine][machine.unit_number]
  	local temperature = v.interface.temperature
  	v.interface.destroy()
  	storage.interfaces[machine.name][machine.unit_number] = nil
  	thermal_system_core.handle_build_event(nil,v.machine,temperature)
  end

  function thermal_system_core.handle_destroy_event(event)
    if storage.registered_entities == nil then return end
    local machine = storage.registered_entities[event.registration_number]--recall what kind of machine we destroyed
    if machine == nil then return end
    storage.registered_entities[event.registration_number] = nil --Clear the entry, as its irrelevant now
  	if storage.interfaces[machine][event.useful_id] ~= nil then
  		local entry = storage.interfaces[machine][event.useful_id]
  		entry.interface.destroy()
  		storage.interfaces[machine][event.useful_id] = nil
     end
  end

--new experemental rotation events

  local function get_entry_from_input_event(event)
    local interface_table = storage.interfaces[event.selected_prototype.name]
    if not event.selected_prototype or interface_table == nil then return end
    local machine_prototype = event.selected_prototype
    local player = game.players[event.player_index]
    local surface = player.character and player.character.surface or player.surface
    local machine = surface.find_entity(machine_prototype.name,event.cursor_position)
    if machine == nil then return end
    local v = interface_table[machine.unit_number]
  return v,machine end

  function thermal_system_core.handle_transform(event,transform)
    local v,machine = get_entry_from_input_event(event)
    if v == nil then return end
    local rotation_ruleset = v.ruleset
    local new_direction = ruleset_lookup[rotation_ruleset][transform][v.direction] -- look up the new rotation from the table.
    if new_direction == nil then return game.print("no new direction found") end
    game.print(v.direction..transform..new_direction)

    --now setup the destruction
    local temperature = v.interface.temperature
    v.interface.destroy()
  	storage.interfaces[machine.name][machine.unit_number] = nil
    --rebuild the entity
  	thermal_system_core.handle_build_event(nil,v.machine,new_direction,temperature)
  end
--thermal system tick updates

  function thermal_system_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)--Update an individual machine
    if v.machine.valid == false then return end --If the machine isnt valid, don't run the script.
		local temperature = v.interface.temperature
		if v.machine.status == 1 then --if the machine is working, heat it up.
			v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*(1 + v.machine.consumption_bonus))--This is the equation of doom. this is 90% of this mods performance cost.
		end
		if temperature >= max_safe_temp then--KILL KILL KILL KILL
			v.machine.disabled_by_script = true
			v.machine.custom_status = {
				diode = defines.entity_status_diode.red,
				label = "Taking thermal damage!"
			}
			v.machine.damage(0.1*delta_time,"neutral")--must be last part of the script that runs, since after this point, the machine may no longer exist.
		elseif temperature >= max_working_temp then
			v.machine.disabled_by_script = true
			v.machine.custom_status = {
				diode = defines.entity_status_diode.red,
				label = "Overheated!"
			}
		else -- if its not overheating, we can happily let it run :)
			v.machine.disabled_by_script = false
			v.machine.custom_status = nil
		end
  end

  local function thermal_update_category(type,table,registered_entities_size)--Update a whole category
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..type].data
    local base_temperature_increase_per_tick = thermal_prototype.base_temperature_increase_per_tick --Precalculation rules.
    local max_working_temp = thermal_prototype.max_working_temperature
    local max_safe_temp = thermal_prototype.max_safe_temperature
    local category_size = table_size(table)
    local update_budget = settings.global["update-quota"].value*(category_size/registered_entities_size)
    local delta_time = category_size/update_budget
    if delta_time < 1 then--if update budget is bigger than table size, you will get a delta time of 1, but if table size is larger than budget, then delta time increases.
      delta_time = 1
    end
    --game.print("TFMG-thermal-"..type..":"..update_budget.." "..delta_time) -- update distribution debug checker
    storage.table_index[type] = flib_table.for_n_of(
      table,storage.table_index[type], update_budget,
      function(v)
        thermal_system_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)
      end
    )
  end

  function thermal_system_core.thermal_update()
    local registered_entities_size = table_size(storage.registered_entities)
    for type , table in pairs(storage.interfaces) do
      thermal_update_category(type,table,registered_entities_size)
    end
  end

return thermal_system_core