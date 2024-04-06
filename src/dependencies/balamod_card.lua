local joker = require('joker')
local assets = require('assets')
local logging = require('logging')
local logger = logging.getLogger('card')

-- references to original patched functions
local card_calculate_joker = card_calculate_joker or Card.calculate_joker
local card_generate_uibox_ability_table = card_generate_uibox_ability_table or Card.generate_UIBox_ability_table
local card_set_sprites = card_set_sprites or Card.set_sprites

function Card:calculate_joker(context)
    local old_return = card_calculate_joker(self, context)
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

function Card:generate_UIBox_ability_table()
    local old_return = card_generate_uibox_ability_table(self)
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

function Card:set_sprites(_center, _front)
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
                if (_center.unlocked and self.config.center.unlocked and _center.discovered) or self.params.bypass_discovery_center then
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