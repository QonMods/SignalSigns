data:extend({
  {
    type = "custom-input",
    name = "signalsigns-open-textbox",
    key_sequence = "F9",
    consuming = "none",
    localised_name = 'Open the SignalSigns textbox',
  }, {
    type = "shortcut",
    name = "signalsigns-open-textbox",
    action = "lua",
    toggleable = true,
    icon =
    {
      filename = "__SignalSigns__/graphics/sign3.jpg",
      priority = "extra-high-no-scale",
      size = 94,
      scale = 1,
      flags = {"icon"}
    },
    localised_name = 'Open the SignalSigns textbox'
  },
})