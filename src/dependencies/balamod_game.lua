local assets = require('assets')
local logging = require('logging')
local logger = logging.getLogger('game')
local balamod = require('balamod')

local game_set_render_settings = game_set_render_settings or Game.set_render_settings

function Game:set_render_settings()
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
