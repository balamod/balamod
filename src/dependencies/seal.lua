local balamod = require('balamod')
local logging = require('logging')
local logger = logging.getLogger("seal")
local seal = {}
seal._VERSION = "0.1.0"
seal.seals = {}
seal.effects = {}
seal.timings = {}
local first_mod = true

local function setData(args)
    local generate_card_ui_ref = generate_card_ui
    function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
        local ignore = true
        local cbadge
        if badges then
            for k, v in ipairs(badges) do
                if v == args.loc_id then
                    ignore = false
                    cbadge = v
                end
            end
        end
        if args.info or not ignore or (_c.set == "Other" and _c.key == args.loc_id) then
            local first_pass = nil
            if not full_UI_table then
                first_pass = true
                full_UI_table = {
                    main = {},
                    info = {},
                    type = {},
                    name = nil,
                    badges = badges or {}
                }
            end
            local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
            local name_override = nil
            local info_queue = {}
            if args.info then
                if _c.set == args.set and _c.name == args.name then
                    info_queue[#info_queue + 1] = {
                        key = args.loc_id,
                        set = "Other"
                    }
                end
            end

            if full_UI_table.name then
                full_UI_table.info[#full_UI_table.info + 1] = {}
                desc_nodes = full_UI_table.info[#full_UI_table.info]
            end

            if not full_UI_table.name then
                if specific_vars and specific_vars.no_name then
                    full_UI_table.name = true
                elseif card_type == 'Locked' then
                    full_UI_table.name = localize {
                        type = 'name',
                        set = 'Other',
                        key = 'locked',
                        nodes = {}
                    }
                elseif card_type == 'Undiscovered' then
                    full_UI_table.name = localize {
                        type = 'name',
                        set = 'Other',
                        key = 'undiscovered_' .. (string.lower(_c.set)),
                        name_nodes = {}
                    }
                elseif specific_vars and (card_type == 'Default' or card_type == 'Enhanced') then
                    if (_c.name == 'Stone Card') then
                        full_UI_table.name = true
                    end
                    if (specific_vars.playing_card and (_c.name ~= 'Stone Card')) then
                        full_UI_table.name = {}
                        localize {
                            type = 'other',
                            key = 'playing_card',
                            set = 'Other',
                            nodes = full_UI_table.name,
                            vars = {
                                localize(specific_vars.value, 'ranks'),
                                localize(specific_vars.suit, 'suits_plural'),
                                colours = {specific_vars.colour}
                            }
                        }
                        full_UI_table.name = full_UI_table.name[1]
                    end
                elseif card_type == 'Booster' then

                else
                    full_UI_table.name = localize {
                        type = 'name',
                        set = _c.set,
                        key = _c.key,
                        nodes = full_UI_table.name
                    }
                end
                full_UI_table.card_type = card_type or _c.set
            end

            local loc_vars = {}
            if main_start then
                desc_nodes[#desc_nodes + 1] = main_start
            end
            if _c.set == 'Other' then
                localize {
                    type = 'other',
                    key = _c.key,
                    nodes = desc_nodes,
                    vars = specific_vars
                }
            elseif hide_desc then
                localize{type = 'other', key = 'undiscovered_'..(string.lower(_c.set)), set = _c.set, nodes = desc_nodes}
            elseif specific_vars and specific_vars.debuffed then
                localize {
                    type = 'other',
                    key = 'debuffed_' .. (specific_vars.playing_card and 'playing_card' or 'default'),
                    nodes = desc_nodes
                }
            elseif _c.set == 'Joker' then
                if _c.name == 'Stone Joker' or _c.name == 'Marble Joker' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_stone
                elseif _c.name == 'Steel Joker' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_steel
                elseif _c.name == 'Glass Joker' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_glass
                elseif _c.name == 'Golden Ticket' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
                elseif _c.name == 'Lucky Cat' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
                elseif _c.name == 'Midas Mask' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
                elseif _c.name == 'Invisible Joker' then
                    if G.jokers and G.jokers.cards then
                        for k, v in ipairs(G.jokers.cards) do
                            if (v.edition and v.edition.negative) and
                                (G.localization.descriptions.Other.remove_negative) then
                                main_end = {}
                                localize {
                                    type = 'other',
                                    key = 'remove_negative',
                                    nodes = main_end,
                                    vars = {}
                                }
                                main_end = main_end[1]
                                break
                            end
                        end
                    end
                elseif _c.name == 'Diet Cola' then
                    info_queue[#info_queue + 1] = {
                        key = 'tag_double',
                        set = 'Tag'
                    }
                elseif _c.name == 'Perkeo' then
                    info_queue[#info_queue + 1] = {
                        key = 'e_negative_consumable',
                        set = 'Edition',
                        config = {
                            extra = 1
                        }
                    }
                end
                if specific_vars and specific_vars.pinned then
                    info_queue[#info_queue + 1] = {
                        key = 'pinned_left',
                        set = 'Other'
                    }
                end
                if specific_vars and specific_vars.sticker then
                    info_queue[#info_queue + 1] = {
                        key = string.lower(specific_vars.sticker) .. '_sticker',
                        set = 'Other'
                    }
                end
                localize {
                    type = 'descriptions',
                    key = _c.key,
                    set = _c.set,
                    nodes = desc_nodes,
                    vars = specific_vars or {}
                }
            elseif _c.set == 'Edition' then
                loc_vars = {_c.config.extra}
                localize {
                    type = 'descriptions',
                    key = _c.key,
                    set = _c.set,
                    nodes = desc_nodes,
                    vars = loc_vars
                }
            elseif _c.set == 'Default' and specific_vars then
                if specific_vars.nominal_chips then
                    localize {
                        type = 'other',
                        key = 'card_chips',
                        nodes = desc_nodes,
                        vars = {specific_vars.nominal_chips}
                    }
                end
                if specific_vars.bonus_chips then
                    localize {
                        type = 'other',
                        key = 'card_extra_chips',
                        nodes = desc_nodes,
                        vars = {specific_vars.bonus_chips}
                    }
                end
            elseif _c.set == 'Enhanced' then 
                if specific_vars and _c.name ~= 'Stone Card' and specific_vars.nominal_chips then
                    localize{type = 'other', key = 'card_chips', nodes = desc_nodes, vars = {specific_vars.nominal_chips}}
                end
                if _c.effect == 'Mult Card' then loc_vars = {_c.config.mult}
                elseif _c.effect == 'Wild Card' then
                elseif _c.effect == 'Glass Card' then loc_vars = {_c.config.Xmult, G.GAME.probabilities.normal, _c.config.extra}
                elseif _c.effect == 'Steel Card' then loc_vars = {_c.config.h_x_mult}
                elseif _c.effect == 'Stone Card' then loc_vars = {((specific_vars and specific_vars.bonus_chips) or _c.config.bonus)}
                elseif _c.effect == 'Gold Card' then loc_vars = {_c.config.h_dollars}
                elseif _c.effect == 'Lucky Card' then loc_vars = {G.GAME.probabilities.normal, _c.config.mult, 5, _c.config.p_dollars, 15}
                end
                localize{type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars}
                if _c.name ~= 'Stone Card' and ((specific_vars and specific_vars.bonus_chips) or _c.config.bonus) then
                    localize{type = 'other', key = 'card_extra_chips', nodes = desc_nodes, vars = {((specific_vars and specific_vars.bonus_chips) or _c.config.bonus)}}
                end
            elseif _c.set == 'Spectral' then
                if _c.name == 'Familiar' or _c.name == 'Grim' or _c.name == 'Incantation' then
                    loc_vars = {_c.config.extra}
                elseif _c.name == 'Immolate' then
                    loc_vars = {_c.config.extra.destroy, _c.config.extra.dollars}
                elseif _c.name == 'Hex' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
                elseif _c.name == 'Talisman' then
                    info_queue[#info_queue + 1] = {
                        key = 'gold_seal',
                        set = 'Other'
                    }
                elseif _c.name == 'Deja Vu' then
                    info_queue[#info_queue + 1] = {
                        key = 'red_seal',
                        set = 'Other'
                    }
                elseif _c.name == 'Trance' then
                    info_queue[#info_queue + 1] = {
                        key = 'blue_seal',
                        set = 'Other'
                    }
                elseif _c.name == 'Medium' then
                    info_queue[#info_queue + 1] = {
                        key = 'purple_seal',
                        set = 'Other'
                    }
                elseif _c.name == 'Ankh' then
                    if G.jokers and G.jokers.cards then
                        for k, v in ipairs(G.jokers.cards) do
                            if (v.edition and v.edition.negative) and
                                (G.localization.descriptions.Other.remove_negative) then
                                info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
                                main_end = {}
                                localize {
                                    type = 'other',
                                    key = 'remove_negative',
                                    nodes = main_end,
                                    vars = {}
                                }
                                main_end = main_end[1]
                                break
                            end
                        end
                    end
                elseif _c.name == 'Cryptid' then
                    loc_vars = {_c.config.extra}
                end
                if _c.name == 'Ectoplasm' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.e_negative;
                    loc_vars = {G.GAME.ecto_minus or 1}
                end
                if _c.name == 'Aura' then
                    info_queue[#info_queue + 1] = G.P_CENTERS.e_foil
                    info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
                    info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
                end
                localize {
                    type = 'descriptions',
                    key = _c.key,
                    set = _c.set,
                    nodes = desc_nodes,
                    vars = loc_vars
                }

            end

            if main_end then
                desc_nodes[#desc_nodes + 1] = main_end
            end

            -- Fill all remaining info if this is the main desc
            if not ((specific_vars and not specific_vars.sticker) and
                (card_type == 'Default' or card_type == 'Enhanced')) then
                if desc_nodes == full_UI_table.main and not full_UI_table.name then
                    localize {
                        type = 'name',
                        key = _c.key,
                        set = _c.set,
                        nodes = full_UI_table.name
                    }
                    if not full_UI_table.name then
                        full_UI_table.name = {}
                    end
                elseif desc_nodes ~= full_UI_table.main then
                    desc_nodes.name = localize {
                        type = 'name_text',
                        key = name_override or _c.key,
                        set = name_override and 'Other' or _c.set
                    }
                end
            end
            if first_pass and not (_c.set == 'Edition') and badges then
                for k, v in ipairs(badges) do
                    if v == 'foil' then
                        info_queue[#info_queue + 1] = G.P_CENTERS['e_foil']
                    end
                    if v == 'holographic' then
                        info_queue[#info_queue + 1] = G.P_CENTERS['e_holo']
                    end
                    if v == 'polychrome' then
                        info_queue[#info_queue + 1] = G.P_CENTERS['e_polychrome']
                    end
                    if v == 'negative' then
                        info_queue[#info_queue + 1] = G.P_CENTERS['e_negative']
                    end
                    if v == 'negative_consumable' then
                        info_queue[#info_queue + 1] = {
                            key = 'e_negative_consumable',
                            set = 'Edition',
                            config = {
                                extra = 1
                            }
                        }
                    end
                    if v == 'eternal' then
                        info_queue[#info_queue + 1] = {
                            key = 'eternal',
                            set = 'Other'
                        }
                    end
                    if v == 'pinned_left' then
                        info_queue[#info_queue + 1] = {
                            key = 'pinned_left',
                            set = 'Other'
                        }
                    end
                    if v == cbadge then info_queue[#info_queue+1] = {key = cbadge, set = 'Other'} end
                end
            end
            for _, v in ipairs(info_queue) do
                generate_card_ui(v, full_UI_table)
            end

            return full_UI_table
        end
        return
            generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    end
end

-- Provided args: 
-- mod_id, color, description
-- id = Seal name with no spaces,
-- label = Seal name as you want it to appear in game,
-- shader = shader type like holo, foil, negative, polychrome, etc.
-- effect = a function. If you wish to implement non-standard effects, provide a blank function here and any timing.
-- timing = "onDiscard" or "onRepetition" or "onHold" or "onEval" or "onDollars", no other options. Make sure you use the context.[timing] in your effect code if the timing is discard or repetition. onEval will provide the 'card' and 'context' values as well, imitating the eval_card function. onDollars must return a number.
--
-- This code will automatically append "_seal" to any seal ID for the location ID. Be aware of this.
-- Ensure all assets include the "m_" prefix. This application will crash otherwise.
local function registerSeal(args)

    local id = args.id or "sealplaceholder" .. #G.P_CENTER_POOLS["Seal"] + 1
    local label = args.label or "Placeholder Seal"
    local color = args.color or "red"
    local shader = args.shader or nil
    local desc = args.description

    local newSeal = {
        balamod = {
            mod_id = args.mod_id,
            key = id
        },
        id = id,
        loc_id = string.lower(id) .. "_seal",
        data = {
            key = id,
            set = 'Seal',
            discovered = false,
            order = #G.P_CENTER_POOLS.Seal + 1
        },
        desc = desc,
        color = color,
        shader = shader,
        label = label
    }

    G.P_SEALS[newSeal.id] = newSeal.data
    table.insert(G.P_CENTER_POOLS['Seal'], newSeal.data)

    local newSealText = {
        name = newSeal.label,
        text = newSeal.desc,
        text_parsed = {},
        name_parsed = {}
    }
    for _, line in ipairs(newSeal.desc) do
        newSealText.text_parsed[#newSealText.text_parsed + 1] = loc_parse_string(line)
    end
    for _, line in ipairs(type(newSealText.name) == 'table' and newSealText.name or {newSeal.label}) do
        newSealText.name_parsed[#newSealText.name_parsed + 1] = loc_parse_string(line)
    end
    G.localization.descriptions.Other[newSeal.loc_id] = newSealText
    G.localization.misc.labels[newSeal.loc_id] = newSeal.label
    local atlas_name = args.mod_id .. "_m_" .. newSeal.loc_id
    G.shared_seals[newSeal.id] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[atlas_name], {
        x = 0,
        y = 0
    })

    if shader then
        local valid_shader = {
            dissolve = true,
            voucher = true,
            vortex = true,
            negative = true,
            holo = true,
            foil = true,
            polychrome = true,
            hologram = true
        }
        if valid_shader[shader] then
            local draw_ref = Card.draw
            function Card:draw(layer)
                if self.seal == newSeal.id then
                    layer = layer or 'both'

                    self.hover_tilt = 1

                    if not self.states.visible then
                        return
                    end

                    if (layer == 'shadow' or layer == 'both') then
                        self.ARGS.send_to_shader = self.ARGS.send_to_shader or {}
                        self.ARGS.send_to_shader[1] = math.min(self.VT.r * 3, 1) + G.TIMERS.REAL / (28) +
                                                          (self.juice and self.juice.r * 20 or 0) + self.tilt_var.amt
                        self.ARGS.send_to_shader[2] = G.TIMERS.REAL

                        for k, v in pairs(self.children) do
                            v.VT.scale = self.VT.scale
                        end
                    end

                    G.shared_shadow = self.sprite_facing == 'front' and self.children.center or self.children.back

                    -- Draw the shadow
                    if not self.no_shadow and G.SETTINGS.GRAPHICS.shadows == 'On' and
                        ((layer == 'shadow' or layer == 'both') and
                            (self.ability.effect ~= 'Glass Card' and not self.greyed) and
                            ((self.area and self.area ~= G.discard and self.area.config.type ~= 'deck') or not self.area or
                                self.states.drag.is)) then
                        self.shadow_height = 0 * (0.08 + 0.4 * math.sqrt(self.velocity.x ^ 2)) +
                                                 ((((self.highlighted and self.area == G.play) or self.states.drag.is) and
                                                     0.35) or (self.area and self.area.config.type == 'title_2') and
                                                     0.04 or 0.1)
                        G.shared_shadow:draw_shader('dissolve', self.shadow_height)
                    end

                    if (layer == 'card' or layer == 'both') and self.area ~= G.hand then
                        if self.children.focused_ui then
                            self.children.focused_ui:draw()
                        end
                    end

                    if (layer == 'card' or layer == 'both') then
                        -- for all hover/tilting:
                        self.tilt_var = self.overwrite_tilt_var or self.tilt_var or {
                            mx = 0,
                            my = 0,
                            dx = self.tilt_var.dx or 0,
                            dy = self.tilt_var.dy or 0,
                            amt = 0
                        }
                        local tilt_factor = 0.3
                        if not self.overwrite_tilt_var then
                            if self.states.focus.is then
                                self.tilt_var.mx, self.tilt_var.my =
                                    G.CONTROLLER.cursor_position.x + self.tilt_var.dx * self.T.w * G.TILESCALE *
                                        G.TILESIZE, G.CONTROLLER.cursor_position.y + self.tilt_var.dy * self.T.h *
                                        G.TILESCALE * G.TILESIZE
                                self.tilt_var.amt = math.abs(
                                    self.hover_offset.y + self.hover_offset.x - 1 + self.tilt_var.dx + self.tilt_var.dy -
                                        1) * tilt_factor
                            elseif self.states.hover.is then
                                self.tilt_var.mx, self.tilt_var.my = G.CONTROLLER.cursor_position.x,
                                    G.CONTROLLER.cursor_position.y
                                self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1) *
                                                        tilt_factor
                            elseif self.ambient_tilt then
                                local tilt_angle = G.TIMERS.REAL * (1.56 + (self.ID / 1.14212) % 1) + self.ID / 1.35122
                                self.tilt_var.mx = ((0.5 + 0.5 * self.ambient_tilt * math.cos(tilt_angle)) * self.VT.w +
                                                       self.VT.x + G.ROOM.T.x) * G.TILESIZE * G.TILESCALE
                                self.tilt_var.my = ((0.5 + 0.5 * self.ambient_tilt * math.sin(tilt_angle)) * self.VT.h +
                                                       self.VT.y + G.ROOM.T.y) * G.TILESIZE * G.TILESCALE
                                self.tilt_var.amt = self.ambient_tilt * (0.5 + math.cos(tilt_angle)) * tilt_factor
                            end
                        end
                        -- Any particles
                        if self.children.particles then
                            self.children.particles:draw()
                        end

                        -- Draw any tags/buttons
                        if self.children.price then
                            self.children.price:draw()
                        end
                        if self.children.buy_button then
                            if self.highlighted then
                                self.children.buy_button.states.visible = true
                                self.children.buy_button:draw()
                                if self.children.buy_and_use_button then
                                    self.children.buy_and_use_button:draw()
                                end
                            else
                                self.children.buy_button.states.visible = false
                            end
                        end
                        if self.children.use_button and self.highlighted then
                            self.children.use_button:draw()
                        end

                        if self.vortex then
                            if self.facing == 'back' then
                                self.children.back:draw_shader('vortex')
                            else
                                self.children.center:draw_shader('vortex')
                                if self.children.front then
                                    self.children.front:draw_shader('vortex')
                                end
                            end

                            love.graphics.setShader()
                        elseif self.sprite_facing == 'front' then
                            -- Draw the main part of the card
                            if (self.edition and self.edition.negative) or
                                (self.ability.name == 'Antimatter' and
                                    (self.config.center.discovered or self.bypass_discovery_center)) then
                                self.children.center:draw_shader('negative', nil, self.ARGS.send_to_shader)
                                if self.children.front and self.ability.effect ~= 'Stone Card' then
                                    self.children.front:draw_shader('negative', nil, self.ARGS.send_to_shader)
                                end
                            elseif not self.greyed then
                                self.children.center:draw_shader('dissolve')
                                -- If the card has a front, draw that next
                                if self.children.front and self.ability.effect ~= 'Stone Card' then
                                    self.children.front:draw_shader('dissolve')
                                end
                            end

                            -- If the card is not yet discovered
                            if not self.config.center.discovered and
                                (self.ability.consumeable or self.config.center.unlocked) and
                                not self.config.center.demo and not self.bypass_discovery_center then
                                local shared_sprite = (self.ability.set == 'Edition' or self.ability.set == 'Joker') and
                                                          G.shared_undiscovered_joker or G.shared_undiscovered_tarot
                                local scale_mod = -0.05 + 0.05 * math.sin(1.8 * G.TIMERS.REAL)
                                local rotate_mod = 0.03 * math.sin(1.219 * G.TIMERS.REAL)

                                shared_sprite.role.draw_major = self
                                shared_sprite:draw_shader('dissolve', nil, nil, nil, self.children.center, scale_mod,
                                    rotate_mod)
                            end

                            if self.ability.name == 'Invisible Joker' and
                                (self.config.center.discovered or self.bypass_discovery_center) then
                                self.children.center:draw_shader('voucher', nil, self.ARGS.send_to_shader)
                            end

                            -- If the card has any edition/seal, add that here
                            if self.edition or self.seal or self.ability.eternal or self.sticker or self.ability.set ==
                                'Spectral' or self.debuff or self.greyed or self.ability.name == 'The Soul' or
                                self.ability.set == 'Voucher' or self.ability.set == 'Booster' or
                                self.config.center.soul_pos or self.config.center.demo then
                                if (self.ability.set == 'Voucher' or self.config.center.demo) and
                                    (self.ability.name ~= 'Antimatter' or
                                        not (self.config.center.discovered or self.bypass_discovery_center)) then
                                    self.children.center:draw_shader('voucher', nil, self.ARGS.send_to_shader)
                                end
                                if self.ability.set == 'Booster' or self.ability.set == 'Spectral' then
                                    self.children.center:draw_shader('booster', nil, self.ARGS.send_to_shader)
                                end
                                if self.edition and self.edition.holo then
                                    self.children.center:draw_shader('holo', nil, self.ARGS.send_to_shader)
                                    if self.children.front and self.ability.effect ~= 'Stone Card' then
                                        self.children.front:draw_shader('holo', nil, self.ARGS.send_to_shader)
                                    end
                                end
                                if self.edition and self.edition.foil then
                                    self.children.center:draw_shader('foil', nil, self.ARGS.send_to_shader)
                                    if self.children.front and self.ability.effect ~= 'Stone Card' then
                                        self.children.front:draw_shader('foil', nil, self.ARGS.send_to_shader)
                                    end
                                end
                                if self.edition and self.edition.polychrome then
                                    self.children.center:draw_shader('polychrome', nil, self.ARGS.send_to_shader)
                                    if self.children.front and self.ability.effect ~= 'Stone Card' then
                                        self.children.front:draw_shader('polychrome', nil, self.ARGS.send_to_shader)
                                    end
                                end
                                if (self.edition and self.edition.negative) or
                                    (self.ability.name == 'Antimatter' and
                                        (self.config.center.discovered or self.bypass_discovery_center)) then
                                    self.children.center:draw_shader('negative_shine', nil, self.ARGS.send_to_shader)
                                end
                                if self.seal then
                                    G.shared_seals[self.seal].role.draw_major = self
                                    G.shared_seals[self.seal]:draw_shader('dissolve', nil, nil, nil, self.children.center)
                                    G.shared_seals[self.seal]:draw_shader(shader, nil, self.ARGS.send_to_shader, nil,
                                        self.children.center)
                                end
                                if self.ability.eternal then
                                    G.shared_sticker_eternal.role.draw_major = self
                                    G.shared_sticker_eternal:draw_shader('dissolve', nil, nil, nil, self.children.center)
                                    G.shared_sticker_eternal:draw_shader('voucher', nil, self.ARGS.send_to_shader, nil,
                                        self.children.center)
                                end
                                if self.sticker and G.shared_stickers[self.sticker] then
                                    G.shared_stickers[self.sticker].role.draw_major = self
                                    G.shared_stickers[self.sticker]:draw_shader('dissolve', nil, nil, nil,
                                        self.children.center)
                                    G.shared_stickers[self.sticker]:draw_shader('voucher', nil,
                                        self.ARGS.send_to_shader, nil, self.children.center)
                                end

                                if self.ability.name == 'The Soul' and
                                    (self.config.center.discovered or self.bypass_discovery_center) then
                                    local scale_mod = 0.05 + 0.05 * math.sin(1.8 * G.TIMERS.REAL) + 0.07 *
                                                          math.sin(
                                            (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)) * math.pi * 14) *
                                                          (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 3
                                    local rotate_mod = 0.1 * math.sin(1.219 * G.TIMERS.REAL) + 0.07 *
                                                           math.sin((G.TIMERS.REAL) * math.pi * 5) *
                                                           (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 2

                                    G.shared_soul.role.draw_major = self
                                    G.shared_soul:draw_shader('dissolve', 0, nil, nil, self.children.center, scale_mod,
                                        rotate_mod, nil, 0.1 + 0.03 * math.sin(1.8 * G.TIMERS.REAL), nil, 0.6)
                                    G.shared_soul:draw_shader('dissolve', nil, nil, nil, self.children.center,
                                        scale_mod, rotate_mod)
                                end

                                if self.config.center.soul_pos and
                                    (self.config.center.discovered or self.bypass_discovery_center) then
                                    local scale_mod = 0.07 + 0.02 * math.sin(1.8 * G.TIMERS.REAL) + 0.00 *
                                                          math.sin(
                                            (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)) * math.pi * 14) *
                                                          (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 3
                                    local rotate_mod = 0.05 * math.sin(1.219 * G.TIMERS.REAL) + 0.00 *
                                                           math.sin((G.TIMERS.REAL) * math.pi * 5) *
                                                           (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 2

                                    if self.ability.name == 'Hologram' then
                                        self.hover_tilt = self.hover_tilt * 1.5
                                        self.children.floating_sprite:draw_shader('hologram', nil,
                                            self.ARGS.send_to_shader, nil, self.children.center, 2 * scale_mod,
                                            2 * rotate_mod)
                                        self.hover_tilt = self.hover_tilt / 1.5
                                    else
                                        self.children.floating_sprite:draw_shader('dissolve', 0, nil, nil,
                                            self.children.center, scale_mod, rotate_mod, nil, 0.1 + 0.03 *
                                                math.sin(1.8 * G.TIMERS.REAL), nil, 0.6)
                                        self.children.floating_sprite:draw_shader('dissolve', nil, nil, nil,
                                            self.children.center, scale_mod, rotate_mod)
                                    end

                                end
                                if self.debuff then
                                    self.children.center:draw_shader('debuff', nil, self.ARGS.send_to_shader)
                                    if self.children.front and self.ability.effect ~= 'Stone Card' then
                                        self.children.front:draw_shader('debuff', nil, self.ARGS.send_to_shader)
                                    end
                                end
                                if self.greyed then
                                    self.children.center:draw_shader('played', nil, self.ARGS.send_to_shader)
                                    if self.children.front and self.ability.effect ~= 'Stone Card' then
                                        self.children.front:draw_shader('played', nil, self.ARGS.send_to_shader)
                                    end
                                end
                            end
                        elseif self.sprite_facing == 'back' then
                            local overlay = G.C.WHITE
                            if self.area and self.area.config.type == 'deck' and self.rank > 3 then
                                overlay = {0.5 + ((#self.area.cards - self.rank) % 7) / 50,
                                           0.5 + ((#self.area.cards - self.rank) % 7) / 50,
                                           0.5 + ((#self.area.cards - self.rank) % 7) / 50, 1}
                            end

                            if self.area and self.area.config.type == 'deck' then
                                self.children.back:draw(overlay)
                            else
                                self.children.back:draw_shader('dissolve')
                            end

                            if self.sticker and G.shared_stickers[self.sticker] then
                                G.shared_stickers[self.sticker].role.draw_major = self
                                G.shared_stickers[self.sticker]:draw_shader('dissolve', nil, nil, true,
                                    self.children.center)
                                if self.sticker == 'Gold' then
                                    G.shared_stickers[self.sticker]:draw_shader('voucher', nil,
                                        self.ARGS.send_to_shader, true, self.children.center)
                                end
                            end
                        end

                        if self.children.overwrite and self.tilt_var then

                            self.children.overwrite.overwrite_tilt_var = copy_table(self.tilt_var)

                        end

                        for k, v in pairs(self.children) do
                            if k ~= 'focused_ui' and k ~= "front" and k ~= "overwrite" and k ~= "back" and k ~=
                                "soul_parts" and k ~= "center" and k ~= 'floating_sprite' and k ~= "shadow" and k ~=
                                "use_button" and k ~= 'buy_button' and k ~= 'buy_and_use_button' and k ~= "debuff" and k ~=
                                'price' and k ~= 'particles' and k ~= 'h_popup' then
                                v:draw()
                            end
                        end

                        if self.children.overwrite then
                            love.graphics.push()
                            love.graphics.setColor(G.C.BLUE)
                            G.BRUTE_OVERLAY = {1, 1, 1, math.sin(5 * G.TIMERS.REAL)}
                            self.children.overwrite:draw('card')
                            G.BRUTE_OVERLAY = nil
                            love.graphics.pop()
                        end

                        if (layer == 'card' or layer == 'both') and self.area == G.hand then
                            if self.children.focused_ui then
                                self.children.focused_ui:draw()
                            end
                        end

                        add_to_drawhash(self)
                        self:draw_boundingrect()
                    end
                else
                    draw_ref(self, layer)
                end
            end
        else
            logger:warn("Invalid shader provided, " .. newSeal.id .. " " .. shader)
        end
    end
    color = string.upper(color)
    if G.BADGE_COL then
        G.BADGE_COL[newSeal.loc_id] = G.C[color]
    else
        G.BADGE_COL = G.BADGE_COL or {
            eternal = G.C.ETERNAL,
            foil = G.C.DARK_EDITION,
            holographic = G.C.DARK_EDITION,
            polychrome = G.C.DARK_EDITION,
            negative = G.C.DARK_EDITION,
            gold_seal = G.C.GOLD,
            red_seal = G.C.RED,
            blue_seal = G.C.BLUE,
            purple_seal = G.C.PURPLE,
            pinned_left = G.C.ORANGE
        }
        G.BADGE_COL[newSeal.loc_id] = G.C[color]
    end

    for k, v in pairs(G.P_SEALS) do
        table.sort(v, function(a, b)
            return a.order < b.order
        end)
    end
    table.sort(G.P_CENTER_POOLS["Seal"], function(a, b)
        return a.order < b.order
    end)

    table.insert(seal.effects, args.effect)
    seal.timings[#seal.timings + 1] = {args.timing, #seal.effects}
    seal.seals[newSeal.id] = {
        pool_indices = {#G.P_CENTER_POOLS['Seal'], #seal.effects, #seal.timings},
        loc_id = newSeal.loc_id,
        color = color
    }
    setData({
        loc_id = newSeal.loc_id,
        info = false
    })
end

local function unregisterSeal(id)
    if seal.seals[id] then
        G.P_CENTER_POOLS['Seal'][seal.seals[id].pool_indices[1]] = nil
        G.P_SEALS[id] = nil
        G.localization.descriptions.Other[seal.seals[id].loc_id] = nil
        G.localization.misc.labels[seal.seals[id].loc_id] = nil
        seal.seals[id] = nil
        seal.effects[seal.seals[id].pool_indices[2]] = nil
        seal.timings[seal.seals[id].pool_indices[3]] = nil
    end
end

-- If you're creating another card that references a Seal object in its description, run this to add that tooltip.
-- Example input: set="Spectral", name="Deja Vu", seal_id="Red" or "red"
-- This function will generate the necessary colors for any text using the given color of the added seal.
-- To use these colors in your description, add "{C:[colorname]}text{}"" to your description, in lowercase without the square brackets.
local function addSealInfotip(set, name, seal_id)
    local loc_id, color = seal.seals[seal_id].loc_id, seal.seals[seal_id].color
    setData({
        loc_id = loc_id,
        set = set,
        name = name,
        info = true
    })
    if G.C[string.upper(color)] then
        if G.ARGS.LOC_COLOURS then
            G.ARGS.LOC_COLOURS[string.lower(color)] = G.C[string.upper(color)]
        else
            G.ARGS.LOC_COLOURS = G.ARGS.LOC_COLOURS or {
                red = G.C.RED,
                mult = G.C.MULT,
                blue = G.C.BLUE,
                chips = G.C.CHIPS,
                green = G.C.GREEN,
                money = G.C.MONEY,
                gold = G.C.GOLD,
                attention = G.C.FILTER,
                purple = G.C.PURPLE,
                white = G.C.WHITE,
                inactive = G.C.UI.TEXT_INACTIVE,
                spades = G.C.SUITS.Spades,
                hearts = G.C.SUITS.Hearts,
                clubs = G.C.SUITS.Clubs,
                diamonds = G.C.SUITS.Diamonds,
                tarot = G.C.SECONDARY_SET.Tarot,
                planet = G.C.SECONDARY_SET.Planet,
                spectral = G.C.SECONDARY_SET.Spectral,
                edition = G.C.EDITION,
                dark_edition = G.C.DARK_EDITION,
                legendary = G.C.RARITY[4],
                enhanced = G.C.SECONDARY_SET.Enhanced
            }
            G.ARGS.LOC_COLOURS[string.lower(color)] = G.C[string.upper(color)]
        end
    else
        logger:warn("Invalid color provided.")
    end
end

local _MODULE = seal
_MODULE.registerSeal = registerSeal
_MODULE.unregisterSeal = unregisterSeal
_MODULE.addSealInfotip = addSealInfotip
return _MODULE
