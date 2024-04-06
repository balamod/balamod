local _MODULE = {}
_MODULE._VERSION = "1.0.0"

local balamod = require("balamod")
local logging = require("logging")
local logger = logging.getLogger("challenge")
local utils = require("utils")
_MODULE.logger = logger
_MODULE.challenges = {}

-- The game implements these custom rules already, it's done for challenge
-- validation purposes. When the challenge API supports adding custom rulesets,
-- the custom rules will be added to this list so that all challenges may use them.
_MODULE.customRules = {
    "no_reward_specific",
    "no_reward",
    "no_extra_hand_money",
    "no_interest",
    "chips_dollar_cap",
    "flipped_cards",
    "minus_hand_size_per_X_dollar",
    "all_eternal",
    "debuff_played_cards",
    "set_eternal_ante",
    "set_joker_slots_ante",
    "inflation",
    "no_shop_jokers",
    "discard_cost",
    "set_seed",
}

_MODULE.modifiers = {
    "dollars",
    "discards",
    "hands",
    "reroll_cost",
    "joker_slots",
    "consumable_slots",
    "hand_size",
}

local function isIdInTable(id, theTable)
    for _, value in ipairs(theTable) do
        if value.id == id then
            return true
        end
    end
    return false
end

local function isValueForIdInTable(id, value, theTable)
    for _, v in ipairs(theTable) do
        if v.id == id and v.value == value then
            return true
        end
    end
    return false
end

local function validateChallengeId(challengeId)
    if challengeId == nil then
        error("Challenge ID is nil")
    end
    if string.match(challengeId, "c_[a-z_]+_[0-9]+") == nil then
        error("Invalid challenge ID: " .. challengeId)
    end
    return challengeId
end

local function validateChallengeName(name)
    if name == nil then
        error("Challenge name is nil")
    end
    return name
end

local function validateChallengeRules(rules)
    if rules == nil then
        return {}  -- just means there's no rules
    end
    if type(rules) ~= 'table' then
        error("Rules are not a table")
    end
    for i, rule in ipairs(rules) do
        if type(rule) == 'string' then
            rules[i] = { id = rule }  -- we assume it's a rule ID
        elseif rule.id == nil then
            error("Rule ID is nil")
        end
    end
    -- validate rules exists
    local nonExistingRules = utils.filter(rules, function(rule) return utils.contains(_MODULE.customRules, rule.id) end)
    if #nonExistingRules > 0 then
        error("Rules do not exist: " .. utils.stringify(utils.map(nonExistingRules, function(rule) return rule.id end)))
    end
    return rules
end

local function validateChallengeModifiers(modifiers)
    if modifiers == nil then
        return {}  -- just means there's no modifiers
    end
    if type(modifiers) ~= 'table' then
        error("Modifiers are not a table")
    end
    for i, modifier in ipairs(modifiers) do
        if modifier.id == nil then
            error("Modifier ID is nil")
        end
        if modifier.value == nil then
            error("Modifier value is nil")
        end
    end
    -- validate modifiers exists
    local nonExistingModifiers = utils.filter(modifiers, function(modifier) return utils.contains(_MODULE.modifiers, modifier.id) end)
    if #nonExistingModifiers > 0 then
        error("Modifiers do not exist: " .. utils.stringify(utils.map(nonExistingModifiers, function(modifier) return modifier.id end)))
    end
    return modifiers
end

local function validateChallengeJokers(jokers)
    if jokers == nil then
        return {}  -- just means there's no jokers
    end
    if type(jokers) ~= 'table' then
        error("Jokers are not a table")
    end
    for i, joker in ipairs(jokers) do
        if type(joker) == 'string' then
            jokers[i] = { id = joker }  -- we assume it's a joker ID
        elseif joker.id == nil then
            error("Joker ID is nil")
        end
    end
    return jokers
end

local function validateChallengeConsumeables(consumeables)
    if consumeables == nil then
        return {}  -- just means there's no consumeables
    end
    if type(consumeables) ~= 'table' then
        error("Consumeables are not a table")
    end
    for i, consumeable in ipairs(consumeables) do
        if type(consumeable) == 'string' then
            consumeables[i] = { id = consumeable }  -- we assume it's a consumeable ID
        elseif consumeable.id == nil then
            error("Consumeable ID is nil")
        end
    end
    return consumeables
end

local function validateChallengeVouchers(vouchers)
    if vouchers == nil then
        return {}  -- just means there's no vouchers
    end
    if type(vouchers) ~= 'table' then
        error("Vouchers are not a table")
    end
    for i, voucher in ipairs(vouchers) do
        if type(voucher) == 'string' then
            vouchers[i] = { id = voucher }  -- we assume it's a voucher ID
        elseif voucher.id == nil then
            error("Voucher ID is nil")
        end
    end
    return vouchers
end

local function validateChallengeDeck(deck)
    if deck == nil then
        return {}  -- just means there's no deck
    end
    if type(deck) ~= 'table' then
        error("Deck is not a table")
    end
    if deck.type ~= "Challenge Deck" then
        deck.type = "Challenge Deck"
    end
    return deck
end

function _MODULE:add(
    challenge_id,
    name,
    rules,
    modifiers,
    jokers,
    consumeables,
    vouchers,
    deck,
    banned_cards,
    banned_tags,
    banned_other,
)
    if self.challenges[name] ~= nil then
        logger:warn("Challenge already exists: " .. name)
        return nil
    end
    challenge_id = validateChallengeId(challenge_id)
    name = validateChallengeName(name)
    rules = validateChallengeRules(rules)
    modifiers = validateChallengeModifiers(modifiers)
    jokers = validateChallengeJokers(jokers)
    consumeables = validateChallengeConsumeables(consumeables)
    vouchers = validateChallengeVouchers(vouchers)
    deck = validateChallengeDeck(deck)
    banned_cards = validateChallengeBannedCards(banned_cards)
    banned_tags = validateChallengeBannedTags(banned_tags)
    banned_other = banned_other or {}
    local challenge = {
        id = challenge_id,
        name = name,
        rules = {
            custom = rules,
            modifiers = modifiers,
        },
        jokers = jokers,
        consumeables = consumeables,
        vouchers = vouchers,
        deck = deck,
        restrictions = {
            banned_cards = banned_cards,
            banned_tags = banned_tags,
            banned_other = banned_other,
        },
    }
    self.challenges[name] = challenge
    table.insert(G.CHALLENGES, challenge)  -- add to the game

    logger:info("Challenge added:", name)
end

function _MODULE:remove(name)
    if self.challenges[name] ~= nil then
        self.challenges[name] = nil
        self.logger:info("Challenge removed: " .. name)
    else
        self.logger:warn("Challenge does not exist: " .. name)
    end
end

return _MODULE
