data:extend{
  { --rotation handler for interfaces
    type = "custom-input",
    name = "interface-rotate",
    key_sequence = "",
    linked_game_control = "rotate",
    include_selected_prototype = true,
    action = "lua",
    hidden = true,
    hidden_in_factoriopedia = true
  },
  { --unrotation handler for interfaces
    type = "custom-input",
    name = "interface-rotate-reverse",
    key_sequence = "",
    linked_game_control = "reverse-rotate",
    include_selected_prototype = true,
    action = "lua",
    hidden = true,
    hidden_in_factoriopedia = true
  },
  { --flip handler for interfaces
    type = "custom-input",
    name = "interface-flip-horizontal",
    key_sequence = "",
    linked_game_control = "flip-horizontal",
    include_selected_prototype = true,
    action = "lua",
    hidden = true,
    hidden_in_factoriopedia = true
  },
  { --antiflip handler for interfaces
    type = "custom-input",
    name = "interface-flip-vertical",
    key_sequence = "",
    linked_game_control = "flip-vertical",
    include_selected_prototype = true,
    action = "lua",
    hidden = true,
    hidden_in_factoriopedia = true
  },
}