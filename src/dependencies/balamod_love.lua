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
local logger = logging.getLogger('love')
local localization = require('localization')

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
        else
            localization.inject()
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
