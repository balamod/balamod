local joker = require('joker')
local seal = require('seal')
local assets = require('assets')
local logging = require('logging')
local logger = logging.getLogger('card')
local consumable = require("consumable")

-- references to original patched functions
local card_calculate_joker = card_calculate_joker or Card.calculate_joker
local card_generate_uibox_ability_table = card_generate_uibox_ability_table or Card.generate_UIBox_ability_table
local card_set_sprites = card_set_sprites or Card.set_sprites
local card_calculate_seal = card_calculate_seal or Card.calculate_seal
local card_get_end_of_round_effect = card_get_end_of_round_effect or Card.get_end_of_round_effect
local card_eval_card = eval_card
local card_open = card_open or Card.open
local card_calculate_dollar_bonus = Card.calculate_dollar_bonus
local card_add_to_deck = Card.add_to_deck
local card_remove_from_deck = Card.remove_from_deck
local card_use_consumeable = Card.use_consumeable
local card_can_use_consumeable = Card.can_use_consumeable


function Card:calculate_joker(context)
    local old_return = card_calculate_joker(self, context)
    if context.first_hand_drawn and self.ability.name == "Certificate" then
        G.E_MANAGER:add_event(Event({
            func = function()
                local _card = create_playing_card({
                    front = pseudorandom_element(G.P_CARDS, pseudoseed('cert_fr')),
                    center = G.P_CENTERS.c_base
                }, G.hand, nil, nil, {G.C.SECONDARY_SET.Enhanced})
                local seal_type = pseudorandom(pseudoseed('certsl'), 1, #G.P_CENTER_POOLS['Seal'])
                local sealName
                for k, v in pairs(G.P_SEALS) do
                    if v.order == seal_type then
                        sealName = k
                        _card:set_seal(sealName, true)
                    end
                end
                G.hand:sort()
                if context.blueprint_card then
                    context.blueprint_card:juice_up()
                else
                    self:juice_up()
                end
                return true
            end
        }))
        playing_card_joker_effects({true})
    end
    if self.ability.set == "Joker" and not self.debuff then
        for k, effect in pairs(joker.calculateJokerEffects) do
            local status, new_return = pcall(effect, self, context)
            if new_return then
                return new_return
            end
        end
    end
    return old_return
end

function Card:generate_UIBox_ability_table()
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
            return card_generate_uibox_ability_table(self)
        elseif not self.config.center.unlocked and not self.bypass_lock then
            return card_generate_uibox_ability_table(self)
        elseif not self.config.center.discovered and not self.bypass_discovery_ui then
            return card_generate_uibox_ability_table(self)
        elseif self.debuff then
            return card_generate_uibox_ability_table(self)
        elseif card_type == 'Default' or card_type == 'Enhanced' then
            return card_generate_uibox_ability_table(self)
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
        return card_generate_uibox_ability_table(self)
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

function Card.calculate_seal(self, context)
    local old_return = card_calculate_seal(self, context)
    for i, v in ipairs(seal.timings) do
        if v[1] == "onDiscard" or v[1] == "onRepetition" then
            local status, new_return = pcall(seal.effects[v[2]], self, context)
            if new_return then
                return new_return
            end
        end
    end
    return old_return
end

function Card.get_end_of_round_effect(self, context)
    local old_return = card_get_end_of_round_effect(self, context)
    for i, v in ipairs(seal.timings) do
        if v[1] == "onHold" then
            local status, new_return = pcall(seal.effects[v[2]], self, context)
            if new_return then
                return new_return
            end
        end
    end
    return old_return
end

function eval_card(card, context)
    local old_return = card_eval_card(card, context)
    for i, v in ipairs(seal.timings) do
        if v[1] == "onEval" then
            pcall(seal.effects[v[2]], card, context)
        end
    end
    return old_return
end

function Card.get_p_dollars(self)
    local ret = 0
    if self.debuff then
        return 0
    end
    for i, v in ipairs(seal.timings) do
        if v[1] == "onDollars" then
            local status, value_return = pcall(seal.effects[v[2]], self)
            if value_return then
                ret = ret + value_return
            end
        end
    end
    if self.seal == 'Gold' then
        ret = ret + 3
    end
    if self.ability.p_dollars > 0 then
        if self.ability.effect == "Lucky Card" then
            if pseudorandom('lucky_money') < G.GAME.probabilities.normal / 15 then
                self.lucky_trigger = true
                ret = ret + self.ability.p_dollars
            end
        else
            ret = ret + self.ability.p_dollars
        end
    end
    if ret > 0 then
        G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + ret
        G.E_MANAGER:add_event(Event({
            func = (function()
                G.GAME.dollar_buffer = 0;
                return true
            end)
        }))
    end
    return ret
end

function Card:open()
    if self.ability.set == "Booster" and not self.ability.name:find('Standard') then
        return card_open(self)
    else
        stop_use()
        G.STATE_COMPLETE = false
        self.opening = true

        if not self.config.center.discovered then
            discover_card(self.config.center)
        end
        self.states.hover.can = false
        G.STATE = G.STATES.STANDARD_PACK
        G.GAME.pack_size = self.ability.extra

        G.GAME.pack_choices = self.config.center.config.choose or 1

        if self.cost > 0 then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    inc_career_stat('c_shop_dollars_spent', self.cost)
                    self:juice_up()
                    return true
                end
            }))
            ease_dollars(-self.cost)
        else
            delay(0.2)
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                self:explode()
                local pack_cards = {}

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        local _size = self.ability.extra

                        for i = 1, _size do
                            local card = nil
                            card = create_card(
                                (pseudorandom(pseudoseed('stdset' .. G.GAME.round_resets.ante)) > 0.6) and "Enhanced" or
                                    "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                            local edition_rate = 2
                            local edition = poll_edition('standard_edition' .. G.GAME.round_resets.ante, edition_rate,
                                true)
                            card:set_edition(edition)
                            local seal_rate = 10
                            local seal_poll = pseudorandom(pseudoseed('stdseal' .. G.GAME.round_resets.ante))
                            if seal_poll > 1 - 0.02 * seal_rate then
                                local seal_type = pseudorandom(pseudoseed('stdsealtype' .. G.GAME.round_resets.ante), 1,
                                    #G.P_CENTER_POOLS['Seal'])
                                local sealName
                                for k, v in pairs(G.P_SEALS) do
                                    if v.order == seal_type then
                                        sealName = k
                                        card:set_seal(sealName)
                                    end
                                end
                            end
                            card.T.x = self.T.x
                            card.T.y = self.T.y
                            card:start_materialize({G.C.WHITE, G.C.WHITE}, nil, 1.5 * G.SETTINGS.GAMESPEED)
                            pack_cards[i] = card
                        end
                        return true
                    end
                }))

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        if G.pack_cards then
                            if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then
                                for k, v in ipairs(pack_cards) do
                                    G.pack_cards:emplace(v)
                                end
                                return true
                            end
                        end
                    end
                }))

                for i = 1, #G.jokers.cards do
                    G.jokers.cards[i]:calculate_joker({
                        open_booster = true,
                        card = self
                    })
                end

                if G.GAME.modifiers.inflation then
                    G.GAME.inflation = G.GAME.inflation + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            for k, v in pairs(G.I.CARD) do
                                if v.set_cost then
                                    v:set_cost()
                                end
                            end
                            return true
                        end
                    }))
                end

                return true
            end
        }))
    end
end

function Card:calculate_dollar_bonus()
    local old_return = card_calculate_dollar_bonus(self)
    if not self.debuff and self.ability.set == "Joker" then
        for _, effect in pairs(joker.dollarBonusEffects) do
            local status, new_return = pcall(effect, self)
            if new_return then 
                return new_return
            end 
        end
    end
    return old_return
end

function Card:add_to_deck(from_debuff)
    local old_return = card_add_to_deck(self, from_debuff)
    for _, effect in pairs(joker.addToDeckEffects) do
        local status, new_return = pcall(effect, self, from_debuff)
        if new_return then
            return new_return
        end
    end
    return old_return
end

function Card:remove_from_deck(from_debuff)
    local old_return = card_remove_from_deck(self, from_debuff)
    for _, effect in pairs(joker.removeFromDeckEffects) do
        local status, new_return = pcall(effect, self, from_debuff)
        if new_return then
            return new_return
        end
    end
    return old_return
end

function Card:can_use_consumeable(any_state, skip_check)
    local old_return = card_can_use_consumeable(self, any_state, skip_check)
    if not skip_check and ((G.play and #G.play.cards > 0) or
        (G.CONTROLLER.locked) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
        then  
        return false 
    end
    if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or any_state then
        for _, condition in pairs(consumable.useConditions) do
            local status, new_return = pcall(condition, self, any_state, skip_check)
            if status and new_return then
                return new_return
            end
        end
    end
    return old_return
end

function Card:use_consumeable(area, copier)
    local old_return = card_use_consumeable(self, area, copier)
    for _, effect in pairs(consumable.useEffects) do
        local status, new_return = pcall(effect, self, area, copier)
        if status and new_return then
            return new_return
        end
    end
end