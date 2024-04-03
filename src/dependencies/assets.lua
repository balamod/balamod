-- Asset loading API, in order to load assets from a mod's directory.
local balamod = require("balamod")
local assets = {}

local game_set_render_settings = game_set_render_settings or Game.set_render_settings
local card_set_sprites = card_set_sprites or Card.set_sprites

local function patched_game_set_render_settings(self)
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

local function patched_card_set_sprites(self, _center, _front)
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
                if (not _center.unlocked or not self.config.center.unlocked or not _center.discovered) and not self.params.bypass_discovery_center then
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
                        self.children.back:set_sprite_pos(G.P_CENTES['b_red'].pos)
                    end
                end
            end
        end
    else
        -- no center specified, just use the base function from the game
        card_set_sprites(self, _center, _front)
    end
end


local function getAtli(modId, textureScaling)
    local atli = {
        asset = {},
        animation = {}
    }
    local assetTypes = {
        b = "Back",
        v = "Voucher",
        j = "Joker",
        e = "Edition",
        c = "Consumable",
        p = "Booster",
        m = "Enhancers",
        t = "Tag",
        card = "Card",
        chip = "Chip",
        blind = "Blind",
        sticker = "Sticker",
    }
    local atliPath = "mods/" .. modId .. "/assets/textures/"..textureScaling.."x"
    local dir = love.filesystem.getDirectoryItems(atliPath)
    for i, path in ipairs(dir) do
        local filename, extension = string.match(path, "([^/]+)%.(.+)$")
        local name = modId .. "_" .. filename
        local image = love.graphics.newImage(atliPath.."/"..path, {mipmaps = true, dpiscale = textureScaling})
        local assetType = assetTypes[string.match(filename, "(.+)_")]
        local px, py = 71, 95
        if assetType == "Chip" then
            px, py = 29, 29
        end
        if assetType == "Tag" then
            px, py = 34, 34
        end
        if assetType == "Blind" then
            px, py = 34, 34
        end
        if assetType == "Blind" then
            table.insert(atli.animation, {
                name = name,
                image = image,
                type = assetType,
                frames = 21,
                px = px,
                py = py,
            })
        else
            table.insert(atli.asset, {
                name = name,
                image = image,
                type = assetType,
                px = px,
                py = py,
            })
        end
    end
    return atli
end

assets.getAtli = getAtli
assets.patched_game_set_render_settings = patched_game_set_render_settings
assets.patched_card_set_sprites = patched_card_set_sprites

return assets
