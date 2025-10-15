thermal_system_core = require("scripts.thermal-system-core")
thermal_system_gui = require("scripts.thermal-system-gui")

local function build_thermal_entity_filter()--set the build event filters. This has to be done after the build event has been registered.
  local filters = {}
  for name , machine in pairs(prototypes.mod_data) do--build the table
    if machine.data_type == "TFMG-thermal.thermal-interface" then
      table.insert(filters,
      {
        filter = "name",
        mode = "or",
        name =  machine.data.name
      })
    end
  end
  if next(filters) == nil then
    script.on_event(defines.events.on_built_entity,nil)
    script.on_event(defines.events.on_robot_built_entity,nil)
    script.on_event(defines.events.on_space_platform_built_entity,nil)
  return end
  script.set_event_filter(defines.events.on_built_entity,filters)
  script.set_event_filter(defines.events.on_robot_built_entity,filters)
  script.set_event_filter(defines.events.on_space_platform_built_entity,filters)
end

local function setup_storage_tables()
  if storage.interfaces == nil then
    storage.interfaces = {}
  end
  if storage.table_index == nil then
    storage.table_index = {}
  end
  for name , machine in pairs(prototypes.mod_data) do--build the sub tables for each machine if they dont already exist. so we can guarantee they exist before any entities have been built.
    if machine.data_type == "TFMG-thermal.thermal-interface" then
      if storage.interfaces[machine.data.name] == nil then
        storage.interfaces[machine.data.name] = {}
      end
      if storage.table_index[machine.data.name] == nil then
        storage.table_index[machine.data.name] = {}
      end
    end
  end
end

script.on_init(function()
  build_thermal_entity_filter()
  setup_storage_tables()
end)

script.on_configuration_changed(function()
  setup_storage_tables()
end)

script.on_load(function()--for some unknown reason, event handlers forget their filters after reload. So we're just gonna rebuild the damn table each time.
  build_thermal_entity_filter()
end)

script.on_event(
  defines.events.on_built_entity,
  function(event)
    thermal_system_core.handle_build_event(event)
  end
)
script.on_event(
  defines.events.on_robot_built_entity,
  function(event)
    thermal_system_core.handle_build_event(event)
  end
)
script.on_event(
  defines.events.on_space_platform_built_entity,
  function(event)
    thermal_system_core.handle_build_event(event)
  end
)
script.on_event(
  defines.events.on_player_rotated_entity,
  function(event)
    thermal_system_core.handle_rotate_event(event)
  end
)
script.on_event(
  defines.events.on_player_flipped_entity,
  function(event)
    thermal_system_core.handle_rotate_event(event)
  end
)
script.on_event(
	defines.events.on_object_destroyed,
	function(event)
		thermal_system_core.handle_destroy_event(event)
	end
)

script.on_event(
  defines.events.on_tick,--Its HaNlDeR sHoUldNt InCluDe PeRfOrMaNce HeAvY CoDe. You cant tell me what to do.
  function ()
    thermal_system_core.thermal_update()
  end
)

