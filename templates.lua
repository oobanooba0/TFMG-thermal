--To apply the thermal system to a building you should include in its prototype.
--Data stage Prototypes are the only thing you should need to deal with when creating thermal entites. Scripting is not required, the library can handle everything else automatically.

thermal_system = {}

--the table doesn't need to contain anything, as all of its components are optional, anything not defined will fall back on default values. the existance of the table is considered an implicit opt in for the system
--there are some limitations, only "assembling-machine", "furnace", "lab", "mining-drill" and "beacon" prototypes are supported right now, other prototypes will ignore the thermal system.

--The thermal system will automatically generate the heat pipe connections, compound entites, and default properties of the system, no futher input is required.


--the complete thermal system prototype looks like this

thermal_system = {
  --Surface conditions operate just like surface conditions do for any other entity. If the surface conditions are met when the parent prototype is placed, the thermal system will apply
  --surface conditions are formatted exactly like its vanilla equivalent.
  --if surface conditions is not defined, the thermal system will apply everwhere. (default thermal system surface conditions setting coming soon)
  surface_conditions = {
    {
      property = "property-name",
      max = number,
      min = number,
    }
  },

  --Connections operate exactly like connection tables for reactor prototypes. 
  --the connection set is used to generate the heat interface prototypes (which are reactors, hence the identical set), in addition, TFMG Thermal will automatically handle the generation of rotated and mirrored varients of the prototypes.
  --if not defined, connections will default to two heat pipes per side, located on the corners of the machine. (1x1 machines only have room for one connection on each side, and naturally get 4)
  connections = {
    { position = {x, y}, direction = defines.direction.north },
    { position = {x, y}, direction = defines.direction.east },
    { position = {x, y}, direction = defines.direction.south },
    { position = {x, y}, direction = defines.direction.west },
  },
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
  --default setting is 10 degrees less than the max working temperature of the machine, or 240 degrees if max working temperature isn't defined.
  default_temperature = number,

}

--additional notes:
  --Machine specific heat is calculated based on the footprint of the machine, A machine has a heat capacity equivilent to the same amount of space in heat pipes. or 1MJ per tile.
  --This means larger machines will take longer to heat up, they have a larger thermal mass.

--limitations
  --Machines that do not rotate wont have rotatable thermal interfaces. (I am trying to solve this, but its a very complicated problem)