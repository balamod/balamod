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

local balamod = require("balamod")
local logging = require('logging')
local utils = require('utils')
local logger = logging.getLogger('patches')
local assets = require('assets')
local joker = require('joker')

function love.load(args)
    local status, message = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_game_load", true, args)
    if not status then
        logger:warn("Failed on_game_load for mods: ", message)
    end
    if game_love_load then
        game_love_load(args)
    end
end

function love.quit()
    local status, message = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_game_quit", true)
    if not status then
        logger:warn("Failed on_game_quit for mods: ", message)
    end
    if game_love_quit then
        game_love_quit()
    end
end

function love.update(dt)
    local cancel_update = false
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_pre_update", false, dt)
    if not status then
        logger:warn("Failed on_pre_update for mods: ", result)
    else
        cancel_update = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
    end
    if cancel_update then
        return
    end

    if game_love_update then
        game_love_update(dt)
    end

    if balamod.is_loaded == false then
        balamod.is_loaded = true
        local status, message = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_enable", true)
        if not status then
            logger:warn("Failed to load mods: ", message)
        end
    end

    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_post_update", false, dt)
    if not status then
        logger:warn("Failed on_post_update for mods: ", result)
    end
end

function love.draw()
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_pre_render", false)
    if not status then
        logger:warn("Failed on_pre_render for mods: ", result)
    end

    if game_love_draw then
        game_love_draw()
    end
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_post_render", false)
    if not status then
        logger:warn("Failed on_post_render for mods: ", result)
    end
end

function love.keypressed(key)
    local cancel_event = false
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_key_pressed", false, key)
    if not status then
        logger:warn("Failed on_key_pressed for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_key_released", false, key)
    if not status then
        logger:warn("Failed on_key_released for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_gamepad_pressed", false, joystick, button)
    if not status then
        logger:warn("Failed on_gamepad_pressed for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_gamepad_released", false, joystick, button)
    if not status then
        logger:warn("Failed on_gamepad_released for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_mouse_pressed", false, x, y, button, touch)
    if not status then
        logger:warn("Failed on_mouse_pressed for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_mouse_released", false, x, y, button)
    if not status then
        logger:warn("Failed on_mouse_released for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_mouse_moved", false, x, y, dx, dy, istouch)
    if not status then
        logger:warn("Failed on_mouse_moved for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
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
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_joystick_axis", false, joystick, axis, value)
    if not status then
        logger:warn("Failed on_joystick_axis for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
    end
    if cancel_event then
        return
    end

    if game_love_joystick_axis then
        game_love_joystick_axis(joystick, axis, value)
    end
end

function love.errhand(msg)
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_error", true, msg)
    if not status then
        logger:warn("Failed on_error for mods: ", result)
    end

    if game_love_errhand then
        game_love_errhand(msg)
    end
end

function love.wheelmoved(x, y)
    local cancel_event = false
    local status, result = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_mousewheel", false, x, y)
    if not status then
        logger:warn("Failed  for mods: ", result)
    else
        cancel_event = utils.reduce(result, function(acc, val)
            return acc or val.result
        end, false)
    end

    if cancel_event then
        return
    end
    if game_love_wheelmoved then
        game_love_wheelmoved(x, y)
    end
end

local game_calculate_joker = Card.calculate_joker

function Card.calculate_joker(self, context)
    local old_return = game_calculate_joker(self, context)
    if self.ability.set == "Joker" and not self.debuff then
        for k, effect in pairs(joker.jokerEffects) do
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
    local old_return = game_generate_uibox_ability_table(self)
    if self.config.center.balamod then
        local card_type = self.ability.set or "None"
        local hide_desc = nil
        local loc_vars = nil
        local main_start, main_end = nil, nil
        local no_badge = nil
        if not self.bypass_lock and self.config.center.unlocked ~= false and
        (self.ability.set == 'Joker' or self.ability.set == 'Edition' or self.ability.consumeable or self.ability.set == 'Voucher' or self.ability.set == 'Booster') and
        not self.config.center.discovered and
        ((self.area ~= G.jokers and self.area ~= G.consumeables and self.area) or not self.area) then
            return old_return
        elseif not self.config.center.unlocked and not self.bypass_lock then
            return old_return
        elseif not self.config.center.discovered and not self.bypass_discovery_ui then
            return old_return
        elseif self.debuff then
            return old_return
        elseif card_type == 'Default' or card_type == 'Enhanced' then
            return old_return
        elseif self.ability.set == 'Joker' then
            loc_vars = joker.loc_vars[self.config.center.balamod.key](self)
        end

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
    else
        return old_return
    end
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
    if love.filesystem.getInfo("mods/" .. modFolder, "directory") then
        local mod = balamod.loadMod(modFolder)
        if mod ~= nil then
            balamod.mods[mod.id] = mod
            logger:info("Loaded mod: ", mod.id)
        end
    end
end
local status, sortedMods = pcall(balamod.sortMods, balamod.mods)
if not status then
    logger:warn("Failed to sort mods: ", sortedMods)
else
    balamod.mods = sortedMods
end

logger:info("Mods: ", utils.keys(mods))
local status, message = pcall(balamod.callModCallbacksIfExists, balamod.mods, "on_pre_load", true)
if not status then
    logger:warn("Failed to preload mods: ", message)
end

G.set_render_settings = assets.patched_game_set_render_settings
Card.set_sprites = assets.patched_card_set_sprites
