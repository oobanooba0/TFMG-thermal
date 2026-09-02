local number = 0 --I hate when i get red squigglies so this lol, ignore this line.


--To apply the thermal system to a building you should include in its prototype.
--Data stage Prototypes are the only thing you should need to deal with when creating thermal entites. Scripting is not required, the library can handle everything else automatically.

TFMG_thermal = {}

--the table doesn't need to contain anything, as all of its components are optional, anything not defined will fall back on default values. the existance of the table is considered an implicit opt in for the system
--there are some limitations, only "assembling-machine", "furnace", "lab", "mining-drill" and "beacon" prototypes are supported right now, other prototypes will ignore the thermal system.

--The thermal system will automatically generate the heat pipe connections, compound entites, and default properties of the system, no futher input is required.


--the complete TFMG_thermal prototype looks like this:

TFMG_thermal = {
  --Surface conditions operate just like surface conditions do for any other entity. If the surface conditions are met when the parent prototype is placed, the thermal system will apply
  --surface conditions are formatted exactly like its vanilla equivalent.
  --if surface conditions is not defined, the thermal system will apply everwhere. (default thermal system surface conditions setting coming soon)
  surface_conditions = {
    {
      property = "property-name",--this is mandatory
      min = number,--optional, defaults to 0
      max = number,--optional defaults to math.big (infinity)
    }
  },

  --Connections operate exactly like connection tables for reactor prototypes. 
  --the connection set is used to generate the heat interface prototypes (which are reactors, hence the identical set), in addition, TFMG Thermal will automatically handle the generation of rotated and mirrored varients of the prototypes.
  --if not defined, connections will default to two heat pipes per side, located on the corners of the machine. (1x1 machines only have room for one connection on each side, and naturally get 4)
  connections = {
    { position = {x, y}, direction = defines.direction.north }, --The order, direction and quantity is totally arbitrary, you are limited to 32 connections.
    { position = {x, y}, direction = defines.direction.east },
    { position = {x, y}, direction = defines.direction.south },
    { position = {x, y}, direction = defines.direction.west },
  },

  --graphics_set determines what graphics the interfaces connectors should use.
  --currently the only option is "vanilla" which uses the vanilla asthetic.
  graphics_set = "vanilla",

  --the heat ratio controls how much heat energy the building will produce. a value of 1 means 100% of the energy the machine uses is converted to heat. (While heat ratios of greater than 1 are accepted, be aware this leads to infinite energy loops)
  --Because heat energy produced is a function of the machines energy consumption. Machines that consume more energy, will also proportionately, produce more heat.
  --Idle energy consumption is *not* considered when calculating heat production. Modifiers from modules are considered.
  --default is 50%
  heat_ratio = number,

  --max working temperature controls at which temperature the machine stops crafting.
  --default is 250
  max_working_temperature = number,

  --max_safe_temperature controls the temperature at which the machine begins to take damage.
  --setting this above 1000 (which is the maximum temperature of the heat interface) will prevent the machine from ever being able to reach this temperature.
  --default is 350
  max_safe_temperature = number,

  --default temperature determines what temperature a machine is placed at
  --default setting is 15 degrees 
  default_temperature = number,

  --specific heat controls the specific heat of the machines thermal interface.
  --default value is the machines footprint * the specific heat pipe of a heat pipe. This means machines, by default, have the same thermal mass as their footprint in heat pipes.
  specific_heat = "energy-value", --Like all other energy prototypes.

  --heat when disabled by script determines weather the machine should still produce heat when disabled by script, this may be useful for compound entities like TFMGs supercomputer.
  --Note that this script still will automatically set machine status to enabled after a thermal tick. This is mostly a because I needed it more than anything.
  --default is false
  heat_when_disabled_by_script = number, --true or false.

}

--TFMG_thermal for space platform thrusters

TFMG_thermal = {
  --thrusters do not have surface conditions. They can only be placed on platforms anyway.

  --if not defined, connections will default to two heat pipes on the top side. This is because heat connections on the bottom make no sense for thrusters.
  connections = {
    { position = {x, y}, direction = defines.direction.north }, --The order, direction and quantity is totally arbitrary, you are limited to 32 connections.
    { position = {x, y}, direction = defines.direction.east },
    { position = {x, y}, direction = defines.direction.south },--south connection is nonsense, but go for it i guess.
    { position = {x, y}, direction = defines.direction.west },
  },

  --style determines what graphics the interfaces connectors should use.
  --currently the only option is "vanilla" which uses the vanilla asthetic.
  graphics_set = "vanilla",

  --default is 750
  max_working_temperature = number,
  --default is 850
  max_safe_temperature = number,
  --default setting is 15 degrees
  default_temperature = number,

  --specific heat controls the specific heat of the thrusters thermal interface.
  --default value is the thrusters footprint * the specific heat pipe of a heat pipe
  specific_heat = "energy-value", --Like all other energy prototypes.

  --heat per unit fluid determines the amount of heat energy generated per unit of fluid the thruster burns.
  --if a thruster uses 50 fuel and 50 oxidizer per second, and generates 100kJ per unit fluid, then it will output 10MW of heat energy.
  --default is "100kJ"
  heat_per_unit_fluid = "energy-value",
}


--additional notes:
  --Machine specific heat is calculated based on the footprint of the machine, A machine has a heat capacity equivilent to the same amount of space in heat pipes. or 1MJ per tile.
  --This means larger machines will take longer to heat up, as they have a larger thermal mass.

--This mod already includes a pre prepared ground radiator in prototypes.prototypes.lua, by default it is set to hidden and disabled, meaning it won't show up in the game. If you wish to use it, as is, simply enable it and give it a recipe. 
--else all the graphics and textures are free for your reuse as desired.