The thermal system for TFMG.

--Main mod--

[TFMG](https://github.com/oobanooba0/TFMG)

What does TFMG thermal do?

TFMG thermal is a library for adding heat-based mechanics to Factorio. Something which isn't really supported by the base game (And is, by extension, a royal pain in the ass to actually implement) but conceptually has a lot of potential.

The main gist of the thermal system is that it allows machines to produce excess waste heat as they work. This causes them to heat up, and if they get too hot, they'll stop working. Even hotter, and they might take damage.
The player must use heat pipes and the connections provided on the machines to remove this excess heat and keep their factory running.
The addition of heat pipes, radiators and various heat control systems can add a lot of interesting spaghetti potential to whichever mods decide to use it.

Take a look at these mods to see the thermal system in action:
[TFMG](https://mods.factorio.com/mod/TFMG)
[Thermal Expansion Vanilla](https://mods.factorio.com/mod/thermal-expansion-vanilla)




How to use TFMG thermal in your mod:

[Detailed Explanation of TFMG_thermal in templates.lua](https://github.com/oobanooba0/TFMG-thermal/blob/main/templates.lua)

TFMG thermal has been designed to be easy to use and intuitive. I handle all the annoying scripting, blueprinting, GUI and compound entity business. So you can focus on how your mechanics play.

All interaction with TFMG thermal is done in your prototypes. The process is similar to defining a fluid box or heat energy source.

To start with, the bare minimum requirement for the thermal system to be applied to a machine is:

```TFMG_thermal = {}```

Without anything defined within this table, TFMG Thermal will detect the existence of the table during data-updates, and treat it as an implied opt-in

Within it, you can define various properties:

```
TFMG_thermal = {
  max_working_temperature = number,
  max_safe_temperature = number,
  heat_ratio = number,
  connections = {
    { position = {x, y}, direction = defines.direction.north },
    { position = {x, y}, direction = defines.direction.east },
    { position = {x, y}, direction = defines.direction.south },
    { position = {x, y}, direction = defines.direction.west },
  }
},
surface_conditions = {
  {
    property = "property-name",
    min = number,
    max = number
  }
},
```

When any of these properties are not defined, as in the original example (`TFMG_thermal = {}`), they are automatically populated by a default value.

For more details into how to use TFMG_thermal, look into [templates.lua](https://github.com/oobanooba0/TFMG-thermal/blob/main/templates.lua)
