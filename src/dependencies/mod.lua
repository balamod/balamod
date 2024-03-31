local mod = {}


function mod.createMod(modId)
    return {
        id = modId,
        name = modName,
        version = modVersion,
        newVersion = modNewVersion,
        author = modAuthor,
        description = modDescription,
        callbacks = {},
        isInstalled = isInstalled,
        manifest = manifest,
        hasUpdate = function(self)
        end,
        install = function(self)
        end,
        toggle = function(self)
        end,
        load = function(self)
        end,
        isManifestValid = function(self)
        end,
    }
end

function mod.allMods()
end

return mod
