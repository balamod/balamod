-- Asset loading API, in order to load assets from a mod's directory.
local assets = {}

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

return assets
