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

function TFMG_thermal_core.surface_condition_compare(surface,conditions)--conditions should be as table
  if conditions == nil then return true end
    for _ , condition in pairs(conditions) do
      local surface_condition_value = surface.get_property(prototypes.surface_property[condition.property])
      if condition.min > surface_condition_value or surface_condition_value > condition.max then return false end
    end
  return true end

--Compound entity handlers
  function TFMG_thermal_core.handle_build_event(event,entity,direction,temperature) -- create machines create machines create machines create machines create machines create machines create machines create
    --gather important data
    local machine = entity or event.entity
    if machine.valid == false then return game.print("tried to build invalid machine")  end
    
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
    --game.print(serpent.block(thermal_prototype))
    local surface = machine.surface
    local bp_proxy = surface.find_entity("TFMG-thermal-bp-proxy",machine.position)
    if bp_proxy then
        direction = (math.floor(bp_proxy.color.r*255))
      bp_proxy.destroy()
    end
    --get direction information
    if direction == nil then --if no direction information is provided
      if event and event.tags and event.tags.thermal_direction then
        direction = event.tags.thermal_direction
      else
        direction = machine.direction/4+1
        if machine.mirroring == true then direction = direction + 4 end
      end
    end
    --if event.tags and event.tags.thermal_direction then game.print(event.tags.thermal_direction) else game.print("no tags on this entity") end --check if tags are coming though
    --Deal with surface conditions
    local interface_prototype = prototypes.entity[machine.name .. "-thermal-interface"..direction]
    local conditions = interface_prototype.surface_conditions
    if TFMG_thermal_core.surface_condition_compare(surface,conditions) == false then return end --You shall not pass
   

  	local interface = machine.surface.create_entity({name = machine.name .. "-thermal-interface"..direction,position = machine.position, force = machine.force })
    if interface == nil then return game.print("entity wasnt created") end
    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine) --register destruction event
  	interface.disabled_by_script = true
    local temperature = temperature or thermal_prototype.default_temperature
  	interface.temperature = temperature
  	interface.destructible = false
    --Store the entity in its table.
  	storage.interfaces[machine.name][unit_number] = { machine = machine, interface = interface, direction = direction}
    storage.registered_entities[unit_number] = machine.name--we need this to be able to recall information about the machine when destorying it
  end

  function TFMG_thermal_core.handle_destroy_event(event)
    if not storage.registered_entities then return end
    local unit_number = event.useful_id
    local machine = storage.registered_entities[unit_number]--recall what kind of machine we destroyed
    if not machine then return game.print("machine was nil"..unit_number) end
  	if storage.interfaces[machine] and storage.interfaces[machine][unit_number] then
  		local v = storage.interfaces[machine][unit_number]
  		if v.interface.destroy() == true then
        --something something undo tags?
  		  storage.interfaces[machine][unit_number] = nil
        storage.registered_entities[unit_number] = nil --Clear the entry, as its irrelevant now
      else game.print("destruction failed")
      end
    else game.print("no storage entry here")
    end
  end

  function TFMG_thermal_core.handle_ghost_deconstruction_event(event)
    local ghost = event.ghost
    local bp_proxy = ghost.surface.find_entity("TFMG-thermal-bp-proxy",ghost.position)
    if bp_proxy then
      direction = (math.floor(bp_proxy.color.r*255))
      bp_proxy.destroy()
    end
  end

  function TFMG_thermal_core.handle_bp_proxy_build_event(event)
    TFMG_thermal_core.schedule_event(event.tick+1,"bp_proxy",event)
    --game.print("bpproxyexistend")
  end

  function TFMG_thermal_core.handle_bp_proxy(event)
    --game.print(serpent.block(event))
    local bp_proxy = event.entity
    if not event.entity.valid then return end
    local ghost = bp_proxy.surface.find_entities_filtered{position = bp_proxy.position,type = "entity-ghost",limit = 1}[1]
    --if not ghost then game.print("no ghost") else game.print(serpent.line(ghost.position)..serpent.line(bp_proxy.position)) end
    if not ghost or ghost.position["x"] ~= bp_proxy.position["x"] or ghost.position["y"] ~= bp_proxy.position["y"]  then
      bp_proxy.destroy()
    else
      TFMG_thermal_core.schedule_event(game.tick+100,"bp_proxy",event)
    end
  end

--new experemental rotation events

  local function get_entry_from_input_event(event)
    if not event.selected_prototype or storage.interfaces[event.selected_prototype.name] == nil then return end
    local interface_table = storage.interfaces[event.selected_prototype.name]
    local machine_prototype = event.selected_prototype
    local player = game.players[event.player_index]
    local surface = player.character and player.character.surface or player.surface
    local machine = surface.find_entity(machine_prototype.name,event.cursor_position)
    if machine == nil then return end
    local v = interface_table[machine.unit_number]
  return v,machine end

  function TFMG_thermal_core.handle_transform(event,transform) --Deals with getting a new direction based on the machines rotation rules and such.
    local v,machine = get_entry_from_input_event(event)
    if v == nil then return end
    local rotation_ruleset = prototypes.mod_data["TFMG-thermal-"..event.selected_prototype.name].data.rotation_ruleset_world
    if rotation_ruleset == "_01" then return end --dont rotate if not rotatable.
    if ruleset_lookup[rotation_ruleset] == nil then return game.print("ruleset "..rotation_ruleset.." does not exist.") end
    local new_direction = ruleset_lookup[rotation_ruleset][transform][v.direction] -- look up the new rotation from the table.
    if new_direction == nil then return game.print("no new direction found") end
    --game.print(v.direction..transform..new_direction) --debug to help show direction changes

    --now setup the destruction
    local temperature = v.interface.temperature
    v.interface.destroy()
    --rebuild the entity
  	TFMG_thermal_core.handle_build_event(nil,v.machine,new_direction,temperature)
  end

--blueprint handlers
  --blueprint setup
  script.on_event(defines.events.on_player_setup_blueprint, function(event)
  	-- Create the temporary setup object that allows manipulation via bplib
  	local bp_setup = BlueprintSetup:new(event)
  	if not bp_setup then return end

  	-- Get a map from blueprint indices to world entities.
  	local map = bp_setup:map_blueprint_indices_to_world_entities()
  	if not map then return end

  	-- Check for any entities matching your custom entity
  	for bp_index, machine in pairs(map) do
      local interface_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name] --for every entity in the blueprint,   we'll check if we have a thermal prototype associated with it
      if interface_prototype and storage.interfaces[machine.name] then
  			-- Calculate your custom tags here based on information about your
  			-- entity.
        local v = storage.interfaces[machine.name][machine.unit_number]
        if v then
  			  bp_setup:apply_tags(bp_index, { thermal_direction = v.direction })
        end
  		end
  	end
  end)

--blueprint place
  ---@param bp_entity BlueprintEntity
  local function blueprint_entity_filter(bp_entity)
    local bp_entity_name = bp_entity.name
    if not prototypes.mod_data["TFMG-thermal-"..bp_entity_name] then return false end --Check if we have a thermal system mod data entry corresponding to the entity, if not, our script can ignore this.
    if prototypes.mod_data["TFMG-thermal-"..bp_entity_name].data.rotation_ruleset == "_01" then return false end --we dont need to do any blueprint stuff if our building isnt rotatable.
    return true
  end

  ---@param tags Tags
  ---@param machine LuaEntity
  local function apply_blueprint_tags_replace(tags, machine) --handles pasting from blueprint onto existing entities
    if storage.interfaces[machine.name] and storage.interfaces[machine.name][machine.unit_number] then
    local v = storage.interfaces[machine.name][machine.unit_number]
    if not v.interface.valid then return end
    local new_direction = tags.thermal_direction
    --now setup the destruction
    local temperature = v.interface.temperature
    v.interface.destroy()
    --rebuild the entity
    if machine.surface.can_place_entity{name = "entity-ghost", inner_name=machine.name,position = machine.position, directon = machine.direction, force = "player", build_check_type = defines.build_check_type.script_ghost, forced = true} then --we check if we could place the parent entity here
      machine.surface.create_entity({name="TFMG-thermal-bp-proxy", snap_to_grid = true, position = machine.position,color = {r = new_direction,g = 0,b = 0, a = 255},force = "player",raise_built = true})--if i must pack data into colour, so be it
    end
  	TFMG_thermal_core.handle_build_event(nil,v.machine,new_direction,temperature)
    --game.print("applied-tags")
    end
  end

  local function apply_place_rotation(event,bp_entities,bp_locations,surface)--apply a rotation to the entities in the blueprint according to their rotation rules.
    local rotation = event.direction/4+1
    local flip_horizontal = event.flip_horizontal
    local flip_vertical = event.flip_vertical
    --game.print(rotation..tostring(flip_horizontal)..tostring(flip_vertical))
    for bp_index, bp_entity in pairs(bp_entities) do
      if blueprint_entity_filter(bp_entity) and bp_entity.tags and bp_entity.tags.thermal_direction then --only if we have tags in there already.
          if prototypes.mod_data["TFMG-thermal-"..bp_entity.name] then
          local rotation_ruleset = prototypes.mod_data["TFMG-thermal-"..bp_entity.name].data.rotation_ruleset
          if ruleset_lookup[rotation_ruleset] == nil then return game.print("ruleset "..rotation_ruleset.." does not exist.") end
          local tag_rotation = bp_entity.tags.thermal_direction
          for i = 2 , rotation do
            tag_rotation = ruleset_lookup[rotation_ruleset]["rotate"][tag_rotation]
          end
          if flip_horizontal == true then tag_rotation = ruleset_lookup[rotation_ruleset]["flip_horizontal"][tag_rotation]  end
          if flip_vertical == true then tag_rotation = ruleset_lookup[rotation_ruleset]["flip_vertical"][tag_rotation] end
          
          bp_entity.tags.thermal_direction = tag_rotation
          
          local bp_location = bp_locations[bp_index]
          direction_check = ((tag_rotation-1) * 4)
          if direction_check > 16 then direction_check = direction_check - 16 end
          if surface.can_place_entity{name = "entity-ghost", inner_name=bp_entity.name,position = {bp_location[1],bp_location[2]}, directon = direction_check, force = "player", build_check_type = defines.build_check_type.script_ghost, forced = true} then --we check if we could place the parent entity here
            surface.create_entity({name="TFMG-thermal-bp-proxy", snap_to_grid = true, position = bp_location,color = {r = tag_rotation,g = 0,b = 0, a = 255},force = "player",raise_built = true})--if i must pack data into colour, so be it
          end
        end
      end
    end
  end
  -- When a blueprint containing your custom entity is stamped down over an
  -- existing entity, use the tags stored in the blueprint to update your
  -- entity's state.
  script.on_event(defines.events.on_pre_build, function(event)
  	local bp_build = BlueprintBuild:new(event)
  	-- Will be `nil` if the event was not a blueprint build.
  	if not bp_build then return end

    local bp_entities = bp_build:get_entities() --[[@as BlueprintEntity[] ]]
    if not bp_entities then return end --if a blueprint has no entities, then we should quit here.
    local bp_locations = bp_build:map_blueprint_indices_to_world_positions()
    --game.print(serpent.block(bp_locations))
    apply_place_rotation(event,bp_entities,bp_locations,bp_build.surface)

  	-- Get entities in the blueprint that (1) match your custom entity and
  	-- (2) are being placed over existing entities.
  	local overlap_map = bp_build:map_blueprint_indices_to_overlapping_entities(
  		blueprint_entity_filter
  	)
  	if not overlap_map or (not next(overlap_map)) then return end
  	-- Map blueprint tags on to the entities
  
  	for bp_index, entity in pairs(overlap_map) do
  		local tags = bp_entities[bp_index].tags or {}
  		apply_blueprint_tags_replace(tags, entity)
  	end
  end)


--thermal system tick updates
  local function run_scheduled_events(tick)
    if not storage.tfmg_job_list[tick] then return end
    if storage.tfmg_job_list[tick].bp_proxy then
      for _ , event in pairs(storage.tfmg_job_list[tick].bp_proxy) do
        TFMG_thermal_core.handle_bp_proxy(event)
      end
    end
    storage.tfmg_job_list[tick] = nil
  end

  function TFMG_thermal_core.schedule_event(tick,type,data) --schedule an event to be run
    if not storage.tfmg_job_list[tick] then
      storage.tfmg_job_list[tick] = {}
    end
    if not storage.tfmg_job_list[tick][type] then
      storage.tfmg_job_list[tick][type] = {}
    end
    table.insert(storage.tfmg_job_list[tick][type],data)
  end

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

  function TFMG_thermal_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)--Update an individual machine
    if v.machine.valid == false then return end --If the machine isnt valid, don't run the script.
    if v.interface.valid == false then return end
		local temperature = v.interface.temperature
		if v.machine.status == 1 or v.machine.status == 14 then --if the machine is working, heat it up.
			v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*(1 + v.machine.consumption_bonus))--This is the equation of doom. this is 90% of this mods performance cost.
		end
		machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)
  end

  function TFMG_thermal_core.thermal_update_machine_passive(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)--This script is for machines that produce heat from passive draw.
    if v.machine.valid == false then return end --If the machine isnt valid, don't run the script.
    if v.interface.valid == false then return end
		local temperature = v.interface.temperature
		if v.machine.status == 1 or v.machine.status == 14 then --if the machine is working (or low power), heat it up.
			v.interface.temperature = temperature + (delta_time*base_temperature_increase_per_tick*(1 + v.machine.consumption_bonus))--This is the equation of doom. this is 90% of this mods performance cost.
		end
		machine_status_control(v,temperature,max_safe_temp,max_working_temp,delta_time)
  end

  function TFMG_thermal_core.thermal_update_thruster(v,temperature_increase_per_unit_fuel,max_working_temp,max_safe_temp,delta_time,fluid_1_type,fluid_2_type,fluid_1_min,fluid_2_min,fluid_1_max,fluid_2_max,min_consumption,max_consumption)
    if v.machine.valid == false then return end --If the machine isnt valid, don't run the script.
    if v.interface.valid == false then return end
    --game.print(serpent.block(v.machine.min_performance))
		local temperature = v.interface.temperature
		if v.machine.status == 1 or v.machine.status == 14 then --if the machine is working, heat it up.
      --game.print(serpent.block(v.machine.quality.default_multiplier))
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
      storage.table_index[type] = flib_table.for_n_of(
        table,storage.table_index[type], update_budget,
        function(v)
          local base_temperature_increase_per_tick = thermal_prototype.base_temperature_increase_per_tick --Precalculation rules.
          TFMG_thermal_core.thermal_update_machine(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)
        end
      )
    elseif thermal_prototype.type == "crafting-machine-passive" then
      storage.table_index[type] = flib_table.for_n_of(
        table,storage.table_index[type], update_budget,
        function(v)
          local base_temperature_increase_per_tick = thermal_prototype.base_temperature_increase_per_tick --Precalculation rules.
          TFMG_thermal_core.thermal_update_machine_passive(v,base_temperature_increase_per_tick,max_working_temp,max_safe_temp,delta_time)
        end
      )
    elseif thermal_prototype.type == "thruster" then
      storage.table_index[type] = flib_table.for_n_of(
        table,storage.table_index[type], update_budget,
        function(v)
          local temperature_increase_per_unit_fuel = thermal_prototype.temperature_increase_per_unit_fuel
          local fluid_1_type = thermal_prototype.fluid_1_type
          local fluid_2_type = thermal_prototype.fluid_2_type
          local fluid_1_min = thermal_prototype.fluid_1_min
          local fluid_2_min = thermal_prototype.fluid_2_min
          local fluid_1_max = thermal_prototype.fluid_1_max
          local fluid_2_max = thermal_prototype.fluid_2_max
          local min_consumption = thermal_prototype.min_consumption
          local max_consumption = thermal_prototype.max_consumption
          TFMG_thermal_core.thermal_update_thruster(v,temperature_increase_per_unit_fuel,max_working_temp,max_safe_temp,delta_time,fluid_1_type,fluid_2_type,fluid_1_min,fluid_2_min,fluid_1_max,fluid_2_max,min_consumption,max_consumption)
        end
      )
    end
  end

  function TFMG_thermal_core.thermal_update(event)
    local tick = event.tick
      run_scheduled_events(tick)
    local registered_entities_size = table_size(storage.registered_entities)
    for type , table in pairs(storage.interfaces) do
      thermal_update_category(type,table,registered_entities_size)
    end
    --game.print(registered_entities_size)
    --game.print(serpent.block(storage.registered_entities))
  end

return TFMG_thermal_core