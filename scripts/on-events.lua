--setup events

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
      script.on_event(defines.events.on_entity_cloned,nil)
      script.on_event(defines.events.on_pre_ghost_deconstructed,nil)
    return end
    script.set_event_filter(defines.events.on_built_entity,filters)
    script.set_event_filter(defines.events.on_robot_built_entity,filters)
    script.set_event_filter(defines.events.on_space_platform_built_entity,filters)
    script.set_event_filter(defines.events.on_entity_cloned,filters)
    script.set_event_filter(defines.events.on_pre_ghost_deconstructed,filters)
  end

  local function setup_storage_tables()--this handles the creation of storage tables, but pays no mind to existing storage tables that must no longer exist. Deal with later.
    if not storage.interfaces then storage.interfaces = {} end
    if not storage.table_index then storage.table_index = {} end
    if not storage.player_storage then storage.players = {} end
    if not storage.registered_entities then storage.registered_entities = {} end
    if not storage.prebuild_data then storage.prebuild_data = {} end
    if not storage.smuggled_data then storage.smuggled_data = {} end
    --build the sub tables for each machine if they dont already exist. so we can guarantee they exist before any entities have been built.
    for _ , machine in pairs(prototypes.mod_data) do
      if machine.data_type == "TFMG-thermal.thermal-interface" then
        if storage.interfaces[machine.data.name] == nil then
          storage.interfaces[machine.data.name] = {}
        end
        --table index is used by flib to know where it is when iterating the main tables.
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

--On tick, destroyer of ups

  script.on_event(
    defines.events.on_tick,--"Its HaNlDeR sHoUldNt InCluDe PeRfOrMaNce HeAvY CoDe." You can't tell me what to do.
    function()
      TFMG_thermal_core.thermal_update()
      TFMG_thermal_gui.on_gui_tick()
    end
  )

--player input events
--build events
  script.on_event(
    defines.events.on_built_entity,
    function(event)
      TFMG_thermal_compound.handle_build_event(event)
    end
  )
  script.on_event(
    defines.events.on_robot_built_entity,
    function(event)
      TFMG_thermal_compound.handle_build_event(event)
    end
  )
  script.on_event(
    defines.events.on_space_platform_built_entity,
    function(event)
      TFMG_thermal_compound.handle_build_event(event)
    end
  )
  script.on_event(
    defines.events.on_entity_cloned,
    function(event)
      TFMG_thermal_compound.handle_build_event(event)
    end
  )

  --on prebuild
  script.on_event(
    defines.events.on_pre_build,
    function(event)
      TFMG_thermal_compound.on_pre_build(event)
    end
  )

--destroy events
  script.on_event(
  	defines.events.on_object_destroyed,
  	function(event)
  		TFMG_thermal_compound.handle_destroy_event(event)
      TFMG_thermal_gui.gui_cleanup(event)
  	end
  )

--rotate events
  script.on_event("interface-rotate",
    function (event)
      TFMG_thermal_compound.handle_transform(event,"rotate")
    end
  )
  script.on_event("interface-rotate-reverse",
    function (event)
      TFMG_thermal_compound.handle_transform(event,"rotate_reverse")
    end
  )
  script.on_event("interface-flip-horizontal",
    function (event)
      TFMG_thermal_compound.handle_transform(event,"flip_horizontal")
    end
  )
  script.on_event("interface-flip-vertical",
    function (event)
      TFMG_thermal_compound.handle_transform(event,"flip_vertical")
    end
  )

--blueprint setup event
  script.on_event(
    defines.events.on_player_setup_blueprint,
    function(event)
      TFMG_thermal_compound.bp_setup(event)
    end
  )
--undo/redo events
  script.on_event(
    defines.events.on_undo_applied,
    function(event)
      TFMG_thermal_compound.undo_redo_applied(event)
    end
  )
  script.on_event(
    defines.events.on_redo_applied,
    function(event)
      TFMG_thermal_compound.undo_redo_applied(event)
    end
  )

--Sketchy Gui related events. Replace these later
--"RePlaCe ThEsE LaTeR"
  script.on_event(defines.events.on_player_created, 
  function(event)
  	TFMG_thermal_gui.on_player_join(event)
  end)

  --make sure player storage exist when adding mod to existing game
  script.on_event(defines.events.on_singleplayer_init, 
  function()
  	TFMG_thermal_gui.reload()
  end)
  script.on_event(defines.events.on_multiplayer_init, 
  function()
  	TFMG_thermal_gui.reload()
  end)

  script.on_event(defines.events.on_gui_opened,
    function(event)
      if event.gui_type == defines.gui_type.entity then
  	  	TFMG_thermal_gui.gui_open(event)
      end
    end
  )

  script.on_event(defines.events.on_gui_closed,
    function(event)
  	  if event.gui_type == defines.gui_type.entity then
  		TFMG_thermal_gui.gui_close(event)
  	  end
    end
  )


