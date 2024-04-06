local balamod = require("balamod")
local logging = require('logging')
local utils = require('utils')
local logger = logging.getLogger('patches')

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

inject = balamod.inject
injectHead = balamod.injectHead
injectTail = balamod.injectTail

require('balamod_love')
require('balamod_card')
require('balamod_game')
require('balamod_uidefs')
require('mod_menu')
