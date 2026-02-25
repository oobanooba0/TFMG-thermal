local TFMG_thermal_compound = {}
local bplib = require("__bplib__.blueprint")
local BlueprintBuild = bplib.BlueprintBuild
local BlueprintSetup = bplib.BlueprintSetup

---basic build events
  function TFMG_thermal_compound.handle_build_event(event)
    local machine = event.entity
    if not machine.valid then game.print("tried to build invalid machine") return end

    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
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

    local _reg_number, unit_number, _type = script.register_on_object_destroyed(machine)

    interface.disabled_by_script = true
    interface.destructible = false
    interface.rotatable = false

    storage.interfaces[machine.name][unit_number] = {
      machine = machine,
      interface = interface,
      --direction = machine.direction, --storing our orientation and mirroring.
      --mirroring = machine.mirroring,
    }
    storage.registered_entities[unit_number] = machine.name--we use this so we can know what interface table the entity belongs to when we destroy it, since we can't get this info from a destoryed entity
  end

  function TFMG_thermal_compound.handle_destroy_event(event)
    local prebuild_data = storage.prebuild_data[event.registration_number]
    if prebuild_data then
      TFMG_thermal_compound.apply_smuggled_bp_data(prebuild_data)
    elseif storage.registered_entities then
      TFMG_thermal_compound.destory_compound_entity(event)
    return end
  end

  function TFMG_thermal_compound.apply_smuggled_bp_data(prebuild_data)
    game.print(serpent.block(prebuild_data))
    local surface = prebuild_data.surface
    local entity_name = prebuild_data.entity
    local position = prebuild_data.position
    local interface = surface.find_entity(entity_name.."-thermal-interface",position)

    if interface then
      interface.direction = prebuild_data.bp_rotation.direction
      interface.mirroring = prebuild_data.bp_rotation.mirroring
    end
    game.print(serpent.block(entity))

  end

  function TFMG_thermal_compound.destory_compound_entity(event) --destory a compound entity
    local unit_number = event.useful_id
    local machine_name = storage.registered_entities[unit_number]--recall what kind of machine we destroyed
    if machine_name and storage.interfaces[machine_name] and storage.interfaces[machine_name][unit_number] then
  		local v = storage.interfaces[machine_name][unit_number]
  		if v.interface.destroy() == true then
  		  storage.interfaces[machine_name][unit_number] = nil
        storage.registered_entities[unit_number] = nil --Clear the entry, as its irrelevant now
        --game.print("deconstruction"..unit_number)
      else
        game.print("destruction failed")
      end
    else game.print("no storage entry here")
    end
  end

--blueprint events

--blueprint setup
  function TFMG_thermal_compound.bp_setup(event)
    --I dont fully understand bplib, but it is what it is.
    local bp_setup = BlueprintSetup:new(event)
  	if not bp_setup then return end

  	-- Get a map from blueprint indices to world entities.
  	local map = bp_setup:map_blueprint_indices_to_world_entities()
  	if not map then return end

    -- Check for any entities matching your custom entity
  	for bp_index, machine in pairs(map) do
      local interface_prototype --for every entity in the blueprint, we'll check if we have a thermal prototype associated with it.
      --since the blueprint source entities may be ghosts, we need to account for that
      if machine.name == "entity-ghost" then
        interface_prototype = prototypes.mod_data["TFMG-thermal-"..machine.ghost_name]
      else
        interface_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name]
      end
      --if we have an interface prototype, then we have work to do.
      if interface_prototype and storage.interfaces[machine.name] then
        --check if we have a storage entry for this entity (this implicitly checks surface conditions.)
        local v = storage.interfaces[machine.name][machine.unit_number]
        if v then --if we so have an interface here, we can use it.
  			  bp_setup:apply_tags(bp_index, {
            TFMG = { direction = v.interface.direction, mirroring = v.interface.mirroring }
          })
        else --Without an interface entry, we dont have an interface to source from. so we'll need to get more creative.
          --for now, we'll try nothing.
        end
  		end
  	end
  end

  ---@param bp_entity BlueprintEntity
  local function blueprint_entity_filter(bp_entity)
    local bp_entity_name = bp_entity.name
    if not prototypes.mod_data["TFMG-thermal-"..bp_entity_name] then return false end --Check if we have a thermal system mod data entry corresponding to the entity, if not, our script can ignore this.
    if prototypes.mod_data["TFMG-thermal-"..bp_entity_name].data.rotation_ruleset == "_01" then return false end --we dont need to do any blueprint stuff if our building shouldnt rotate.
    return true
  end

  --this should largely deal with entities that cant adopt their rotaiton from their parent entity. like beacons.
  local function blueprint_place_tag_handler(bp_entity,bp_transforms,bp_location,surface)
    local rotation_ruleset = prototypes.mod_data["TFMG-thermal-"..bp_entity.name].data.rotation_ruleset
    --we're gonna get our orientation, so we can apply our silly little rotation rules
    local tag_orientation = TFMG_thermal_util.direction_to_orientation[bp_entity.tags.TFMG.direction][bp_entity.tags.TFMG.mirroring]
    --make appropriate rotation changes to the tags based on the blueprint.
    --this could probably be much more efficient, and i have big questions.
    for i = 2 , (bp_transforms.bp_rotation/4+1) do --this feels like a mistake, I hope to find it.
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["rotate"][tag_orientation]
    end
    if bp_transforms.bp_flip_horizontal then
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["flip_horizontal"][tag_orientation]
    end
    if bp_transforms.bp_flip_vertical then
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["flip_horizontal"][tag_orientation]
    end
    --convert tag orientaiton backinto direction and orientation
    local new_direction = TFMG_thermal_util.orientation_to_direction[tag_orientation]

    TFMG_thermal_util.subtick_trigger_abuse({--we're creating an entity, destorying it and using its destroy event trigger to get some other code to run at the end of the tick.
      surface = surface,
      position = bp_location,
      bp_rotation = new_direction,
      entity = bp_entity.name,
    })
  end

  --this should apply to situations where you're pasting over thermal entities.
  local function blueprint_overbuild_handler()

  end

  --if you're copy pasting from surfaces that dont have thermal entities, to ones that do. Don't do that.

--blueprint placement events
  function TFMG_thermal_compound.on_pre_build(event)
    local bp_build = BlueprintBuild:new(event)
    -- Will be `nil` if the event was not a blueprint build.
  	if not bp_build then return end

    local bp_entities = bp_build:get_entities() --[[@as BlueprintEntity[] ]]
    if not bp_entities then return end --if a blueprint has no entities, then we should quit here.
    local bp_locations = bp_build:map_blueprint_indices_to_world_positions()

    local bp_transforms = {
      bp_rotation = event.direction,
      horizbp_flip_horizontalontal = event.flip_horizontal,
      bp_flip_vertical = event.flip_vertical,
    }
    --game.print(bp_rotation..tostring(bp_flip_horizontal)..tostring(bp_flip_vertical))

    for bp_index, bp_entity in pairs(bp_entities) do
      if blueprint_entity_filter(bp_entity) and bp_entity.tags and bp_entity.tags.TFMG then
        local bp_location = bp_locations[bp_index]
        blueprint_place_tag_handler(bp_entity,bp_transforms,bp_location,bp_build.surface)
      end
    end

  	-- Get entities in the blueprint that (1) match your custom entity and
  	-- (2) are being placed over existing entities.
  	local overlap_map = bp_build:map_blueprint_indices_to_overlapping_entities(blueprint_entity_filter)
  
  	if not overlap_map or (not next(overlap_map)) then return end
  	-- Map blueprint tags on to the entities

  	for bp_index, entity in pairs(overlap_map) do
  		local tags = bp_entities[bp_index].tags or {}
  		blueprint_overbuild_handler(tags, entity)
  	end
  end


  function TFMG_thermal_compound.post_build(event)


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