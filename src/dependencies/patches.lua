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
local logger = logging.getLogger('patches')

function love.load(args)
    for _, mod in ipairs(balamod.mods) do
        if mod.on_game_load then
            mod.on_game_load(args)
        end
    end
    if game_love_load then
        game_love_load(args)
    end
end

function love.quit()
    for _, mod in ipairs(balamod.mods) do
        if mod.on_game_quit then
            mod.on_game_quit()
        end
    end
    if game_love_quit then
        game_love_quit()
    end
end

function love.update(dt)
    local cancel_update = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_pre_update then
            if mod.on_pre_update(dt) then
                cancel_update = true
            end
        end
    end

    if cancel_update then return end

    if game_love_update then
        game_love_update(dt)
    end

    if balamod.is_loaded == false then
        balamod.is_loaded = true
        for _, mod in ipairs(balamod.mods) do -- Load all mods after eveything else
            if mod.enabled and mod.on_enable and type(mod.on_enable) == "function" then
                local ok, message = pcall(mod.on_enable) -- Call the on_enable function of the mod if it exists
                if not ok then
                    logger:warn("Enabling mod ", mod.mod_id, "failed: ", message)
                end
            end
        end
    end

    for _, mod in ipairs(balamod.mods) do
        if mod.on_post_update then
            mod.on_post_update(dt)
        end
    end
end

function love.draw()
    for _, mod in ipairs(balamod.mods) do
        if mod.on_pre_render then
            mod.on_pre_render()
        end
    end

    if game_love_draw then
        game_love_draw()
    end

    for _, mod in ipairs(balamod.mods) do
        if mod.on_post_render then
            mod.on_post_render()
        end
    end

end

function love.keypressed(key)
    local cancel_event = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_key_pressed then
            if mod.on_key_pressed(key) then
                cancel_event = true
            end
        end
    end

    if cancel_event then return end

    if game_love_keypressed then
        game_love_keypressed(key)
    end
end

function love.keyreleased(key)
    local cancel_event = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_key_released then
            if mod.on_key_released(key) then
                cancel_event = true
            end
        end
    end

    if cancel_event then return end

    if game_love_keyreleased then
        game_love_keyreleased(key)
    end
end

function love.gamepadpressed(joystick, button)
    if game_love_gamepad_pressed then
        game_love_gamepad_pressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    if game_love_gamepad_released then
        game_love_gamepad_released(joystick, button)
    end
end

function love.mousepressed(x, y, button, touch)
    local cancel_event = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_mouse_pressed then
            if mod.on_mouse_pressed(x, y, button, touches) then
                cancel_event = true
            end
        end
    end
    if cancel_event then return end

    if game_love_mousepressed then
        game_love_mousepressed(x, y, button, touch)
    end
end

function love.mousereleased(x, y, button)
    local cancel_event = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_mouse_released then
            if mod.on_mouse_released(x, y, button) then
                cancel_event = true
            end
        end
    end
    if cancel_event then return end

    if game_love_mousereleased then
        game_love_mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if game_love_mousemoved then
        game_love_mousemoved(x, y, dx, dy, istouch)
    end
end

function love.joystickaxis(joystick, axis, value)
    if game_love_joystick_axis then
        game_love_joystick_axis(joystick, axis, value)
    end
end

function love.errhand(msg)
    for _, mod in ipairs(balamod.mods) do
        if mod.on_error then
            mod.on_error(msg)
        end
    end

    if game_love_errhand then
        game_love_errhand(msg)
    end
end

function love.wheelmoved(x, y)
    local cancel_event = false
    for _, mod in ipairs(balamod.mods) do
        if mod.on_mousewheel then
            if mod.on_mousewheel(x, y) then
                cancel_event = true
            end
        end
        if cancel_event then return end
    end

    if game_love_wheelmoved then
        game_love_wheelmoved(x, y)
    end
end
