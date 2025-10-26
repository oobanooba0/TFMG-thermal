local ground_radiator_shift = util.by_pixel(0,0)
local hit_effects = require("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")
local item_sounds = require("__base__.prototypes.item_sounds")

data:extend({
  {
    type = "recipe-category",
    name = "radiator"
  },
  {--Theres nothing particularly important about this recipe, it just acts as a way to get a radiator to operate forever.
    type = "recipe",
    category = "radiator",
    name = "TFMG-heat-radiation",
    icon = "__base__/graphics/icons/signal/signal-fire.png",
    energy_required = 100,
    enabled = false,
    hidden = true,
    ingredients = {},
    results = {},
  },
  {--blueprint building proxy entity. Used to make blueprint building work.
    type = "simple-entity-with-owner",
    name = "TFMG-thermal-bp-proxy",
    icon = "__base__/graphics/icons/signal/signal-fire.png",
    --picture makes this visible for debug purposes.
    --picture = {
    --  filename = "__base__/graphics/icons/signal/signal-fire.png",
    --  size = 64,
    --},
    --minable = {mining_time = 0},
    collision_mask = {layers = {}},
    flags = {"placeable-off-grid"},
    hidden = true,
  },
})
---ground radiator
data:extend({
  {--ground radiator item
    type = "item",
    name = "ground-radiator",
    icon = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-icon.png",
    icon_size = 64,
    subgroup = "energy",
    order = "d[radiator]",--adjust this if it displeases you.
    hidden = true,
    inventory_move_sound = item_sounds.mechanical_inventory_move,
    pick_sound = item_sounds.mechanical_inventory_pickup,
    drop_sound = item_sounds.mechanical_inventory_move,
    place_result = "ground-radiator",
    stack_size = 50,
  },
  {--ground radiator entity
    type = "assembling-machine",
    name = "ground-radiator",
    icon = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-icon.png",
    hidden = true,
    flags = {"placeable-neutral","player-creation"},
    minable = {mining_time = 0.2, result = "ground-radiator"},
    max_health = 400,
    circuit_wire_max_distance = assembling_machine_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions["assembling-machine"],
    collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    impact_category = "metal",
    working_sound =
    {
      sound = {filename = "__base__/sound/nuclear-reactor-1.ogg", volume = 0.45, audible_distance_modifier = 0.5},
      fade_in_ticks = 4,
      fade_out_ticks = 20
    },
    damaged_trigger_effect = hit_effects.entity(),
    graphics_set =
    {
      animation =
      {
        layers =
        {
          {
            filename = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground.png",
            priority = "high",
            line_length = 1,
            frame_count = 1,
            animation_speed = 0.25,
            width = 256,
            height = 256,
            shift = ground_radiator_shift,
            scale = 0.5
          },
          {
            filename = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-shadow.png",
            priority = "high",
            line_length = 1,
            frame_count = 1,
            animation_speed = 0.25,
            width = 256,
            height = 256,
            shift = ground_radiator_shift,
            scale = 0.5,
            draw_as_shadow = true,
          },
        }
      },
      working_visualisations = {{
        fadeout = true,
        effect = "uranium-glow",
        light = {intensity = 2, size = 4.5, shift = {0, 0}, color = {1, 0.2, 0.2}},
        animation = {
          filename = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-working.png",
          priority = "high",
          width = 256,
          height = 256,
          shift = ground_radiator_shift,
          scale = 0.5,
          blend_mode = "additive",
        },
      }},
      water_reflection = {
        pictures =
        {
          filename = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-water-reflection.png",
          priority = "extra-high",
          width = 24,
          height = 24,
          shift = util.by_pixel(5, 40),
          variation_count = 1,
          scale = 5
        },
        rotate = false,
        orientation_to_variation = false
      }
    },
    crafting_categories = {"radiator"},
    fixed_recipe = "TFMG-heat-radiation",
    crafting_speed = 1,
    energy_usage = "1MW",
    energy_source =
    {
      type = "heat",
      max_temperature = 1000,
      min_working_temperature = 15,
      default_temperature = 15,
      specific_heat = "1MJ",
      max_transfer = "1GW",
      connections =
      {--north connection is not real and cannot hurt me.
        { position = {0, -1}, direction = defines.direction.north},
        { position = {1, 0}, direction = defines.direction.east},
        { position = {0, 1}, direction = defines.direction.south},
        { position = {-1, 0}, direction = defines.direction.west},
      },
      heat_picture = {
        layers = {
          {
            filename = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-heat.png",
            priority = "high",
            width = 256,
            height = 256,
            shift = ground_radiator_shift,
            scale = 0.5,
            draw_as_glow = true,
            blend_mode = "additive-soft",
          },
        }
      }
    }
  },
})
--space age enabled prototypes
 local small_radiator_connector = circuit_connector_definitions.create_vector
    (
      universal_connector_template,
      {
        { variation = 18, main_offset = util.by_pixel(5, 5), shadow_offset = util.by_pixel(35, 31), show_shadow = true },
        { variation = 18, main_offset = util.by_pixel(-10, 5), shadow_offset = util.by_pixel(35, 31), show_shadow = true },
        { variation = 18, main_offset = util.by_pixel(5, -10), shadow_offset = util.by_pixel(35, 31), show_shadow = true },
        { variation = 18, main_offset = util.by_pixel(10, 5), shadow_offset = util.by_pixel(35, 31), show_shadow = true }
      }
    )
if feature_flags["space_travel"] then
--space radiator 
  --graphics helpers.
    local pixel = 1/32
    local radiator_shift_n = {0,-2+pixel*1}
    local radiator_shift_e = {2-pixel*1,0}
    local radiator_shift_s = {0,2-pixel*1}
    local radiator_shift_w = {-2+pixel*1,0}
  --space platform collision mask
  local tile_collision_masks = require("__base__/prototypes/tile/tile-collision-masks")
  data:extend({{ type = "collision-layer", name = "platform" }})--quick, we have to add an entire collision layer just to unfuck our radiators.

data:extend({
  {--small radiator item
    type = "item",
    name = "small-radiator",
    icon = "__TFMG-thermal__/graphics/small-radiator/small-radiator-icon.png",
    icon_size = 64,
    subgroup = "space-related",--realistically these can only be placed in space, so I suppose this makes the most sense.
    order = "d[radiator]",
    inventory_move_sound = item_sounds.mechanical_inventory_move,
    pick_sound = item_sounds.mechanical_inventory_pickup,
    drop_sound = item_sounds.mechanical_inventory_move,
    place_result = "small-radiator",
    stack_size = 50,
    weight = 20 * kg,
    hidden = true,
  },
  {--small radiator
    type = "assembling-machine",
    name = "small-radiator",
    icon = "__TFMG-thermal__/graphics/small-radiator/small-radiator-icon.png",
    icon_size = 64,
    flags = {"placeable-neutral","player-creation","filter-directions"},--filter directions doesnt work, I want to find out why.
    hidden = true,
    minable = {mining_time = 0.2, result = "small-radiator"},
    max_health = 250,
    circuit_wire_max_distance = assembling_machine_circuit_wire_max_distance,
    circuit_connector = small_radiator_connector,
    collision_box = {{-0.4, -4.4}, {0.4, 0.4}},
    selection_box = {{-0.5, -4.5}, {0.5, 0.5}},
    tile_height = 1,
    tile_width = 1,
    tile_buildability_rules =
    {
      {area = {{-0.4, -4.4}, {0.4, 0.4}}, required_tiles = {layers = {empty_space = true}}, remove_on_collision = true},
      {area = {{-0.4, 0.6}, {0.4, 0.9}}, required_tiles = {layers = {ground_tile = true}}, colliding_tiles = {layers = {empty_space = true}}, remove_on_collision = true},
    },
    surface_conditions = {{property = "gravity",min = 0,max = 0}},
    collision_mask = {layers={is_object = true, is_lower_object = true, transport_belt = true, platform = true}},
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    impact_category = "metal",
    working_sound =
    {
      sound = {filename = "__base__/sound/nuclear-reactor-1.ogg", volume = 0.45, audible_distance_modifier = 0.5},
      fade_in_ticks = 4,
      fade_out_ticks = 20
    },
    damaged_trigger_effect = hit_effects.entity(),
    graphics_set = { animation = {
      north = { layers = {
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-1.png",size = 384, scale = 0.5,shift = radiator_shift_n},
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-shadow-1.png",size = 384, scale = 0.5,draw_as_shadow = true,shift = radiator_shift_n},
        }},
      east = { layers = {
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-2.png",size = 384, scale = 0.5,shift = radiator_shift_e},
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-shadow-2.png",size = 384, scale = 0.5,draw_as_shadow = true,shift = radiator_shift_e},
        }},
      south = { layers = {
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-3.png",size = 384, scale = 0.5,shift = radiator_shift_s},
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-shadow-3.png",size = 384, scale = 0.5,draw_as_shadow = true,shift = radiator_shift_s},
        }},
      west = { layers = {
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-4.png",size = 384, scale = 0.5,shift = radiator_shift_w},
        {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-shadow-4.png",size = 384, scale = 0.5,draw_as_shadow = true,shift = radiator_shift_w},
        }},
      },
      working_visualisations = {{
        fadeout = true,
        effect = "uranium-glow",
        light = {intensity = 2, size = 4.5, shift = {0, 0}, color = {1, 0.2, 0.2}},
        north_animation = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-working-1.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.4,0.4,0.4}, shift = radiator_shift_n},
        east_animation = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-working-2.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.4,0.4,0.4}, shift = radiator_shift_e},
        south_animation = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-working-3.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.4,0.4,0.4}, shift = radiator_shift_s},
        west_animation = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-working-4.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.4,0.4,0.4}, shift = radiator_shift_w},
      }}
    },
    crafting_categories = {"radiator"},
    fixed_recipe = "TFMG-heat-radiation",
    crafting_speed = 1,
    energy_source =
    {
      type = "heat",
      max_temperature = 1000, --this has to be a big number or a thermal system could lock up and be unable to cool down
      min_working_temperature = 15,
      default_temperature = 15,
      specific_heat = "1MJ",--radiator graphics get weird if they have more specific heat than the heat pipe they are connected to.
      max_transfer = "1GW",
      connections =
      {--north connection is not real and cannot hurt me.
        {
          position = {0, 0},
          direction = defines.direction.south
        },
      },
      heat_picture = {
        north = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-heat-1.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.5,0.5,0.5}, shift = radiator_shift_n},
        east = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-heat-2.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.5,0.5,0.5}, shift = radiator_shift_e},
        south = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-heat-3.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.5,0.5,0.5}, shift = radiator_shift_s},
        west = {filename = "__TFMG-thermal__/graphics/small-radiator/small-radiator-heat-4.png",size = 384, scale = 0.5,blend_mode = "additive",draw_as_glow = true,tint = {0.5,0.5,0.5}, shift = radiator_shift_w},
      }
    },
    energy_usage = "2MW",--change this to fit the balance of your mod.
    placeable_position_visualization =
    {
      filename = "__core__/graphics/cursor-boxes-32x32.png",
      priority = "extra-high-no-scale",
      width = 64,
      height = 64,
      scale = 0.5,
      x = 3*64
    },
  },
})

  data.raw.tile ["space-platform-foundation"].collision_mask = {layers={ground_tile=true,platform=true}} -- necessary for the splatform collision mask to work.
  local ground_radiator_item = data.raw.item["ground-radiator"]
  ground_radiator_item.weight = 20 * kg
end