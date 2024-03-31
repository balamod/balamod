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

local balamod = require("balamod")
local logging = require('logging')
local utils = require('utils')
local logger = logging.getLogger('patches')
local assets = require('assets')
local jokerapi = require('jokerapi')

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
        for k, effect in pairs(jokerapi.jokerEffects) do
            local status, new_return = pcall(effect, self, context)
            if new_return then 
                return new_return
            end 
        end
    end
    return old_return
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
                self.children.center:reset()
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
                    self.children.center:reset()
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
