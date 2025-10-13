local flib_table = require("__flib__/table")

local thermal_system_core = {}
--Compound entity handlers
  function thermal_system_core.handle_build_event(event,entity,temperature) -- create machines create machines create machines create machines create machines create machines create machines create
    local machine = entity or event.entity
    local direction = machine.direction/4+1
    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine)
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
  	local interface = machine.surface.create_entity({name = machine.name .. "-thermal-interface"..direction,position = machine.position, force = machine.force })
  	interface.disabled_by_script = true
  	interface.temperature = temperature or thermal_prototype.default_temperature
  	interface.destructible = false
  	table.insert(storage.interfaces[machine.name], unit_number, { machine = machine, interface = interface })
    if storage.registered_entities == nil then
      storage.registered_entities = {}
    end
    table.insert(storage.registered_entities,_reg_number,machine.name)--we need this to be able to recall information about the machine when destorying it
  end
  
  function thermal_system_core.handle_rotate_event(event)
    machine = event.entity.name
    if storage.interfaces[event.entity.name] == nil then return end -- since we cant 
  	local v = storage.interfaces[event.entity.name][event.entity.unit_number]
  	local temperature = v.interface.temperature
  	v.interface.destroy()
  	storage.interfaces[event.entity.name][event.entity.unit_number] = nil
  	thermal_system_core.handle_build_event(nil,v.machine,temperature)
  end

  function thermal_system_core.handle_destroy_event(event)
    local machine = storage.registered_entities[event.registration_number]--recall what kind of machine we destroyed
    storage.registered_entities[event.registration_number] = nil --Clear the entry, as its irrelevant now
  	if storage.interfaces[machine][event.useful_id] ~= nil then
  		local entry = storage.interfaces[machine][event.useful_id]
  		entry.interface.destroy()
  		storage.interfaces[machine][event.useful_id] = nil
     end
  end

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

  local function thermal_update_category(type,table)--Update a whole category
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..type].data
    local base_temperature_increase_per_tick = thermal_prototype.base_temperature_increase_per_tick --Precalculation rules.
    local max_working_temp = thermal_prototype.max_working_temperature
    local max_safe_temp = thermal_prototype.max_safe_temperature

    local update_budget = 1 -- define how many machines to update, per category
    local delta_time = 1
    local delta = table_size(table)/update_budget
    if delta > 1 then--if update budget is bigger than table size, you will get a delta time of 1, but if table size is larger than budget, then delta time increases.
      delta_time = delta
    end
    storage.table_index[type] = flib_table.for_n_of(
      table,storage.table_index[type], update_budget,
      function(v)
        thermal_system_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)
      end
    )
  end

  function thermal_system_core.thermal_update()
    for type , table in pairs(storage.interfaces) do
      thermal_update_category(type,table)
    end
  end

return thermal_system_core