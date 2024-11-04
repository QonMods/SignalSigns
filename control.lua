require 'mod-gui'
local mod_gui = require("mod-gui")
local add = require('math3d').vector2.add

local HOTKEY_EVENT_NAME = 'signalsigns-open-textbox'
local SHORTCUT_NAME = 'signalsigns-open-textbox'

local SPACE_SIGNAL = 'signal-black'
local DOT_SIGNAL = 'signal-dot'

function string:split2(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]*)%s?", sep, sep)
   local selfsep = self..sep
   selfsep:gsub(pattern, function(c) fields[#fields+1] = c end)
   table.remove(fields)
   return fields
end

function letter_to_signal(c)
    if c == nil or c == ' ' or c == '\n' then return SPACE_SIGNAL end
    if c == '_' then return 'signal-blue' end
    if c == '-' or c == "'" or c:match('^[\\.\\,]$') then return DOT_SIGNAL end
    if c:match('^[a-zA-Z0-9]$') then return 'signal-'..c:upper() end
    return SPACE_SIGNAL
end

function entities_from_string(s)
    local lines = s:split2('\n')

    local lines_a = {}
    local longest_line = 0
    for i, line in ipairs(lines) do
        longest_line = math.max(longest_line, #line)

        table.insert(lines_a, {})
        for j = 1, #line do
            local c = line:sub(j, j)
            table.insert(lines_a[i], c)
        end
    end

    local position = {0, 0}
    local chars = {}
    for i = 1, #s do
        local c = s:sub(i, i)
        table.insert(chars, c)
    end
    local a = {}

    local hstep = math.min(#lines, 2)
    local wstep = 2
    local entity_number = 1
    local i = 1
    while i <= #lines do
        local longer_line = i == 1 and wstep or 0
        for ud = 0, hstep - 1 do
            longer_line = math.max(longer_line, #(lines[i + ud] or ''))
        end

        for ci = 1, longer_line, wstep do
            local filters = {}
            for ud = 0, hstep - 1 do
                for lr = 0, wstep - 1 do
                    local c = letter_to_signal((lines_a[i + ud] or {})[ci + lr])
                    if c ~= SPACE_SIGNAL or wstep == 2 or hstep == 2 then
                        table.insert(filters, {
                            index = 1 + lr + ud * 6,
                            count = 1,
                            signal = {
                                name = c,
                                type = 'virtual',
                            },
                        })
                    end
                end
            end
            if #filters > 0 then
                local entity = {
                    entity_number = entity_number,
                    name = 'constant-combinator',
                    position = add(position, {math.floor((ci - 1) / wstep), 0}),
                    control_behavior = {filters = filters},
                }
                table.insert(a, entity)
                entity_number = entity_number + 1
            end
        end

        position = add(position, {0, 1})
        position[1] = 0
        i = i + wstep
    end
    return a
end

function set_cursor(player, entities, text, textbox_index)
    if player.cursor_stack.is_blueprint and player.cursor_stack.get_blueprint_entity_tag(1, 'SignalSign-textbox_index') == textbox_index then player.cursor_stack.clear() end
    if player.clear_cursor() then
        player.cursor_stack.set_stack({name = 'blueprint'})
        player.cursor_stack.set_blueprint_entities(entities)
        player.cursor_stack.set_blueprint_entity_tag(1, 'SignalSign-textbox_index', textbox_index)
        -- player.cursor_stack.custom_description = text
    end
end

function open_textbox(event)
    if event.input_name ~= HOTKEY_EVENT_NAME and event.prototype_name ~= SHORTCUT_NAME then return end

    local player = game.players[event.player_index]
    local popup = player.gui.center[script.mod_name..'-popup-container']
    if popup ~= nil then
        popup.destroy()
        return
    else
        popup = player.gui.center.add{name = script.mod_name..'-popup-container', type = 'frame', direction = 'vertical', caption = 'Signal Signs'}
        popup.add{type = 'label', caption = 'Multiline text possible.'}
        popup.add{type = 'label', caption = 'Letters and numbers work as expected.'}
        popup.add{type = 'label', caption = '.,-\' becomes a dot. _ becomes a blue square.'}
        popup.add{type = 'label', caption = 'Everything else becomes a black square.'}
        popup.add{name = script.mod_name..'-text-box', type = 'text-box'}
        popup.add{name = script.mod_name..'-close', type = 'button', caption = 'Close', style = mod_gui.button_style}
    end
end

function on_gui_event(event)
    -- element :: LuaGuiElement: The clicked element.
    -- player_index :: uint: The player who did the clicking.
    -- button :: defines.mouse_button_type: The mouse button used if any.
    -- alt :: boolean: If alt was pressed.
    -- control :: boolean: If control was pressed.
    -- shift :: boolean: If shift was pressed.

    local player = game.players[event.player_index]
    local popup = player.gui.center[script.mod_name..'-popup-container']
    if event.name == defines.events.on_gui_click and event.element.name == script.mod_name..'-close' then
        popup.destroy()
        return
    end

    if popup and event.element.name == script.mod_name..'-text-box' then
        local textbox = popup[script.mod_name..'-text-box']
        local text = textbox.text
        set_cursor(player, entities_from_string(text), text, textbox.index)
    end
end

script.on_event(defines.events.on_gui_text_changed, on_gui_event)
script.on_event(defines.events.on_gui_click, on_gui_event)

script.on_event(defines.events.on_lua_shortcut, open_textbox)
script.on_event(HOTKEY_EVENT_NAME, open_textbox)