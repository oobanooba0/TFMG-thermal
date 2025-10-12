local function build_thermal_entity_list()--Create a list of all buildings with thermal interfaces associated with them
  storage.thermal_entity_list = {}
  for name , machine in pairs(prototypes.mod_data) do
    if machine.data_type == "TFMG-thermal.thermal-interface" then
      table.insert(storage.thermal_entity_list,{machine.data.name})
    end
  end
end

script.on_init(function()
  build_thermal_entity_list()
end)

script.on_configuration_changed(function()
  build_thermal_entity_list()
end)

script.on_event(
	defines.events.on_built_entity,function()
    --game.print(serpent.block(storage.thermal_entity_list))
    --game.print(serpent.block(prototypes.mod_data["TFMG-thermal-assembling-machine-1"].data))
	end
)

