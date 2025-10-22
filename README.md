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
[Thermal-Expansion-Vanilla](https://mods.factorio.com/mod/TFMG](https://mods.factorio.com/mod/thermal-expansion-vanilla)




How to use TFMG thermal in your mod:

TFMG thermal has been designed to be easy to use and intuitive. I handle all the annoying scripting, blueprinting, GUI and compound entity business. So you can focus on how your mechanics play.

All interaction with TFMG thermal is done in your prototypes. The process is similar to defining a fluid box or heat energy source.

To start with, the bare minimum requirement for the thermal system to be applied to a machine is:

TFMG_thermal = {}

The table doesn't need to contain anything, as all of its components are optional; anything not defined will fall back on default values. The existence of the table is considered an implicit opt-in for the system
There are some limitations; only "assembling-machine", "furnace", "lab", "mining-drill" and "beacon" prototypes are supported right now, other prototypes will ignore the thermal system.
