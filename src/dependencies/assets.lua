-- -----------------------------------------
-- sendDebugMessage("Adding Test to centers!")

-- local joker, text = jokerHook.addJoker(self, "j_test", "Test", nil, true, 5, { x = 0, y = 0 }, nil, {mult = 5, extra = 1}, {"testestestes", "testestestestestestes", "testestestestestes", "testestestest"}, 4, true, true) -- see centerhook by @arachneii

-- ------------------------------------------
-- sendDebugMessage("Adding texture file for Test!")

-- local toReplaceAtlas = "{name = 'chips', path = \"resources/textures/\"..self.SETTINGS.GRAPHICS.texture_scaling..\"x/chips.png\",px=29,py=29}"

-- local replacementAtlas = [[
--     {name = 'test', path = "pack/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/test.png",px=71,py=95},
--     {name = 'chips', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/chips.png",px=29,py=29}
-- ]]

-- inject("game.lua", "Game:set_render_settings", toReplaceAtlas:gsub("([^%w])", "%%%1"), replacementAtlas)


-- G:set_render_settings()

-- -------------------------------------------------------
-- sendDebugMessage("Adding sprite draw logic for Test!")

-- local toReplaceTexLoad = "elseif self.config.center.set == 'Voucher' and not self.config.center.unlocked and not self.params.bypass_discovery_center then"

-- local replacementTexLoad = [[
--     elseif _center.name == 'Test' then
--         self.children.center = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS["test"], j_test)
--     elseif self.config.center.set == 'Voucher' and not self.config.center.unlocked and not self.params.bypass_discovery_center then
-- ]]

-- inject("card.lua", "Card:set_sprites", toReplaceTexLoad:gsub("([^%w])", "%%%1"), replacementTexLoad)

-- -------------------------------------------------------

-- Asset loading API, in order to load assets from a mod's directory.

local assets = {}

function assets.getAtli(modId, textureScaling)
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
        local image = love.graphics.newImage(path, {mipmaps = true, dpiscale = textureScaling})
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

return assets
