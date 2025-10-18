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
    enabled = true,
    hidden = true,
    ingredients = {},
    results = {},
  },
  {--ground radiator
    type = "item",
    name = "ground-radiator",
    icon = "__TFMG-thermal__/graphics/radiator-ground/radiator-ground-icon.png",
    icon_size = 64,
    subgroup = "energy",
    order = "d[radiator]",
    hidden = true,
    inventory_move_sound = item_sounds.mechanical_inventory_move,
    pick_sound = item_sounds.mechanical_inventory_pickup,
    drop_sound = item_sounds.mechanical_inventory_move,
    place_result = "ground-radiator",
    stack_size = 50,
  },
  {--placed ground radiator
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
  }
})