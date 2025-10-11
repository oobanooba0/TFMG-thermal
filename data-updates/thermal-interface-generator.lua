---Heat interface connections
  --connected
    local HP_NS = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-vertical-1.png", scale = 0.5}
    local HP_EW = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-straight-horizontal-1.png", scale = 0.5}
  --disconnected
    local HP_N = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-down-1.png", scale = 0.5,shift = {0,-0.3}}
    local HP_E = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-left-1.png", scale = 0.5,shift = {0.3,0}}
    local HP_S = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-up-1.png", scale = 0.5,shift = {0,0.3}}
    local HP_W = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heat-pipe-ending-right-1.png", scale = 0.5,shift = {-0.3,0}}
  --connected hot
    local HP_NS_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-vertical-1.png", scale = 0.5}
    local HP_EW_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-straight-horizontal-1.png", scale = 0.5}
  --disconnected hot
    local HP_N_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-down-1.png", scale = 0.5,shift = {0,-0.3}}
    local HP_E_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-left-1.png", scale = 0.5,shift = {0.3,0}}
    local HP_S_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-up-1.png", scale = 0.5,shift = {0,0.3}}
    local HP_W_Hot = {size = 64, filename = "__base__/graphics/entity/heat-pipe/heated-ending-right-1.png", scale = 0.5,shift = {-0.3,-0}}


local function generate_thermal_interface_icons(machine) -- handles the creation of an entity icon for the editor gui.
  local icons = {{
      icon = "__base__/graphics/icons/signal/signal-fire.png",
      icon_size = 64,
    }}

  if machine.icon then
    table.insert(icons,{
      icon = machine.icon,
      icon_size = (machine.icon_size or defines.default_icon_size),
      scale = 16.0 / (machine.icon_size or defines.default_icon_size), -- scale = 0.5 * 32 / icon_size simplified
      shift = fluid_icon_shift
    })
  elseif machine.icons then
    icons = util.combine_icons(icons, machine.icons, {scale = 0.5}, machine.icon_size)
  end

  return icons
end

--sanity checks and error logging
  local function log_thermal_interface_error(string)
    log("Thermal interface generation disabled: " .. string .. ".")
  end

  local function can_generate_thermal_interfaces(machines)
    if not machines then
      log_thermal_interface_error("there are no machines")
    return end

    return true
  end

--generate a thermal interfaces, and add it to data.raw
  local function generate_thermal_interface(machine)
    if machine.thermal_system ~= true then return end -- Check if machine is opted into the thermal system.

    local interface = {--machine interface template
      type = "reactor",
      name = machine.name .. "-thermal-interface",
      localised_name = {"entity-name.thermal-interface", machine.localised_name or {"entity-name."..machine.name}},
      order = "y",
      icons = generate_thermal_interface_icons(machine),
      flags = {"placeable-neutral", "player-creation","not-on-map","not-blueprintable","not-deconstructable","no-automated-item-insertion","no-automated-item-removal"},
      collision_mask = {layers ={}}, --the interface does not concern itself with the plight of lesser entities.
      collision_box = machine.collision_box, --ensures correct placement
      selection_priority = 1, --mostly for debug in editors.
      selectable_in_game = false,
      allow_copy_paste = false,
      consumption = "1W", -- this is actually irrelevant, but its required by the reactor prototype.
      energy_source = { --also irrelevant, but must be defined.
        type = "void",
      },
      heat_buffer = {
        max_temperature = 1000,
        minimum_glow_temperature = 1,
        specific_heat = "1MJ",--This will be proportioned to machine size I think.
        max_transfer = "100TW",--Ultimately, this will be limited more by connections than anything else.
        connections = {--we must get connections some smarter way, but this will do.
          { position = {0, -1}, direction = defines.direction.north },
          { position = {1, 0}, direction = defines.direction.east },
          { position = {0, 1}, direction = defines.direction.south },
          { position = {-1, 0}, direction = defines.direction.west },
        },
      },
      connection_patches_connected = { HP_NS, HP_EW, HP_NS, HP_EW },
      connection_patches_disconnected = { HP_N, HP_E, HP_S, HP_W },
      heat_connection_patches_connected ={ HP_NS_Hot, HP_EW_Hot, HP_NS_Hot, HP_EW_Hot },--I should look into the fact that heat connections are identical to regular ones
      heat_connection_patches_disconnected ={ HP_N_Hot, HP_E_Hot, HP_S_Hot, HP_W_Hot },
    }
    data:extend({interface})
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