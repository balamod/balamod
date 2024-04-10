local game_love_draw = love.draw
local game_love_update = love.update
local game_love_keypressed = love.keypressed
local game_love_keyreleased = love.keyreleased
local game_love_mousepressed = love.mousepressed
local game_love_mousereleased = love.mousereleased
local game_love_mousemoved = love.mousemoved
local game_love_wheelmoved = love.wheelmoved
local game_love_textinput = love.textinput
local game_love_resize = love.resize
local game_love_quit = love.quit
local game_love_load = love.load
local game_love_gamepad_pressed = love.gamepadpressed
local game_love_gamepad_released = love.gamepadreleased
local game_love_joystick_axis = love.joystickaxis
local game_love_errhand = love.errhand
local game_set_render_settings = G.set_render_settings
local card_set_sprites = Card.set_sprites
local card_calculate_dollar_bonus = Card.calculate_dollar_bonus
local card_add_to_deck = Card.add_to_deck
local card_remove_from_deck = Card.remove_from_deck

local balamod = require("balamod")
local logging = require('logging')
local utils = require('utils')
local logger = logging.getLogger('patches')
local assets = require('assets')
local joker = require('joker')
local consumable = require('consumable')

function love.load(args)
    for modId, mod in pairs(balamod.mods) do
        if mod.on_game_load then
            local status, message = pcall(mod.on_game_load, args)
            if not status then
                logger:warn("Loading mod ", mod.id, "failed: ", message)
            end
        end
    end
    if game_love_load then
        game_love_load(args)
    end
end

function love.quit()
    for modId, mod in pairs(balamod.mods) do
        if mod.on_game_quit then
            local status, message = pcall(mod.on_game_quit)
            if not status then
                logger:warn("Quitting mod ", mod.id, "failed: ", message)
            end
        end
    end
    if game_love_quit then
        game_love_quit()
    end
end

function love.update(dt)
    local cancel_update = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_pre_update then
            local status, message = pcall(mod.on_pre_update, dt)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Pre-updating mod ", mod.id, "failed: ", message)
            end
        end
    end

    if cancel_update then
        return
    end

    if game_love_update then
        game_love_update(dt)
    end

    if balamod.is_loaded == false then
        balamod.is_loaded = true
        for modId, mod in pairs(balamod.mods) do
            -- Load all mods after eveything else
            if mod.enabled and mod.on_enable and type(mod.on_enable) == "function" then
                local ok, message = pcall(mod.on_enable) -- Call the on_enable function of the mod if it exists
                if not ok then
                    logger:warn("Enabling mod ", mod.id, "failed: ", message)
                end
            end
        end
    end

    for modId, mod in pairs(balamod.mods) do
        if mod.on_post_update then
            local status, message = pcall(mod.on_post_update, dt)
            if not status then
                logger:warn("Post-updating mod ", mod.id, "failed: ", message)
            end
        end
    end
end

function love.draw()
    for modId, mod in pairs(balamod.mods) do
        if mod.on_pre_render then
            local status, message = pcall(mod.on_pre_render)
            if not status then
                logger:warn("Pre-rendering mod ", mod.id, "failed: ", message)
            end
        end
    end

    if game_love_draw then
        game_love_draw()
    end

    for modId, mod in pairs(balamod.mods) do
        if mod.on_post_render then
            local status, message = pcall(mod.on_post_render)
            if not status then
                logger:warn("Post-rendering mod ", mod.id, "failed: ", message)
            end
        end
    end

end

function love.keypressed(key)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_key_pressed then
            local status, message = pcall(mod.on_key_pressed, key)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Key pressed event for mod ", mod.id, "failed: ", message)
            end
        end
    end

    if cancel_event then
        return
    end

    if game_love_keypressed then
        game_love_keypressed(key)
    end
end

function love.keyreleased(key)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_key_released then
            local status, message = pcall(mod.on_key_released, key)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Key released event for mod ", mod.id, "failed: ", message)
            end
        end
    end

    if cancel_event then
        return
    end

    if game_love_keyreleased then
        game_love_keyreleased(key)
    end
end

function love.gamepadpressed(joystick, button)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_gamepad_pressed then
            local status, message = pcall(mod.on_gamepad_pressed, joystick, button)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Gamepad pressed event for mod ", modId, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_gamepad_pressed then
        game_love_gamepad_pressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_gamepad_pressed then
            local status, message = pcall(mod.on_gamepad_released, joystick, button)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Gamepad released event for mod ", modId, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_gamepad_released then
        game_love_gamepad_released(joystick, button)
    end
end

function love.mousepressed(x, y, button, touch)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_mouse_pressed then
            local status, message = pcall(mod.on_mouse_pressed, x, y, button, touch)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Mouse pressed event for mod ", mod.id, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_mousepressed then
        game_love_mousepressed(x, y, button, touch)
    end
end

function love.mousereleased(x, y, button)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_mouse_released then
            local status, message = pcall(mod.on_mouse_released, x, y, button)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Mouse released event for mod ", mod.id, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_mousereleased then
        game_love_mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_mouse_moved then
            local status, message = pcall(mod.on_mouse_moved, x, y, dx, dy, istouch)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Mouse moved event for mod ", mod.id, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_mousemoved then
        game_love_mousemoved(x, y, dx, dy, istouch)
    end
end

function love.joystickaxis(joystick, axis, value)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_mouse_released then
            local status, message = pcall(mod.on_joystick_axis, joystick, axis, value)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Joystick axis event for mod ", mod.id, "failed: ", message)
            end
        end
    end
    if cancel_event then
        return
    end

    if game_love_joystick_axis then
        game_love_joystick_axis(joystick, axis, value)
    end
end

function love.errhand(msg)
    for modId, mod in pairs(balamod.mods) do
        if mod.on_error then
            local status, message = pcall(mod.on_error, msg)
            if not status then
                logger:warn("Error event for mod ", mod.id, "failed: ", message)
            end
        end
    end

    if game_love_errhand then
        game_love_errhand(msg)
    end
end

function love.wheelmoved(x, y)
    local cancel_event = false
    for modId, mod in pairs(balamod.mods) do
        if mod.on_mousewheel then
            local status, message = pcall(mod.on_mousewheel, x, y)
            if status then
                if message then
                    cancel_update = true
                end
            else
                logger:warn("Mouse wheel event for mod ", mod.id, "failed: ", message)
            end
        end
        if cancel_event then
            return
        end
    end

    if game_love_wheelmoved then
        game_love_wheelmoved(x, y)
    end
end

local game_calculate_joker = Card.calculate_joker

function Card.calculate_joker(self, context)
    local old_return = game_calculate_joker(self, context)
    if self.ability.set == "Joker" and not self.debuff then
        for _, effect in pairs(joker.calculateJokerEffects) do
            local status, new_return = pcall(effect, self, context)
            if new_return then 
                return new_return
            end 
        end
    end
    return old_return
end

local game_generate_uibox_ability_table = Card.generate_UIBox_ability_table

function Card:generate_UIBox_ability_table()
    if self.config.center.balamod then
        if not self.bypass_lock and self.config.center.unlocked ~= false and
        (self.ability.set == 'Joker' or self.ability.set == 'Edition' or self.ability.consumeable or self.ability.set == 'Voucher' or self.ability.set == 'Booster') and
        not self.config.center.discovered and 
        ((self.area ~= G.jokers and self.area ~= G.consumeables and self.area) or not self.area) then
            return game_generate_uibox_ability_table(self)
        elseif not self.config.center.unlocked and not self.bypass_lock then
            return game_generate_uibox_ability_table(self)
        elseif not self.config.center.discovered and not self.bypass_discovery_ui then
            return game_generate_uibox_ability_table(self)
        elseif self.debuff then
            return game_generate_uibox_ability_table(self)
        elseif card_type == 'Default' or card_type == 'Enhanced' then
            return game_generate_uibox_ability_table(self)
        elseif self.ability.set == 'Joker' or consumable.isConsumeableSet(self.ability.set) then
            local card_type = self.ability.set or "None"
            local hide_desc = nil
            local loc_vars = nil
            local main_start, main_end = nil, nil
            local no_badge = nil
            local loc_loc_vars = joker.loc_vars[self.config.center.balamod.key] or consumable.loc_vars[self.config.center.balamod.key]
            loc_vars = loc_loc_vars(self)
            logger:debug(loc_vars)
            local badges = {}

            if (card_type ~= 'Locked' and card_type ~= 'Undiscovered' and card_type ~= 'Default') or self.debuff then
                badges.card_type = card_type
            end

            if self.ability.set == 'Joker' and self.bypass_discovery_ui and (not no_badge) then
                badges.force_rarity = true
            end

            if self.edition then
                if self.edition.type == 'negative' and self.ability.consumeable then
                    badges[#badges + 1] = 'negative_consumable'
                else
                    badges[#badges + 1] = (self.edition.type == 'holo' and 'holographic' or self.edition.type)
                end
            end
            if self.seal then badges[#badges + 1] = string.lower(self.seal)..'_seal' end
            if self.ability.eternal then badges[#badges + 1] = 'eternal' end
            if self.pinned then badges[#badges + 1] = 'pinned_left' end
        
            if self.sticker then loc_vars = loc_vars or {}; loc_vars.sticker=self.sticker end
        
            return generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
        end
    end
    return game_generate_uibox_ability_table(self)
end
local game_create_UIBox_main_menu_buttons = create_UIBox_main_menu_buttons

function create_UIBox_main_menu_buttons()
    local t = game_create_UIBox_main_menu_buttons()
    local modBtn = {
        n = G.UIT.R,
        config = {
            align = "cm",
            padding = 0.2,
            r = 0.1,
            emboss = 0.1,
            colour = G.C.L_BLACK,
        },
        nodes = {
            {
                n = G.UIT.R,
                config = {
                    align = "cm",
                    padding = 0.15,
                    minw = 1,
                    r = 0.1,
                    hover = true,
                    colour = G.C.PURPLE,
                    button = 'show_mods',
                    shadow = true,
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "MODS",
                            scale = 0.6,
                            colour = G.C.UI.TEXT_LIGHT,
                            shadow = true,
                        },
                    },
                },
            },
        },
    }

    local insertIndex = #t.nodes[2].nodes
    if not G.F_ENGLISH_ONLY then
        insertIndex = insertIndex - 1
    end
    table.insert(t.nodes[2].nodes, insertIndex, modBtn)
    return t
end

local modFolders = love.filesystem.getDirectoryItems("mods") -- Load all mods
logger:info("Loading mods from folders ", modFolders)
for _, modFolder in ipairs(modFolders) do
    local mod = balamod.loadMod(modFolder)
    if mod ~= nil then
        balamod.mods[mod.id] = mod
        logger:info("Loaded mod: ", mod.id)
    end
end

logger:info("Mods: ", utils.map(mods, function(mod)
    return mod.id
end))

for _, mod in ipairs(balamod.mods) do
    if mod.enabled and mod.on_pre_load and type(mod.on_pre_load) == "function" then
        local status, message = pcall(mod.on_pre_load) -- Call the on_pre_load function of the mod if it exists
        if not status then
            logger:warn("Pre-loading mod ", mod.id, "failed: ", message)
        end
    end
end

function Game.set_render_settings(self)
    game_set_render_settings(self)
    for modId, mod in pairs(balamod.mods) do
        local atli = assets.getAtli(mod.id, self.SETTINGS.GRAPHICS.texture_scaling)
        if atli and type(atli) == 'table' then
            if atli.asset and type(atli.asset) == 'table' then
                for _, atlas in ipairs(atli.asset) do
                    self.ASSET_ATLAS[atlas.name] = {}
                    self.ASSET_ATLAS[atlas.name].name = atlas.name
                    self.ASSET_ATLAS[atlas.name].image = atlas.image
                    self.ASSET_ATLAS[atlas.name].px = atlas.px
                    self.ASSET_ATLAS[atlas.name].py = atlas.py
                    self.ASSET_ATLAS[atlas.name].type = atlas.type
                end
            end
            if atli.animation and type(atli.animation) == 'table' then
                for _, atlas in ipairs(atli.animation) do
                    self.ANIMATION_ATLAS[atlas.name] = {}
                    self.ANIMATION_ATLAS[atlas.name].name = atlas.name
                    self.ANIMATION_ATLAS[atlas.name].image = atlas.image
                    self.ANIMATION_ATLAS[atlas.name].px = atlas.px
                    self.ANIMATION_ATLAS[atlas.name].py = atlas.py
                    self.ANIMATION_ATLAS[atlas.name].frames = atlas.frames
                end
            end
        end
    end
end

function Card.set_sprites(self, _center, _front)
    if _center and _center.balamod then
        -- we have a center, and it's custom from the balamod hook
        if _center.set then
            -- if we already have a center, we need to update it
            -- the default game function takes in the set as the key in the asset atlas
            -- but for custom stuff, we need the custom asset instead
            if self.children.center then
                self.children.center.atlas = G.ASSET_ATLAS[_center.balamod.asset_key]
                -- custom assets are single images, their pos is always 0,0
                self.children.center:set_sprite_pos({ x = 0, y = 0 })
            else
                -- We process the asset with the normal function
                -- this is done to keep the default behavior of the game
                -- we'll patvh the sprite afterwards, but in the meantime it
                -- allows us to keep the locker/undiscovered logic
                card_set_sprites(self, _center, _front)
                -- the sprite has been initialized, check that the center is unlocked
                -- if the center is locked, or not discovered yet, we don't want to
                -- use the custom asset (it should show the game images for locked/undiscovered)
                -- cards. Bypass discovery center though should still bypass that check
                if (_center.unlocked and self.config.center.unlocked and _center.discovered) or self.params.bypass_discovery_center then
                    -- center has been unlocked, so we can use our custom atlas
                    -- as before, pos is always 0,0 becaue we have a single image
                    -- per atlas.
                    self.children.center.atlas = G.ASSET_ATLAS[_center.balamod.asset_key]
                    self.children.center:set_sprite_pos({ x = 0, y = 0 })
                end
                -- Get the 'back' instance we need from the selected deck
                local back = G.GAME[self.back]
                local back_center = back.effect.center
                if not self.params.bypass_back then
                    -- only do that when there is no bypass of the back enabled
                    if self.playing_card and back_center.balamod then
                        -- this sprite is a playing card,
                        -- the game sets the card back as G.GAME[self.back].pos
                        -- we need to set it to the custom asset instead
                        -- from our back atlases
                        -- it's a custom deck as well (because the back center has a balamod table)
                        self.children.back.atlas = G.ASSET_ATLAS[back_center.balamod.asset_key]
                        self.children.back:set_sprite_pos({ x = 0, y = 0 })
                    else
                        -- it's not a playing card, so the game just sets
                        -- it to the red deck back
                        -- we replicate that behavior here
                        self.children.back.atlas = G.ASSET_ATLAS['centers']
                        -- card backs are in the centers atlas for some reason
                        self.children.back:set_sprite_pos(G.P_CENTERS['b_red'].pos)
                    end
                end
            end
        end
    else
        -- no center specified, just use the base function from the game
        card_set_sprites(self, _center, _front)
    end
end

function Card:calculate_dollar_bonus()
    local old_return = card_calculate_dollar_bonus(self)
    if not self.debuff and self.ability.set == "Joker" then
        for _, effect in pairs(joker.dollarBonusEffects) do
            local status, new_return = pcall(effect, self)
            if new_return then 
                return new_return
            end 
        end
    end
    return old_return
end

function Card:add_to_deck(from_debuff)
    local old_return = card_add_to_deck(self, from_debuff)
    for _, effect in pairs(joker.addToDeckEffects) do
        local status, new_return = pcall(effect, self, from_debuff)
        if new_return then
            return new_return
        end
    end
    return old_return
end

function Card:remove_from_deck(from_debuff)
    local old_return = card_remove_from_deck(self, from_debuff)
    for _, effect in pairs(joker.removeFromDeckEffects) do
        local status, new_return = pcall(effect, self, from_debuff)
        if new_return then
            return new_return
        end
    end
    return old_return
end

local card_can_use_consumeable = Card.can_use_consumeable
function Card:can_use_consumeable(any_state, skip_check)
    local old_return = card_can_use_consumeable(self, any_state, skip_check)
    if not skip_check and ((G.play and #G.play.cards > 0) or
        (G.CONTROLLER.locked) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
        then  
        return false 
    end
    if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or any_state then
        for _, condition in pairs(consumable.useConditions) do
            local status, new_return = pcall(condition, self, any_state, skip_check)
            if new_return then
                return new_return
            end
        end
    end
    return old_return
end

local card_use_consumeable = Card.use_consumeable
function Card:use_consumeable(area, copier)
    local old_return = card_use_consumeable(self, area, copier)
    for _, effect in pairs(consumable.useEffects) do
        local status, new_return = pcall(condition, self, area, copier)
        if new_return then
            return new_return
        end
    end
end

function create_UIBox_your_collection_tarots()
    local deck_tables = {}
  
    G.your_collection = {}
    for j = 1, 2 do
        G.your_collection[j] = CardArea(
            G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
            (4.25+j)*G.CARD_W,
            1*G.CARD_H, 
            {card_limit = 4 + j, type = 'title', highlight_limit = 0, collection = true}
        )
        table.insert(deck_tables, 
            {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
                {n=G.UIT.O, config={object = G.your_collection[j]}}
            }}
        )
    end
  
    local tarot_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Tarot/11) do
        table.insert(tarot_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Tarot/11)))
    end
  
    for j = 1, #G.your_collection do
        for i = 1, 4+j do
            local center = G.P_CENTER_POOLS["Tarot"][i+(j-1)*(5)]
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, nil, center)
            card:start_materialize(nil, i>1 or j>1)
            G.your_collection[j]:emplace(card)
        end
    end
  
    INIT_COLLECTION_CARD_ALERTS()
    
    local t = create_UIBox_generic_options({ back_func = 'your_collection', contents = {
        {n=G.UIT.R, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables},
            {n=G.UIT.R, config={align = "cm"}, nodes={
                create_option_cycle({options = tarot_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_tarot_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
            }}
        }})
    return t
end

local misc_generate_card_ui = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    if _c.set == "Tarot" then
        local first_pass = nil
        if not full_UI_table then 
            first_pass = true
            full_UI_table = {
                main = {},
                info = {},
                type = {},
                name = nil,
                badges = badges or {}
            }
        end

        local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
        local name_override = nil
        local info_queue = {}

        if full_UI_table.name then
            full_UI_table.info[#full_UI_table.info+1] = {}
            desc_nodes = full_UI_table.info[#full_UI_table.info]
        end

        if not full_UI_table.name then
            if specific_vars and specific_vars.no_name then
                full_UI_table.name = true
            elseif card_type == 'Locked' then
                full_UI_table.name = localize{type = 'name', set = 'Other', key = 'locked', nodes = {}}
            elseif card_type == 'Undiscovered' then 
                full_UI_table.name = localize{type = 'name', set = 'Other', key = 'undiscovered_'..(string.lower(_c.set)), name_nodes = {}}
            elseif specific_vars and (card_type == 'Default' or card_type == 'Enhanced') then
                if (_c.name == 'Stone Card') then full_UI_table.name = true end
                if (specific_vars.playing_card and (_c.name ~= 'Stone Card')) then
                    full_UI_table.name = {}
                    localize{type = 'other', key = 'playing_card', set = 'Other', nodes = full_UI_table.name, vars = {localize(specific_vars.value, 'ranks'), localize(specific_vars.suit, 'suits_plural'), colours = {specific_vars.colour}}}
                    full_UI_table.name = full_UI_table.name[1]
                end
            elseif card_type == 'Booster' then
                
            else
                full_UI_table.name = localize{type = 'name', set = _c.set, key = _c.key, nodes = full_UI_table.name}
            end
            full_UI_table.card_type = card_type or _c.set
        end 

        local loc_vars = {}
        if main_start then 
            desc_nodes[#desc_nodes+1] = main_start 
        end

    
        if _c.name == "The Fool" then
            local fool_c = G.GAME.last_tarot_planet and G.P_CENTERS[G.GAME.last_tarot_planet] or nil
            local last_tarot_planet = fool_c and localize{type = 'name_text', key = fool_c.key, set = fool_c.set} or localize('k_none')
            local colour = (not fool_c or fool_c.name == 'The Fool') and G.C.RED or G.C.GREEN
            main_end = {
                {n=G.UIT.C, config={align = "bm", padding = 0.02}, nodes={
                    {n=G.UIT.C, config={align = "m", colour = colour, r = 0.05, padding = 0.05}, nodes={
                        {n=G.UIT.T, config={text = ' '..last_tarot_planet..' ', colour = G.C.UI.TEXT_LIGHT, scale = 0.3, shadow = true}},
                    }}
                }}
            }
            loc_vars = {last_tarot_planet}
            if not (not fool_c or fool_c.name == 'The Fool') then
                    info_queue[#info_queue+1] = fool_c
            end
        elseif _c.name == "The Magician" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The High Priestess" then loc_vars = {_c.config.planets}
        elseif _c.name == "The Empress" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Emperor" then loc_vars = {_c.config.tarots}
        elseif _c.name == "The Hierophant" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Lovers" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Chariot" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "Justice" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Hermit" then loc_vars = {_c.config.extra}
        elseif _c.name == "The Wheel of Fortune" then loc_vars = {G.GAME.probabilities.normal, _c.config.extra};  info_queue[#info_queue+1] = G.P_CENTERS.e_foil; info_queue[#info_queue+1] = G.P_CENTERS.e_holo; info_queue[#info_queue+1] = G.P_CENTERS.e_polychrome; 
        elseif _c.name == "Strength" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "The Hanged Man" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "Death" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "Temperance" then
            local _money = 0
            if G.jokers then
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i].ability.set == 'Joker' then
                        _money = _money + G.jokers.cards[i].sell_cost
                    end
                end
            end
            loc_vars = {_c.config.extra, math.min(_c.config.extra, _money)}
        elseif _c.name == "The Devil" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Tower" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Star" then loc_vars = {_c.config.max_highlighted,  localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "The Moon" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "The Sun" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "Judgement" then
        elseif _c.name == "The World" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        end
        if _c.balamod then
            for k,v in pairs(consumable.tarot_loc_vars) do
                if k == _c.key then 
                    local status, new_loc_vars = pcall(v, _c)
                    if new_loc_vars then
                        loc_vars = new_loc_vars
                    end
                end
            end
        end
        
        localize{type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars}
        
        if main_end then 
            desc_nodes[#desc_nodes+1] = main_end 
        end
    
       --Fill all remaining info if this is the main desc
        if not ((specific_vars and not specific_vars.sticker) and (card_type == 'Default' or card_type == 'Enhanced')) then
            if desc_nodes == full_UI_table.main and not full_UI_table.name then
                localize{type = 'name', key = _c.key, set = _c.set, nodes = full_UI_table.name} 
                if not full_UI_table.name then full_UI_table.name = {} end
            elseif desc_nodes ~= full_UI_table.main then 
                desc_nodes.name = localize{type = 'name_text', key = name_override or _c.key, set = name_override and 'Other' or _c.set} 
            end
        end
    
        if first_pass and not (_c.set == 'Edition') and badges then
            for k, v in ipairs(badges) do
                if v == 'foil' then info_queue[#info_queue+1] = G.P_CENTERS['e_foil'] end
                if v == 'holographic' then info_queue[#info_queue+1] = G.P_CENTERS['e_holo'] end
                if v == 'polychrome' then info_queue[#info_queue+1] = G.P_CENTERS['e_polychrome'] end
                if v == 'negative' then info_queue[#info_queue+1] = G.P_CENTERS['e_negative'] end
                if v == 'negative_consumable' then info_queue[#info_queue+1] = {key = 'e_negative_consumable', set = 'Edition', config = {extra = 1}} end
                if v == 'gold_seal' then info_queue[#info_queue+1] = {key = 'gold_seal', set = 'Other'} end
                if v == 'blue_seal' then info_queue[#info_queue+1] = {key = 'blue_seal', set = 'Other'} end
                if v == 'red_seal' then info_queue[#info_queue+1] = {key = 'red_seal', set = 'Other'} end
                if v == 'purple_seal' then info_queue[#info_queue+1] = {key = 'purple_seal', set = 'Other'} end
                if v == 'eternal' then info_queue[#info_queue+1] = {key = 'eternal', set = 'Other'} end
                if v == 'perishable' then info_queue[#info_queue+1] = {key = 'perishable', set = 'Other', vars = {G.GAME.perishable_rounds or 1, specific_vars.perish_tally or G.GAME.perishable_rounds}} end
                if v == 'rental' then info_queue[#info_queue+1] = {key = 'rental', set = 'Other', vars = {G.GAME.rental_rate or 1}} end
                if v == 'pinned_left' then info_queue[#info_queue+1] = {key = 'pinned_left', set = 'Other'} end
            end
        end
    
        for _, v in ipairs(info_queue) do
            generate_card_ui(v, full_UI_table)
        end
    
        return full_UI_table
    end
    return misc_generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
end