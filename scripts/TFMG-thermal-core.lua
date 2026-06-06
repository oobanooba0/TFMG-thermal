--this file contains the major components of the runtime scripting of TFMG Thermal. You should not have to interact with this in any way, though the functions can be called on the off chance they are useful to you.
local bplib = require("__bplib__.blueprint")
local BlueprintBuild = bplib.BlueprintBuild
local BlueprintSetup = bplib.BlueprintSetup
local flib_table = require("__flib__/table")

--rotation ruleset lookup table
  --R = Rotatable
  --r = Rotatable, but 180 degrees.
  --F = flippable,
  --08 = 8 unique variations
  --00 = 1 unique directions

  --we index each sequence of orientations by initial orientation, to next orientation.

  ruleset_lookup = {--ruleset transform current_rotation
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


local TFMG_thermal_core = {}
---
  local function machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)--handle the enable,disable and status setting of a machine.
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

  function TFMG_thermal_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time,base_buffer_size)--Update an individual machine
    if not v.machine.valid  then return end --If the machine isnt valid, don't run the script.
    if not v.interface.valid then return end
    if v.paused then return end

		local temperature = v.interface.temperature
		if v.machine.status == 1 then --if the machine is working, heat it up.
			v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*(1 + v.machine.consumption_bonus))--This is the equation of doom. this is 90% of this mods performance cost.
    elseif v.machine.status == 14 then --when on low power, we need to know at what fraction of optimal we're running, this is more complex, so we only do this if our machine is in low power status.
      local energy_multiplier = (1 + v.machine.consumption_bonus)
      local power_level = v.machine.energy/(base_buffer_size*energy_multiplier)
      v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*energy_multiplier*power_level)
    end
		machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)
  end

  function TFMG_thermal_core.thermal_update_machine_disabled_heat(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time,base_buffer_size)--This version of the script should still produce heat when machines are disabled by script.
    if not v.machine.valid  then return end --If the machine isnt valid, don't run the script.
    if not v.interface.valid then return end
    if v.paused then return end

    v.machine.disabled_by_script = false --We have to enable the machine to read its real status.

		local temperature = v.interface.temperature
    if max_working_temp >= temperature then -- we need to check if this machine isnt overheated, since the no heat if its not working assumption no longer applies here.
		  if v.machine.status == 1 then --if the machine is working, heat it up.
		  	v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*(1 + v.machine.consumption_bonus))--This is the equation of doom. this is 90% of this mods performance cost.
      elseif v.machine.status == 14 then --when on low power, we need to know at what fraction of optimal we're running, this is more complex, so we only do this if our machine is in low power status.
        local energy_multiplier = (1 + v.machine.consumption_bonus)
        local power_level = v.machine.energy/(base_buffer_size*energy_multiplier)
        v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*energy_multiplier*power_level)
      end
    end
		machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)
  end

  function TFMG_thermal_core.thermal_update_thruster(v,temperature_increase_per_unit_fuel,max_working_temp,max_safe_temp,delta_time,fluid_1_type,fluid_2_type,fluid_1_min,fluid_2_min,fluid_1_max,fluid_2_max,min_consumption,max_consumption)
    --thruster script, is more complex because our heat production is based off the fuel burned. since thrusters dont consume energy like other machines.
    if not v.machine.valid  then return end --If the machine isnt valid, don't run the script.
    if not v.interface.valid then return end
    if v.paused then return end

		local temperature = v.interface.temperature
		if v.machine.status == 1 then --if the machine is working, heat it up.
      local quality_multiplier = v.machine.quality.default_multiplier
      local consumption = max_consumption
      do
        local fluid1 = v.machine.get_fluid_count(fluid_1_type)
        local fluid2 = v.machine.get_fluid_count(fluid_2_type)
        if fluid1 >= fluid_1_max and fluid2 >= fluid_2_max then goto heat end--if both are at max, then we just spit out max consumption. between these two pre checks we should ideally, get reasonably performant code
        if fluid1 <= fluid_1_min then consumption = min_consumption goto heat end --if either fluid is below its minimum then consumption is gonna be its lowest possible value
        if fluid2 <= fluid_2_min then consumption = min_consumption goto heat end
        local fluid1_scale = (fluid1 - fluid_1_min)/(fluid_1_max - fluid_1_min)
        local fluid2_scale = (fluid2 - fluid_2_min)/(fluid_2_max - fluid_2_min)
        local scale = math.min(fluid1_scale,fluid2_scale)
        consumption = scale*(max_consumption-min_consumption) + min_consumption
      end
      ::heat::
      --game.print(consumption*quality_multiplier,{skip = defines.print_skip.never})
			v.interface.temperature = temperature + (delta_time*consumption*temperature_increase_per_unit_fuel*quality_multiplier)--This is the equation of doom. this is 90% of this mods performance cost.
		end
		machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)
  end

  local function thermal_update_category(type,table,registered_entities_size)--Update a whole category
    if not prototypes.mod_data["TFMG-thermal-"..type] then
      game.print("previously-existing-thermal-entity"..type.." no longer exists. Deleting related storage tables.") 
      storage.interfaces[type] = nil
      return end
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..type].data
    local max_working_temp = thermal_prototype.max_working_temperature
    local max_safe_temp = thermal_prototype.max_safe_temperature
    
    --game.print(category_size)
    local category_size = table_size(table)
    local update_budget = settings.global["update-quota"].value*(category_size/registered_entities_size)
    local delta_time = category_size/update_budget
    if delta_time < 1 then--if update budget is bigger than table size, you will get a delta time of 1, but if table size is larger than budget, then delta time increases.
      delta_time = 1
    end
    --game.print("TFMG-thermal-"..type..":"..update_budget.." "..delta_time) -- update distribution debug checker

    if thermal_prototype.type == "crafting-machine" then --We're gonna chose which thermal calculation function to use based on the machine type.
      --get these values only once, since they should remain the same across all instances of the machine.
      local base_temperature_increase_per_tick = thermal_prototype.base_temperature_increase_per_tick --Precalculation rules.
      local base_buffer_size = (prototypes.entity[thermal_prototype.name].get_max_energy_usage())*(64/60)
      if thermal_prototype.heat_when_disabled_by_script then --we run the same damn script but like, a tiny bit different
        storage.table_index[type] = flib_table.for_n_of(
        table,storage.table_index[type], update_budget,
        function(v)
          TFMG_thermal_core.thermal_update_machine_disabled_heat(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time,base_buffer_size)
        end
      )
      else
        storage.table_index[type] = flib_table.for_n_of(
          table,storage.table_index[type], update_budget,
          function(v)
            TFMG_thermal_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time,base_buffer_size)
          end
        )
      end
    elseif thermal_prototype.type == "thruster" then -- for thrusters, which need a wholly different thermal script.
      --get these values only once, since theyre reused for each instance of the thruster.
      local temperature_increase_per_unit_fuel = thermal_prototype.temperature_increase_per_unit_fuel
      local fluid_1_type = thermal_prototype.fluid_1_type
      local fluid_2_type = thermal_prototype.fluid_2_type
      local fluid_1_min = thermal_prototype.fluid_1_min
      local fluid_2_min = thermal_prototype.fluid_2_min
      local fluid_1_max = thermal_prototype.fluid_1_max
      local fluid_2_max = thermal_prototype.fluid_2_max
      local min_consumption = thermal_prototype.min_consumption
      local max_consumption = thermal_prototype.max_consumption
      storage.table_index[type] = flib_table.for_n_of(
        table,storage.table_index[type], update_budget,
        function(v)
          TFMG_thermal_core.thermal_update_thruster(v,temperature_increase_per_unit_fuel,max_working_temp,max_safe_temp,delta_time,fluid_1_type,fluid_2_type,fluid_1_min,fluid_2_min,fluid_1_max,fluid_2_max,min_consumption,max_consumption)
        end
      )
    else
      game.print("thermal prototype type "..thermal_prototype.type.." does not exist")
    end
  end

  function TFMG_thermal_core.thermal_update()
    local registered_entities_size = table_size(storage.registered_entities)
    for type , table in pairs(storage.interfaces) do
      thermal_update_category(type,table,registered_entities_size)
    end
    --game.print(registered_entities_size)
    --game.print(serpent.block(storage.registered_entities))
  end

return TFMG_thermal_core