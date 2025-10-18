local thermal_system_gui = {}

---currently using the old sketchy gui system as its better than nothing when it comes to debug.

local function gui_anchor(entity)--Gets the corrosponding anchor for the entities gui type.
	if entity.type == "furnace" then
		anchor = {gui=defines.relative_gui_type.furnace_gui, position=defines.relative_gui_position.bottom}
	elseif entity.type== "assembling-machine" then
		anchor = {gui=defines.relative_gui_type.assembling_machine_gui, position=defines.relative_gui_position.bottom}
	elseif entity.type== "lab" then
		anchor = {gui=defines.relative_gui_type.lab_gui, position=defines.relative_gui_position.bottom}
  elseif entity.type == "beacon" then
    anchor = {gui=defines.relative_gui_type.beacon_gui, position=defines.relative_gui_position.bottom}
	else
		anchor = nil
	end
return anchor end

local function collect_interface_entry(machine,player_storage)--will gather the relevant information about the entry, and store it in the the table
  player_storage.gui = {}
  local gui_storage = player_storage.gui

  if storage.interfaces[machine.name] == nil then
    gui_storage = nil
  else
    local thermal_prototype = prototypes.mod_data["TFMG-thermal-"..machine.name].data
    gui_storage.gui_interface = storage.interfaces[machine.name][machine.unit_number]
    gui_storage.max_safe_temperature = thermal_prototype.max_safe_temperature
	  gui_storage.max_working_temperature =  thermal_prototype.max_working_temperature
	  gui_storage.heat_ratio =	thermal_prototype.heat_ratio --as fraction of 1
	  gui_storage.base_heat_output = thermal_prototype.base_heat_output --in W
  end
return gui_storage end

function thermal_system_gui.on_player_join(event)
  local player = game.players[event.player_index]
	storage.players[player.index] = {}--initialise player storage
end

function thermal_system_gui.gui_open(event)
	
  local machine = event.entity
  if prototypes.mod_data["TFMG-thermal-"..machine.name] == nil then return end --first check, make sure this is a thermal entity.
	local player_storage = storage.players[event.player_index]
  gui_storage = collect_interface_entry(machine,player_storage)--Now we can find the interface entry. and by extention, the interface. 
	if gui_storage == nil then return end --if theres no interface. we can call quits.

	local anchor = gui_anchor(machine)
  if anchor == nil then return end

  local player = game.players[event.player_index]
  local frame = player.gui.relative.add{type="frame", anchor=anchor,direction="vertical"}
	gui_storage.gui = frame
	frame.add{type="flow",name = "1"}
	frame["1"].add{type = "label", name = "temperature-reading"}
	frame["1"].add{type = "progressbar", name = "heat-bar"}
	frame["1"].add{type = "progressbar", name = "heat-bar2"}
	frame.add{type = "label", name = "heating"}
	frame.add{type = "label", name = "working"}
	frame.add{type = "label", name = "damage"}


end

function thermal_system_gui.gui_close(event)
  local gui_storage = storage.players[event.player_index].gui
  if gui_storage == nil then return end
	if gui_storage.gui == nil then return end
	if gui_storage.gui.valid == false then return end
	gui_storage.gui.destroy()
	gui_storage = nil
end

function thermal_system_gui.gui_cleanup(event)
	local players = game.connected_players
	for _ , v in pairs(players) do
		local gui_storage = storage.players[v.index].gui
		if gui_storage ~= nil and gui_storage.gui ~= nil and gui_storage.gui.valid == true and gui_storage.gui_interface ~= nil and gui_storage.gui_interface.interface.valid == false then
			gui_storage.gui.destroy()
			gui_storage = nil
		end
	end
end

function thermal_system_gui.on_gui_tick()
	local players = game.connected_players
  for _ , v in pairs(players) do
		local gui_storage = storage.players[v.index].gui
		if gui_storage ~= nil and gui_storage.gui ~= nil and gui_storage.gui.valid == true and gui_storage.gui_interface ~= nil and gui_storage.gui_interface.interface.valid == true then --holy stack batman
			local interface = gui_storage.gui_interface
			local max_working_temperature = gui_storage.max_working_temperature
			local max_safe_temperature = gui_storage.max_safe_temperature
			local temperature = interface.interface.temperature
			local energy_multiplier = interface.machine.consumption_bonus + 1
			local heat_output = (gui_storage.base_heat_output * energy_multiplier)/1000000

			gui_storage.gui["1"]["temperature-reading"].caption = "Temperature: "..string.format("%.2f",temperature).."°C"
			gui_storage.gui["1"]["heat-bar"].value = temperature/max_working_temperature
			gui_storage.gui["1"]["heat-bar2"].value = (temperature-max_working_temperature)/(max_safe_temperature-max_working_temperature)
			gui_storage.gui["heating"].caption = "Heat output: "..string.format("%.2f",heat_output).."MW"
			gui_storage.gui["working"].caption = "Maximum working temperature: "..max_working_temperature.."°C"
			gui_storage.gui["damage"].caption = "Maximum safe temperature: "..max_safe_temperature.."°C"
		end
	end
end



return thermal_system_gui