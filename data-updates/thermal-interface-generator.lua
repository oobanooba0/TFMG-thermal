---Heat interface connection graphic definitions
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
      scale = 16.0 / (icon_size), -- scale = 0.5 * 32 / icon_size simplified
    })
  elseif machine.icons then
    icons = util.combine_icons(icons, machine.icons, {scale = 0.5}, icon_size)
  end
return icons end

--sanity checks and error logging
  local function log_thermal_interface_error(string)
    log("Thermal interface generation disabled: " .. string .. ".")
  end

  local function can_generate_thermal_interfaces(machines)
    if not machines then
      log_thermal_interface_error("there are no machines")
    return end
  return true end

  local function semifloor(number)--Round down number to the nearest 0.5
  return math.floor(number*2)/2 end

  local function semiceil(number)
  return math.ceil(number*2)/2 end--Round up number to the nearest 0.5

--lets build our interface connections
  local function generate_thermal_interface_connections(machine)
    if not machine.thermal_system.connections then -- if no player defined connection set, we shall generate one automagically
      local machine_box = machine.collision_box
      --We're gonna find the coordinates of the x most, and y most tiles of the collision box.
      local x_max = semifloor(machine_box[2][1])
      local x_min = semiceil(machine_box[1][1])
      local y_max = semifloor(machine_box[2][2])
      local y_min = semiceil(machine_box[1][2])
      
      connections = {--conceivably, the default layout can be pretty much anything, but this setup should work with any machine shape that isnt 1x1. Remember to handle 1x1 edge case later.
        { position = {x_min, y_min}, direction = 0 },
        { position = {x_max, y_min}, direction = 0 },
        { position = {x_max, y_min}, direction = 4 },
        { position = {x_max, y_max}, direction = 4 },
        { position = {x_min, y_max}, direction = 8 },
        { position = {x_max, y_max}, direction = 8 },
        { position = {x_min, y_min}, direction = 12 },
        { position = {x_min, y_max}, direction = 12 },
      }
    else connections = machine.thermal_system.connections end
  return connections end

  local function rotate(coordinate)
    local rotated_coordinate = {-coordinate[2],coordinate[1]}
  return rotated_coordinate end

  local function rotate_connection(connection)
    local coordinate = connection.position
    local rotated_coordinate = rotate(coordinate)
    local direction = connection.direction + 4
    if direction >= 16 then direction = direction - 16 end

    local rotated_connection = { position = rotated_coordinate, direction = direction}

  return rotated_connection end

  local function rotate_connections(connections)
    local rotated_connections = {}
    for name, connection in pairs(connections) do
      table.insert(rotated_connections, rotate_connection(connection))
    end
  return rotated_connections end

  local function mirror_connections(connections)
  end

  local function generate_thermal_interface_connection_set(machine)
    local connections = generate_thermal_interface_connections(machine)
    local connection_set = {}
    for i = 1, 4 do --speeeen
      table.insert(connection_set, connections) -- start by getting the north set and putting it in our table on index 1
      connections = rotate_connections(connections)
    end
  return connection_set end

  local function rotate_collision_box(collision_box)--wheeeee
    local rotated_collision_box = {
     {-collision_box[2][2],collision_box[1][1]},
     {-collision_box[1][2],collision_box[2][1]},
    }
  return rotated_collision_box end

  local function generate_thermal_interface_collision_box_set(machine)


    local collision_box_set = {}
    local collision_box = machine.collision_box
    for i = 1, 4 do --speeeen
      table.insert(collision_box_set, collision_box) -- start by getting the north set and putting it in our table on index 1
      collision_box = rotate_collision_box(collision_box)
    end
  return collision_box_set end

  local function generate_heat_patches_from_connections (connections,interface)--Because neither you, nor I want to do this every time.
    local interface = interface
    --setting up the connection patch tables.
    interface.connection_patches_connected = {}
    interface.connection_patches_disconnected = {}
    interface.heat_connection_patches_connected = {}
    interface.heat_connection_patches_disconnected = {}

    for _, connection in pairs(connections) do
      local direction = connection.direction/4+1--this is goofy, but it works. basically we're just converting direction (0,4,8,12 into 1,2,3,4, which corresponds to an index within a predefined table of heat pipe textures.)
      table.insert(interface.connection_patches_connected, heat_pipe_connected[direction])
      table.insert(interface.connection_patches_disconnected, heat_pipe_disconnected[direction])
      table.insert(interface.heat_connection_patches_connected, heat_pipe_glow_connected[direction])
      table.insert(interface.heat_connection_patches_disconnected, heat_pipe_glow_disconnected[direction])
    end
  return interface end

  local function calculate_machine_footprint(machine)
    local machine_box = machine.collision_box
    --We're gonna find number of tiles a machine takes up, so we have to round outwards.
    local x_max = semiceil(machine_box[2][1])
    local x_min = semifloor(machine_box[1][1])
    local y_max = semiceil(machine_box[2][2])
    local y_min = semifloor(machine_box[1][2])

    local area = (x_max-x_min)*(y_max-y_min)
  return area end

--generate a thermal interfaces, and add it to data.raw
  local function generate_thermal_interface(machine)
    if not machine.thermal_system then return end -- Check if machine is opted into the thermal system.
    local specific_heat = calculate_machine_footprint(machine)*1000000 --in joules. 1MJ, likely will be based on the footprint of the machine.
    local connection_set = generate_thermal_interface_connection_set(machine)
    local collision_set = generate_thermal_interface_collision_box_set(machine)
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

      data:extend({interface})
    end
    
    local heat_ratio = machine.thermal_system.heat_ratio or 0.5
    local energy_usage_per_tick = util.parse_energy(machine.energy_usage) -- in joules
    local base_heat_output = energy_usage_per_tick*heat_ratio*60--in W
    local base_temperature_increase_per_tick = (energy_usage_per_tick*heat_ratio)/(specific_heat)--precalculate the per tick base heat output of the machine. That way we don't need to calculate it in runtime.
    local default_temperature = (machine.thermal_system_max_working_temperature or 250) - 10

    local machine_data = {--this information we take into runtime.
      type = "mod-data",
      data_type = "TFMG-thermal.thermal-interface",
      name = "TFMG-thermal-"..machine.name,
      data = {
        name = machine.name,
        max_working_temperature = machine.thermal_system.max_working_temperature or 250,
        max_safe_temperature = machine.thermal_system.max_safe_temperature or 350,
        base_temperature_increase_per_tick = base_temperature_increase_per_tick,--this is in degrees per tick.
        base_heat_output = base_heat_output,
        heat_ratio = heat_ratio,
        default_temperature = default_temperature,
        debug_field = calculate_machine_footprint(machine),
        rotations = 4,
        mirrorable = true,
      }
    }
    data:extend({machine_data})
  end

  ---go through all machines and run generate_thermal_interface for each of them.
  local function generate_thermal_interfaces(machines)
    if not can_generate_thermal_interfaces(machines) then return end --End if we fail sanity check
    for name, machine in pairs(machines) do -- run this script for every machine prototype
      generate_thermal_interface(machine)
    end
  end

--Finally, generate all the thermal interfaces.
generate_thermal_interfaces(data.raw["assembling-machine"])
generate_thermal_interfaces(data.raw["furnace"])
generate_thermal_interfaces(data.raw["lab"])
generate_thermal_interfaces(data.raw["beacon"])