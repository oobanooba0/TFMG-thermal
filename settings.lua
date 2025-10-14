local default_config = "vanilla"
if mods["space-age"] then default_config = "space-age" end

data:extend({
  {--None is your goto if you want to define everything manually
    type = "string-setting",
    name = "use-config",
    setting_type = "startup",
    default_value = default_config,
    allowed_values = {default_config},
    --hidden = true
  }
})

