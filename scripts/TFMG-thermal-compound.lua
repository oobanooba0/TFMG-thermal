local bplib = require("__bplib__.blueprint")
local BlueprintBuild = bplib.BlueprintBuild
local BlueprintSetup = bplib.BlueprintSetup
local TFMG_thermal_compound = {}

---basic build events
  function TFMG_thermal_compound.handle_build_event(event)
    local machine = event.entity
    if not machine.valid then game.print("tried to build invalid machine") return end

    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
    if not thermal_prototype then game.print("no thermal prototype data?") return end

    local surface = machine.surface

    ---surface condition check
    local conditions = thermal_prototype.surface_conditions
    if TFMG_thermal_util.surface_condition_compare(surface,conditions) == false then return end

    --obtain the correct rotation information
    local interface_direction
    local interface_mirroring

    if event.tags then --I should double check if entity rotatableness has some sort of goofy impact
      --if we have ghost tags, that means we should use the rotation information encoded into that
      interface_direction = event.tags.direction
      interface_mirroring = event.tags.mirroring
    else
      --in all other situations, we adopt our direction from our parent machine.
      interface_direction = machine.direction
      interface_mirroring = machine.mirroring
    end

    local interface = surface.create_entity({
      name = machine.name.."-thermal-interface",
      position = machine.position,
      direction = interface_direction,
      mirror = interface_mirroring,
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
    --if our destroy event has a data smuggling entry related to it, then we should do that.
    --i forsee a potential problem where the event id coincidentally manages to match a unit number, and something wacky happens.
    local smuggled_data = storage.smuggled_data[event.registration_number]
    if smuggled_data then
      if smuggled_data.data_type == "blueprint" then
        TFMG_thermal_compound.apply_smuggled_bp_data(smuggled_data)
      elseif smuggled_data.data_type == "undo-stack" then
        TFMG_thermal_compound.tag_undo(smuggled_data)
      end
      --after any event using data smuggling, we should clear the storage. Ideally, nothing remains after the tick is over.
      storage.smuggled_data[event.registration_number] = nil
    return end
    --otherwise, take the compound entity destruction function.
    if storage.registered_entities then
      TFMG_thermal_compound.destory_compound_entity(event)
    return end
  end

  function TFMG_thermal_compound.destory_compound_entity(event) --destory a compound entity
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
    --the flips must happen before the rotation, this is because... reasons.
    if bp_transforms.bp_flip_horizontal then
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["flip_horizontal"][tag_orientation]
    end
    if bp_transforms.bp_flip_vertical then
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["flip_vertical"][tag_orientation]
    end
    --I have no idea what I was thinking when I made this, like why am I starting with i = 2? God knows. But it works, so i'm not touching it. but ???
    for i = 2 , (bp_transforms.bp_rotation/4+1) do --this feels like a mistake, I hope to find it.
      tag_orientation = TFMG_thermal_util.ruleset_lookup[rotation_ruleset]["rotate"][tag_orientation]
    end

    --convert tag orientaiton back into direction and orientation.
    local new_direction = TFMG_thermal_util.orientation_to_direction[tag_orientation]
    local entity_name = bp_entity.name

    TFMG_thermal_util.subtick_trigger_abuse({--we're creating an entity, destorying it and using its destroy event trigger to get some other code to run at the end of the tick.
    --thanks to the lord thy god for that idea. It's brilliant.
      data_type = "blueprint",
      surface = surface,
      position = bp_location,
      bp_rotation = new_direction,
      entity = entity_name,
    })
  end

  --the subtick_trigger_abuse function leads here. This happens at the end of a tick, after the blueprint or entity has been built.
  --this allows us to actually take all this data we collected in the on prebuild event, and use it *after the entities and ghosts in question have actually been built*
  function TFMG_thermal_compound.apply_smuggled_bp_data(smuggled_data)
    --game.print(serpent.block(smuggled_data))
    local surface = smuggled_data.surface
    local entity_name = smuggled_data.entity
    local position = smuggled_data.position

    --if this building was blueprinted organically, we should see a ghost of the parent entity here. We're gonna store our rotation information inside the ghosts tags.
    local parent_ghost = surface.find_entities_filtered({position = position, ghost_name = entity_name})
    if parent_ghost[1] then
      parent_ghost[1].tags = smuggled_data.bp_rotation --only god knows what the fuck this shit is doing. Wheres "TFMG" coming from? Why does it break if nest the table futher. regardless, since i have no bug reports yet, ill just ignore this shit.
      game.print(serpent.block(parent_ghost[1].tags))
    return end

    --If this building was built instantly or was pasted over an existing building, then we expect there to already be an interface, and we can interact with that.
    local interface = surface.find_entity(entity_name.."-thermal-interface",position)
    if interface then
      interface.direction = smuggled_data.bp_rotation.direction
      interface.mirroring = smuggled_data.bp_rotation.mirroring
    return end
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
      bp_flip_horizontal = event.flip_horizontal,
      bp_flip_vertical = event.flip_vertical,
    }
    --game.print(bp_rotation..tostring(bp_flip_horizontal)..tostring(bp_flip_vertical))

    --actions for every blueprinted entity.

    for bp_index, bp_entity in pairs(bp_entities) do
      if blueprint_entity_filter(bp_entity) and bp_entity.tags and bp_entity.tags.TFMG then
        local bp_location = bp_locations[bp_index]
        blueprint_place_tag_handler(bp_entity,bp_transforms,bp_location,bp_build.surface)
      end
    end

    --ill need to handle the undo/redo stack somewhere around here.

    --blueprint overbuild stuff

    --through some stroke of luck or whatever, it seems I dont have to do anything special to buildings that are getting overplaced. The whole data smuggling trick from earlier actually seems to just, do that for me. nice.
  	--local overlap_map = bp_build:map_blueprint_indices_to_overlapping_entities(blueprint_entity_filter)
  	--if not overlap_map or (not next(overlap_map)) then return end
  	---- Map blueprint tags on to the entities
  	--for bp_index, entity in pairs(overlap_map) do
  	--	local tags = bp_entities[bp_index].tags or {}
  	--	blueprint_overbuild_handler(tags, entity)
  	--end
  end

--direct rotation handlers
  function TFMG_thermal_compound.handle_transform(event,transform) --note that the input event occurs before the game actually does anything.
    local v = TFMG_thermal_util.get_entry_from_input_event(event)
    if not v then game.print("no interface entry found from input event") return end

    --gather rotation rules
    local rotation_ruleset = prototypes.mod_data["TFMG-thermal-"..event.selected_prototype.name].data.rotation_ruleset_world
    if rotation_ruleset == "_01" then return end --dont rotate if not rotatable.
    --smuggle data so we can add it to our undo stack
    TFMG_thermal_util.subtick_trigger_abuse({
      data_type = "undo-stack",
      player_index = event.player_index,
      modified_interfaces = {
        {--While nesting like this isnt necessary here, hopefully this means i can use a unified method for when one entity, and many entities all need undos together
          --normally i'd just put in v.interface, but for whatever reason that doesn't seem to work here. Looks like the data that can be stored in a tag is quite limited.
          surface_index = v.interface.surface.index,
          interface_position = v.interface.position,
          interface_name = v.interface.name,
          original_direction = v.interface.direction,
          original_mirroring = v.interface.mirroring,
        },
      }
    })
    --finally, actually rotate the interface
    TFMG_thermal_util.advanced_rotate(v.interface,transform,rotation_ruleset) --flawed in the sense that non rotatable entities that can become rotatable can be broken.
  end

--undo event tag setup
  --undo key is evil.
  function TFMG_thermal_compound.tag_undo(smuggled_data) --This function will work, totally.
    --game.print(serpent.block(smuggled_data))
    local player = game.players[smuggled_data.player_index]
    local undo_stack = player.undo_redo_stack
    --we're tagging the top item and top action of the undo stack. God knows if thats a good idea.
    undo_stack.set_undo_tag(1,1,"TFMG_thermal",smuggled_data.modified_interfaces)
  end

--undo/redo events

  function TFMG_thermal_compound.undo_redo_applied(event)
    if not event.actions[1].tags or not event.actions[1].tags.TFMG_thermal then return end
    local undo_redo_data = event.actions[1].tags.TFMG_thermal
    --we'll need to prep the reverse event also.
    local player = game.players[event.player_index]
    local undo_redo_stack = player.undo_redo_stack
    local revert_data = {}
    --for each individual item stored in the tag we should do stuff
    for _,interface_data in pairs(undo_redo_data) do
      local surface_index = interface_data.surface_index
      local surface = game.surfaces[surface_index]
      local interface_name = interface_data.interface_name
      local interface_position = interface_data.interface_position
      local interface = surface.find_entity(interface_name,interface_position)
      if interface and interface.valid then
        --add the appropriate information into the revert data (basically, if we're undoing, this goes into the redo, and if we're redoing, we're putting this into the redo)
        table.insert(revert_data,{
          surface_index = surface_index,
          interface_position = interface_position,
          interface_name = interface_name,
          original_direction = interface.direction,
          original_mirroring = interface.mirroring,
        })
        --actually reorient the thingymajig
        interface.direction = interface_data.original_direction
        interface.mirroring = interface_data.original_mirroring
      end
    end
    --now place the revert data into the correct tags based on weather we just undid, or redid our action
    if event.name == defines.events.on_undo_applied then
      undo_redo_stack.set_redo_tag(1,1,"TFMG_thermal",revert_data)
    else
      undo_redo_stack.set_undo_tag(1,1,"TFMG_thermal",revert_data)
    end
  end



return TFMG_thermal_compound