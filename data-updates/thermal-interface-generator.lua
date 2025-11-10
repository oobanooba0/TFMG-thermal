--this file contains all the code used to read the TFMG_thermal information from your machine prototypes and generate the theramal interface prototypes, as well as prepare the mod data tables and pre-calculate energy usage.
--Nothing in here is all too important for you to understand.

--sanity checks and error logging
  local function log_thermal_interface_error(string)
    error("Thermal interface generation failed:" .. string .. ".",0)
  end

  local function can_generate_thermal_interfaces(machines)
    if not machines then
      log_thermal_interface_error("There are no machines that can be generated.")
    return end
  return true end

--Heat interface connection graphic definitions
  local heat_pipe_connected = {--connected
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-vertical-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-horizontal-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-vertical-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-horizontal-1.png", scale = 0.5},
  }
  local heat_pipe_disconnected = {--disconnected
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-down-1.png", scale = 0.5,shift = {0,-0.3}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-left-1.png", scale = 0.5,shift = {0.3,0}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-up-1.png", scale = 0.5,shift = {0,0.3}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-right-1.png", scale = 0.5,shift = {-0.3,0}},
  }
  local heat_pipe_glow_connected = {--connected hot
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-vertical-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-horizontal-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-vertical-1.png", scale = 0.5},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-horizontal-1.png", scale = 0.5},
  }
  local heat_pipe_glow_disconnected = {--disconnected hot
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-down-1.png", scale = 0.5,shift = {0,-0.3}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-left-1.png", scale = 0.5,shift = {0.3,0}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-up-1.png", scale = 0.5,shift = {0,0.3}},
    {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-right-1.png", scale = 0.5,shift = {-0.3,-0}},
  }
--icon graphic generation
  local function generate_thermal_interface_icons(machine) --handles the creation of an entity icon for the editor gui.
  local icons = {{--this is icon we're gonna use as a base.
      icon = "__base__/graphics/icons/signal/signal-fire.png",
      icon_size = 64,
    }}
  local icon_size = machine.icon_size or defines.default_icon_size
  if machine.icon then
    table.insert(icons,{
      icon = machine.icon,
      icon_size = (icon_size),
      scale = 16.0 / (icon_size),
    })
  elseif machine.icons then
    icons = util.combine_icons(icons, machine.icons, {scale = 0.5}, icon_size)
  end
  return icons end
--math and coordinate transform functions
  local function semifloor(number)--Round down number to the nearest 0.5
  return math.floor(number*2)/2 end

  local function semiceil(number)
  return math.ceil(number*2)/2 end--Round up number to the nearest 0.5

  local function rotate(coordinate)--rotate a pair of coordinates 90 degrees around 0,0
    local rotated_coordinate = {-coordinate[2],coordinate[1]}
  return rotated_coordinate end

  local function mirror(coordinate)--flip a pair of coordinates along the x axis
    local mirrored_coordinate = {-coordinate[1],coordinate[2]}
  return mirrored_coordinate end

  local function rotate_connection(connection) --rotate a connection 90 degrees
    local coordinate = connection.position
    local rotated_coordinate = rotate(coordinate)
    local direction = connection.direction + 4
    if direction >= 16 then direction = direction - 16 end
    local rotated_connection = { position = rotated_coordinate, direction = direction}
  return rotated_connection end

  local function mirror_connection(connection) --Mirror a connection horizontally
    local coordinate = connection.position
    local mirrored_coordinate = mirror(coordinate)
    local direction = connection.direction
    if direction == 4 then direction = 12--we only need to flip the west and east connections, north and south stay the same
    elseif direction == 12 then direction = 4 end
    local mirrored_connection = { position = mirrored_coordinate, direction = direction}
  return mirrored_connection end

  local function rotate_connections(connections)--rotate a set of connections
    local rotated_connections = {}
    for name, connection in pairs(connections) do
      table.insert(rotated_connections, rotate_connection(connection))
    end
  return rotated_connections end

  local function mirror_connections(connections)--mirror a set of connections along the X axis
    local mirrored_connections = {}
    for name, connection in pairs(connections) do
      table.insert(mirrored_connections, mirror_connection(connection))
    end
  return mirrored_connections end

  local function rotate_collision_box(collision_box)--my mind is a machine that turns
    local rotated_collision_box = {
     {-collision_box[2][2],collision_box[1][1]},
     {-collision_box[1][2],collision_box[2][1]},
    }
  return rotated_collision_box end

  local function mirror_collision_box(collision_box)--this theoretically, shouldnt do anything, but you never know when you need to account for someones off center building.
    local rotated_collision_box = {
     {-collision_box[2][1],collision_box[1][2]},
     {-collision_box[1][1],collision_box[2][2]},
    }
  return rotated_collision_box end

  local function is_square(coordinate_pair)--checks if a pair of coordinates are square
    if coordinate_pair[2][1]-coordinate_pair[1][1] == coordinate_pair[2][2]-coordinate_pair[1][2] then return true end
  return false end


--Generate the initial heat pipe connections for the north varient of the machine, either from a connection set prototype, or by generating one from scratch
  local function generate_thermal_interface_connections(machine)
    if not machine.TFMG_thermal.connections then -- if no connections are defined, we shall generate one automagically
      --We're gonna find the coordinates of the center of the x most, and y most tiles of the collision box.
      local machine_box = machine.collision_box
      local x_max = semifloor(machine_box[2][1])
      local x_min = semiceil(machine_box[1][1])
      local y_max = semifloor(machine_box[2][2])
      local y_min = semiceil(machine_box[1][2])

      --use the coordinates coordinates create a table of 4 connections on the corners, we don't generate all 8 in one go, since if a machine has a side length of 1, that would create two connections in the same spot, which prevents the game from loading.
      --conceivably, the default layout can be pretty much anything, but the heat pipes at the corner works regardless of size. It makes sense to me as an easy layout.

      connections = {
        { position = {x_min, y_min}, direction = 0 },
        { position = {x_max, y_min}, direction = 4 },
        { position = {x_max, y_max}, direction = 8 },
        { position = {x_min, y_max}, direction = 12 },
      }

      if x_max - x_min > 0 then--if our north and south side length is large enough then we add our second corner connetions.
      table.insert(connections,{ position = {x_max, y_min}, direction = 0 })
      table.insert(connections,{ position = {x_min, y_max}, direction = 8 })
      end

      if y_max - y_min > 0 then--same for the east and west sides.
      table.insert(connections,{ position = {x_max, y_max}, direction = 4 })
      table.insert(connections,{ position = {x_min, y_min}, direction = 12 })
      end

    else connections = machine.TFMG_thermal.connections end --Else use the connection set defined in the entity prototype.
  return connections end

  local function generate_thermal_interface_connections_thruster(machine)
    if not machine.TFMG_thermal.connections then -- if no connections are defined, we shall generate one automagically
      --We're gonna find the coordinates of the center of the x most, and y most tiles of the collision box.
      local machine_box = machine.collision_box
      local x_max = semifloor(machine_box[2][1])
      local x_min = semiceil(machine_box[1][1])
      local y_min = semiceil(machine_box[1][2])

      --basically the same process as generating for normal machines, but we only bother with the top connections.

      connections = {
        { position = {x_min, y_min}, direction = 0 },
      }
      if x_max - x_min > 0 then--if our north and south side length is large enough then we add our second corner connetions.
      table.insert(connections,{ position = {x_max, y_min}, direction = 0 })
      end

    else connections = machine.TFMG_thermal.connections end --Else use the connection set defined in the entity prototype.
  return connections end

  local function generate_thermal_interface_connection_set(machine)--generate all 8 rotations and mirrorings of the connection by generating a north facing connection set, and then flipping and rotating.
    local connections = generate_thermal_interface_connections(machine)--generate north connection set
    local connection_set = {}
    for i = 1, 2 do--mirror
      for i = 1, 4 do --speeeen
        table.insert(connection_set, connections) --get our connection set, and add it to the table
        connections = rotate_connections(connections) --rotate the set.
      end
    connections = mirror_connections(connections)--do a flip
    end
  return connection_set end

  local function generate_thermal_interface_collision_box_set(machine)--correct collision boxes are required for the heat interfaces to be placed in the right spots
    local collision_box_set = {}
    local collision_box = machine.collision_box
    for i = 1, 2 do 
      for i = 1, 4 do --speeeen
        table.insert(collision_box_set, collision_box) -- start by getting the north set and putting it in our table on index 1
        collision_box = rotate_collision_box(collision_box)
      end
      mirror_collision_box(collision_box)
    end
  return collision_box_set end

  local function calculate_machine_footprint(machine)--calculate the number of tiles a machine takes up.
    local machine_box = machine.collision_box
    --We're gonna find number of tiles a machine takes up, so we have to round outwards to thhe outer corners of the tile.
    local x_max = semiceil(machine_box[2][1])
    local x_min = semifloor(machine_box[1][1])
    local y_max = semiceil(machine_box[2][2])
    local y_min = semifloor(machine_box[1][2])

    local area = (x_max-x_min)*(y_max-y_min)
  return area end

  --Because neither you, nor I want to do this every time.

  local function generate_heat_patches_from_connections (connections,interface)--uses the set of heat 
    local interface = interface --I gotta check if this was important or whatever.
    --setting up the connection patch tables.
    interface.connection_patches_connected = {}
    interface.connection_patches_disconnected = {}
    interface.heat_connection_patches_connected = {}
    interface.heat_connection_patches_disconnected = {}

    for _, connection in pairs(connections) do
      local direction = connection.direction/4+1--this is goofy, but it works. basically we're just converting direction 0,4,8,12 into 1,2,3,4 which corresponds to an index within a predefined table of heat pipe textures, and we slam that into a new table of connection patches.
      table.insert(interface.connection_patches_connected, heat_pipe_connected[direction])
      table.insert(interface.connection_patches_disconnected, heat_pipe_disconnected[direction])
      table.insert(interface.heat_connection_patches_connected, heat_pipe_glow_connected[direction])
      table.insert(interface.heat_connection_patches_disconnected, heat_pipe_glow_disconnected[direction])
    end
  return interface end

  local function surface_condition_compare(surface,conditions)--this function fucks.
  if conditions == nil then return true end -- if we dont have any surface conditions, we already know it will pass
    for _ , condition in pairs(conditions) do --checking each surface condition requirement, if any fail, we return false.
      local surface_condition_value = surface.surface_properties[condition.property] or data.raw["surface-property"][condition.property].default_value
      if condition.min > surface_condition_value or surface_condition_value > condition.max then return false end
    end
  return true end --if all conditions have passed, then we return true.

  local function TFMG_thermal_locations(machine)--Generate a string that lists all the locations the thermal system will apply to this machine, in the form of nice planet icons.
    local locations = ""
    local location_passes = 0
    local locations_listed = 0
    local conditions = machine.TFMG_thermal.surface_conditions
    if surface_condition_compare(data.raw["surface"]["space-platform"],conditions) == true then --check if can be placed on platforms. This is seperate since space platforms arent planets, but do have their own surface conditions.
      locations = locations.."[item=space-platform-foundation]"
      location_passes = location_passes + 1
      locations_listed = locations_listed + 1
    end
    for _ , surface in pairs(data.raw["planet"]) do -- We're gonna check if we pass surface conditions on every planet, taking note of how many we pass.
      if surface_condition_compare(surface,conditions) == true then
        location_passes = location_passes + 1
        locations_listed = locations_listed + 1
      end
    end
    if table_size(data.raw["planet"]) + 1 == location_passes then --If we pass every single planet check, then we know the thermal system will apply on every planet, so we just say "everything"
      locations = {"TFMG-thermal.all-locations"}
      return locations end
    for _ , surface in pairs(data.raw["planet"]) do --go through every planet prototype again, but this time, we're gonna build up our string of locations, making sure to stop before we hit 200 characters, which is the limit for custom tooltips.
      if surface_condition_compare(surface,conditions) == true then
        locations2 = locations.."[planet="..surface.name.."]"
        if string.len(locations2) >= 200 then --if we do exceed the character limit, we're gonna go back one step, calculate how many planets we didnt get to list, and append that instaid. We know this will always fit because this can only ever use 9 on the string (provided you have 99 or fewer planets.), and "[planet=".."]" will always take up at least 9 characters + the length of the planet name.
        return locations.."+ "..location_passes-locations_listed.." more" end
        locations = locations2
      end
    end
  return locations end

  local function build_and_check_surface_conditions(machine)--for the most part handles correcting any missing information in a surface condition table
    if not machine.TFMG_thermal.surface_conditions then return end
    surface_conditions = {}
    for _ , prototype_condition in pairs(machine.TFMG_thermal.surface_conditions) do
      if not prototype_condition.property then log_thermal_interface_error("a surface condition property must be specified to evaluate TFMG_thermal surface conditions. Check prototype:"..machine.name) return end
      local new_surface_condition = {
        property = prototype_condition.property,
        min = prototype_condition.min or 0,
        max = prototype_condition.max or math.huge,
      }
      if new_surface_condition.min > new_surface_condition.max then log_thermal_interface_error("A surface condition's minimum value is greater than its maximum value. Check prototype:"..machine.name) return end
      table.insert(surface_conditions,new_surface_condition)
    end
  return surface_conditions end

  local function set_rotation_rules(machine)
    local rotation_ruleset = "RF_08" --Right now, no distinction is needed.
    local rotation_ruleset_world = "RF_08"
    if not is_square(machine.collision_box) then
      rotation_ruleset_world = "rF_08"
    end
  return rotation_ruleset, rotation_ruleset_world end

  local function calculate_specific_heat(machine)--we're gonna calculate the specific heat capacity for the machine based on some of its properties.
    local specific_heat
    if machine.TFMG_thermal.specific_heat then 
      if type(machine.TFMG_thermal.specific_heat) ~= "string" then log_thermal_interface_error("specific heat should be formatted as string. Check: "..machine.name) return end
      specific_heat = util.parse_energy(machine.TFMG_thermal.specific_heat)
    else
      if not data.raw["heat-pipe"]["heat-pipe"] then log_thermal_interface_error("a heat pipe prototype must exist for thermal interface specific heat calculation to be possible.") return end
      specific_heat = calculate_machine_footprint(machine)*util.parse_energy(data.raw["heat-pipe"]["heat-pipe"].heat_buffer.specific_heat)
    end
  return specific_heat end

--generate a thermal interfaces, and add it to data.raw
  local function generate_thermal_interface(machine)
    if not machine.TFMG_thermal then return end -- Check if machine is opted into the thermal system. 
    local specific_heat = calculate_specific_heat(machine)
    local connection_set = generate_thermal_interface_connection_set(machine)
    local collision_set = generate_thermal_interface_collision_box_set(machine)
    local surface_conditions = nil
    if feature_flags["space_travel"] then--only if we have space age features enabled can we use surface conditions. Surface conditions are stored in the interface prototype, dispite this actually not having any direct effect. Surface conditions dont affect entities placed by script.
      surface_conditions = build_and_check_surface_conditions(machine)
    end
    machine.TFMG_thermal.surface_conditions = surface_conditions
    for direction, connections in pairs(connection_set) do
      local interface = {--machine interface template
        type = "reactor",
        name = machine.name .. "-thermal-interface"..direction,
        localised_name = {"entity-name.thermal-interface", machine.localised_name or {"entity-name."..machine.name}},
        order = "y"..machine.type,
        icons = generate_thermal_interface_icons(machine),
        flags = {"placeable-neutral", "player-creation","not-on-map","not-blueprintable","not-deconstructable","no-automated-item-insertion","no-automated-item-removal"},
        collision_mask = {layers ={}}, --the interface does not concern itself with the plight of lesser entities.
        collision_box = collision_set[direction], --ensures correct placement
        selection_box = collision_set[direction],
        selection_priority = 40,
        selectable_in_game = true,
        allow_copy_paste = false,
        hidden = true,
        consumption = "1W", -- this is actually irrelevant, but its required by the reactor prototype.
        energy_source = { --also irrelevant, since interfaces are disabled by script at birth, but wube demands it.
          type = "void",
        },
        heat_buffer = {
          max_temperature = 1000,--These two values just match heat pipes, and should be fine in pretty much all sane use cases.
          minimum_glow_temperature = 350,
          specific_heat = specific_heat.."J",
          max_transfer = "100TW",--Ultimately, this will be limited more by connections than anything else.
          connections = connections--we shall connect the world.
        },
      }

      generate_heat_patches_from_connections(interface.heat_buffer.connections,interface)

      if feature_flags["space_travel"] then interface.surface_conditions = surface_conditions end

      data:extend({interface})
    end
    
    --gather information we will put into a mod data table to recall during runtime.
    local heat_ratio = machine.TFMG_thermal.heat_ratio or 0.5
    local max_working_temperature = machine.TFMG_thermal.max_working_temperature or 250
    local max_safe_temperature = machine.TFMG_thermal.max_safe_temperature or 350
    local energy_usage_per_tick = util.parse_energy(machine.energy_usage) -- in joules
    local base_heat_output = energy_usage_per_tick*heat_ratio*60--in W
    local base_temperature_increase_per_tick = (energy_usage_per_tick*heat_ratio)/(specific_heat)--precalculate the per tick base heat output of the machine. That way we don't need to calculate it in runtime.
    local default_temperature = 0
    if max_working_temperature >= max_safe_temperature then
      default_temperature = max_safe_temperature - 10
    else
      default_temperature = max_working_temperature - 10
    end

    local rotation_ruleset, rotation_ruleset_world = set_rotation_rules(machine)
    local script_type = "crafting-machine"
    local heat_when_disabled = false
    if machine.TFMG_thermal.heat_when_disabled_by_script then heat_when_disabled = true end

    local machine_data = {--this information we take into runtime, since we need it for scripts or for gui.
      type = "mod-data",
      data_type = "TFMG-thermal.thermal-interface",
      name = "TFMG-thermal-"..machine.name,
      data = {
        name = machine.name,
        type = script_type,
        heat_when_disabled_by_script = heat_when_disabled,
        max_working_temperature = max_working_temperature,
        max_safe_temperature = max_safe_temperature,
        base_temperature_increase_per_tick = base_temperature_increase_per_tick,--this is in degrees per tick. This is actually the important value, heat ratio and heat output arent actually used when calculating the thermal scripts.
        base_heat_output = base_heat_output,--we still keep these cause theyre useful for gui, and its easy to grab them from here.
        heat_ratio = heat_ratio,
        default_temperature = machine.TFMG_thermal.default_temperature or default_temperature,
        rotation_ruleset = rotation_ruleset,
        rotation_ruleset_world = rotation_ruleset_world,
        surface_conditions = surface_conditions,
        specific_heat = (specific_heat/1000000).."MJ",
      }
    }
    data:extend({machine_data})

    -- now add our custom tooltips
    if not machine.custom_tooltip_fields then machine.custom_tooltip_fields = {} end
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.max-temperature"},
      value = {"TFMG-thermal.machine-max-temperature",tostring(max_working_temperature)},
      order = 252,
    })
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.max-safe-temperature"},
      value = {"TFMG-thermal.machine-max-safe-temperature",tostring(max_safe_temperature)},
      order = 253,
    })
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.efficiency"},
      value = {"TFMG-thermal.machine-efficiency",tostring(heat_ratio*100)},
      order = 254,
    })
    if feature_flags["space_travel"] then--we only care about what planets the thermal system applies on if we have spage
      table.insert(machine.custom_tooltip_fields,{
        name = {"TFMG-thermal.thermal-locations"},
        value = TFMG_thermal_locations(machine),
        order = 255,
      })
    end
  end
--generate thermal interfaces for thrusters. They cannot be rotated and lack many properties that crafting machines do.
  local function generate_thermal_interface_thruster(machine)
    if not machine.TFMG_thermal then return end -- Check if machine is opted into the thermal system. 
    local specific_heat = calculate_specific_heat(machine)
    local connections = generate_thermal_interface_connections_thruster(machine)
    local collision_box = machine.collision_box
    machine.TFMG_thermal.surface_conditions = surface_conditions
    local interface = {--machine interface template
      type = "reactor",
      name = machine.name .. "-thermal-interface".."1",
      localised_name = {"entity-name.thermal-interface", machine.localised_name or {"entity-name."..machine.name}},
      order = "y"..machine.type,
      icons = generate_thermal_interface_icons(machine),
      flags = {"placeable-neutral", "player-creation","not-on-map","not-blueprintable","not-deconstructable","no-automated-item-insertion","no-automated-item-removal"},
      collision_mask = {layers ={}}, --the interface does not concern itself with the plight of lesser entities.
      collision_box = collision_box,
      selection_box = {{-1,-1},{1,1}},
      selection_priority = 250,
      selectable_in_game = true,
      allow_copy_paste = false,
      hidden = true,
      consumption = "1W", -- this is actually irrelevant, but its required by the reactor prototype.
      energy_source = { --also irrelevant, since interfaces are disabled by script at birth, but wube demands it.
        type = "void",
      },
      heat_buffer = {
        max_temperature = 1000,--These two values just match heat pipes, and should be fine in pretty much all sane use cases.
        minimum_glow_temperature = 350,
        specific_heat = specific_heat.."J",
        max_transfer = "100TW",--Ultimately, this will be limited more by connections than anything else.
        connections = connections--we shall connect the world.
      },
    }
    generate_heat_patches_from_connections(interface.heat_buffer.connections,interface)
    data:extend({interface})
    
    --gather information we will put into a mod data table to recall during runtime.
    local max_working_temperature = machine.TFMG_thermal.max_working_temperature or 750
    local max_safe_temperature = machine.TFMG_thermal.max_safe_temperature or 850
    local heat_per_unit_fluid = util.parse_energy(machine.TFMG_thermal.heat_per_unit_fluid or "100kJ")
    local temperature_increase_per_unit_fuel = (heat_per_unit_fluid/specific_heat)*2
    local default_temperature = 0
    if max_working_temperature >= max_safe_temperature then
      default_temperature = max_safe_temperature - 10
    else
      default_temperature = max_working_temperature - 10
    end

    local rotation_ruleset, rotation_ruleset_world = set_rotation_rules(machine)

    local machine_data = {--this information we take into runtime, since we need it for scripts or for gui.
      type = "mod-data",
      data_type = "TFMG-thermal.thermal-interface",
      name = "TFMG-thermal-"..machine.name,
      data = {
        name = machine.name,
        type = "thruster",
        max_working_temperature = max_working_temperature,
        max_safe_temperature = max_safe_temperature,
        temperature_increase_per_unit_fuel = temperature_increase_per_unit_fuel,
        default_temperature = machine.TFMG_thermal.default_temperature or default_temperature,
        rotation_ruleset = "_01",
        rotation_ruleset_world = "_01",
        surface_conditions = nil, --thrusters can only built on platforms, surface conditions are never relevant.
        specific_heat = (specific_heat/1000000).."MJ",
        min_consumption = machine.min_performance.fluid_usage,--per tick
        max_consumption = machine.max_performance.fluid_usage,
        fluid_1_min = machine.fuel_fluid_box.volume*machine.min_performance.fluid_volume,
        fluid_1_max = machine.fuel_fluid_box.volume*machine.max_performance.fluid_volume,
        fluid_2_min = machine.oxidizer_fluid_box.volume*machine.min_performance.fluid_volume,
        fluid_2_max = machine.oxidizer_fluid_box.volume*machine.max_performance.fluid_volume,
        fluid_1_type = machine.fuel_fluid_box.filter,
        fluid_2_type = machine.oxidizer_fluid_box.filter,
      }
    }
    data:extend({machine_data})

    -- now add our custom tooltips
    if not machine.custom_tooltip_fields then machine.custom_tooltip_fields = {} end
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.max-temperature"},
      value = {"TFMG-thermal.machine-max-temperature",tostring(max_working_temperature)},
      order = 252,
    })
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.max-safe-temperature"},
      value = {"TFMG-thermal.machine-max-safe-temperature",tostring(max_safe_temperature)},
      order = 253,
    })
    table.insert(machine.custom_tooltip_fields,{
      name = {"TFMG-thermal.output"},
      value = {"TFMG-thermal.machine-output",tostring(heat_per_unit_fluid/1000)},
      order = 254,
    })
  end
---go through all entities in a prototype category and run generate_thermal_interface for each of them.
  local function generate_thermal_interfaces(machines)
    if not can_generate_thermal_interfaces(machines) then return end --End if we fail sanity check
    for name, machine in pairs(machines) do -- run this script for every machine prototype
      generate_thermal_interface(machine)
    end
  end

  local function generate_thermal_interfaces_thruster(machines)
    if not can_generate_thermal_interfaces(machines) then return end --End if we fail sanity check
    for name, machine in pairs(machines) do -- run this script for every machine prototype
      generate_thermal_interface_thruster(machine)
    end
  end

--Finally, generate thermal interfaces for these categories.
  generate_thermal_interfaces(data.raw["assembling-machine"])
  generate_thermal_interfaces(data.raw["furnace"])
  generate_thermal_interfaces(data.raw["lab"])
  generate_thermal_interfaces(data.raw["beacon"])
  generate_thermal_interfaces(data.raw["mining-drill"])
  generate_thermal_interfaces_thruster(data.raw["thruster"])