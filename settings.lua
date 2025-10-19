data:extend({
    {
        type = "int-setting",
        name = "update-quota",
        setting_type = "runtime-global",
        minimum_value = 1,--Rip bozo if they set it to 1.
        default_value = 5000,
    },
})