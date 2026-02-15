local TFMG_thermal_util = {}

  function TFMG_thermal_util.surface_condition_compare(surface,conditions)--conditions should be as table
    if conditions == nil then return true end
      for _ , condition in pairs(conditions) do
        local surface_condition_value = surface.get_property(prototypes.surface_property[condition.property])
        if condition.min > surface_condition_value or surface_condition_value > condition.max then return false end
      end
  return true end

return TFMG_thermal_util