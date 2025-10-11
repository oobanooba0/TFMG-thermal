local function refresh_storage()
end

script.on_init(function()
  refresh_storage()
end)

script.on_configuration_changed(function()
  refresh_storage()
end)

script.on_event(
	defines.events.on_built_entity,
	function(event)
  local machine = prototypes.mod_data["TFMG-thermal-steel-furnace"]
      game.print(serpent.block(machine.name)..serpent.block(machine.data))
	end
)

