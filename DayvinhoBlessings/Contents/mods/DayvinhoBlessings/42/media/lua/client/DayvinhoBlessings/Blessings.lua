-- ============================================================
--  Blessings.lua — Definição dos 24 tipos de bênção
--
--  Cada entrada contém:
--    weight   : peso na rolagem aleatória (maior = mais frequente)
--    duration : duração em segundos reais (0 = instantâneo)
--    apply    : function(player, isLegendary, data) chamada ao ativar
--    onTick   : function(player, data) chamada a cada ~2s enquanto ativa
--    onRemove : function(player, data) chamada ao expirar
--
--  API de stats (B42): CharacterStat enum
--    s:get(CharacterStat.X)    — lê valor atual (escala 0-1)
--    s:set(CharacterStat.X, v) — define valor absoluto
--  APIs inexistentes em B42 substituídas por surrogates:
--    setLuck/getLuck          → CharacterStat.MORALE
--    setForagingRadius        → CharacterStat.MORALE
--    setFishingMultiplier     → CharacterStat.MORALE
--    setWalkingSpeed          → CharacterStat.ENDURANCE
--    getOverallBodyHealth/setOverallBodyHealth → CharacterStat.PAIN
-- ============================================================

require "DayvinhoBlessings/Messages"
require "DayvinhoBlessings/Logger"

DayvinhoBlessings_Blessings = {}

-- ── Helpers internos ──────────────────────────────────────────

local function stats(player)
    local ok, s = pcall(function() return player:getStats() end)
    return ok and s or nil
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local GIFT_ITEMS = {
    "Base.Mushroom", "Base.Worm",  "Base.Twigs",
    "Base.Flint",    "Base.TomatoSeeds", "Base.WildGarlic",
}

-- ── Definições ────────────────────────────────────────────────

local DEFS = {

    -- ── XP Boost: +10% / +20% via LevelPerk (tratado no Main) ──
    xp_boost = {
        weight = 15, duration = 300,  -- 5 min (teste)
        apply = function(player, legendary, data)
            data.mult = legendary and 0.20 or 0.10
        end,
        onRemove = function(player, data) data.mult = 0 end,
    },

    -- ── Sorte: morale boost (getLuck/setLuck não existem no B42) ──
    luck = {
        weight = 8, duration = 300,  -- 5 min (teste)
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local prev  = s:get(CharacterStat.MORALE) or 0
            data.prev   = prev
            local bonus = legendary and 0.15 or 0.10
            data.bonus  = bonus
            pcall(function() s:set(CharacterStat.MORALE, clamp(prev + bonus, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:set(CharacterStat.MORALE, data.prev or 0) end)
        end,
    },

    -- ── Achado Valioso: morale boost (setForagingRadius não existe no B42) ──
    foraging = {
        weight = 6, duration = 300,  -- 5 min (teste)
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local prev  = s:get(CharacterStat.MORALE) or 0
            data.prev   = prev
            local bonus = legendary and 0.22 or 0.15
            data.bonus  = bonus
            pcall(function() s:set(CharacterStat.MORALE, clamp(prev + bonus, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:set(CharacterStat.MORALE, data.prev or 0) end)
        end,
    },

    -- ── Presente do Jardim: item aleatório ────────────────────
    gift = {
        weight = 5, duration = 0,
        apply = function(player, legendary, data)
            local itemType = GIFT_ITEMS[ZombRand(#GIFT_ITEMS) + 1]
            if legendary then
                pcall(function() player:getInventory():AddItem(itemType) end)
                local extra = GIFT_ITEMS[ZombRand(#GIFT_ITEMS) + 1]
                pcall(function() player:getInventory():AddItem(extra) end)
            else
                pcall(function() player:getInventory():AddItem(itemType) end)
            end
        end,
    },

    -- ── Barriga Cheia: reduz fome ao longo do tempo ───────────
    full_belly = {
        weight = 8, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.004 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.HUNGER) or 0
            pcall(function() s:set(CharacterStat.HUNGER, clamp(cur - data.rate, 0, 1)) end)
        end,
    },

    -- ── Água Fresca: reduz sede imediatamente ─────────────────
    fresh_water = {
        weight = 8, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.70 or 0.50
            local cur = s:get(CharacterStat.THIRST) or 0
            pcall(function() s:set(CharacterStat.THIRST, clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Descanso Revigorante: reduz fadiga ────────────────────
    rest = {
        weight = 8, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.25 or 0.15
            local cur = s:get(CharacterStat.FATIGUE) or 0
            pcall(function() s:set(CharacterStat.FATIGUE, clamp(cur - pct, 0, 1)) end)
        end,
    },

    -- ── Espírito Forte: reduz estresse e tédio gradualmente ───
    spirit = {
        weight = 7, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function()
                local stress  = s:get(CharacterStat.STRESS)  or 0
                local boredom = s:get(CharacterStat.BOREDOM) or 0
                s:set(CharacterStat.STRESS,  clamp(stress  - data.rate, 0, 1))
                s:set(CharacterStat.BOREDOM, clamp(boredom - data.rate, 0, 1))
            end)
        end,
    },

    -- ── Bom Humor: reduz infelicidade ─────────────────────────
    good_mood = {
        weight = 7, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.40 or 0.25
            local cur = s:get(CharacterStat.UNHAPPINESS) or 0
            pcall(function() s:set(CharacterStat.UNHAPPINESS, clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Paz Interior: reduz estresse ──────────────────────────
    inner_peace = {
        weight = 7, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.45 or 0.30
            local cur = s:get(CharacterStat.STRESS) or 0
            pcall(function() s:set(CharacterStat.STRESS, clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Sono Tranquilo: flag para próximo sono ────────────────
    calm_sleep = {
        weight = 4, duration = 0,
        apply = function(player, legendary, data)
            local md = player:getModData()
            md.DayvinhoBlessings = md.DayvinhoBlessings or {}
            md.DayvinhoBlessings.calmSleepPending   = true
            md.DayvinhoBlessings.calmSleepLegendary = legendary == true
        end,
    },

    -- ── Mãos Habilidosas: endurance boost (setWalkingSpeed não existe no B42) ──
    skilled_hands = {
        weight = 5, duration = 300,  -- 5 min (teste)
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local prev  = s:get(CharacterStat.ENDURANCE) or 0
            data.prev   = prev
            local bonus = legendary and 0.15 or 0.10
            data.bonus  = bonus
            pcall(function() s:set(CharacterStat.ENDURANCE, clamp(prev + bonus, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function()
                local cur = s:get(CharacterStat.ENDURANCE) or 0
                s:set(CharacterStat.ENDURANCE, clamp(cur - (data.bonus or 0), 0, 1))
            end)
        end,
    },

    -- ── Pescador Abençoado: morale boost (setFishingMultiplier não existe no B42) ──
    fisherman = {
        weight = 4, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local prev  = s:get(CharacterStat.MORALE) or 0
            data.prev   = prev
            local bonus = legendary and 0.15 or 0.10
            data.bonus  = bonus
            pcall(function() s:set(CharacterStat.MORALE, clamp(prev + bonus, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:set(CharacterStat.MORALE, data.prev or 0) end)
        end,
    },

    -- ── Colheita Feliz: redução de estresse ───────────────────
    harvest = {
        weight = 3, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.STRESS) or 0
            pcall(function() s:set(CharacterStat.STRESS, clamp(cur - 0.05, 0, 1)) end)
        end,
    },

    -- ── Lenhador Sortudo: bônus de endurance ──────────────────
    lumberjack = {
        weight = 3, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.ENDURANCE) or 0
            pcall(function() s:set(CharacterStat.ENDURANCE, clamp(cur + 0.10, 0, 1)) end)
        end,
    },

    -- ── Passos Leves: reduz pânico ────────────────────────────
    light_steps = {
        weight = 5, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PANIC) or 0
            pcall(function() s:set(CharacterStat.PANIC, clamp(cur - 0.05, 0, 1)) end)
        end,
    },

    -- ── Olhos Atentos: morale boost (setForagingRadius não existe no B42) ──
    sharp_eyes = {
        weight = 4, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local prev  = s:get(CharacterStat.MORALE) or 0
            data.prev   = prev
            local bonus = legendary and 0.20 or 0.12
            data.bonus  = bonus
            pcall(function() s:set(CharacterStat.MORALE, clamp(prev + bonus, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:set(CharacterStat.MORALE, data.prev or 0) end)
        end,
    },

    -- ── Instinto de Sobrevivência: reduz pânico ───────────────
    instinct = {
        weight = 3, duration = 300,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PANIC) or 0
            local pct = legendary and 0.20 or 0.10
            pcall(function() s:set(CharacterStat.PANIC, clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Mochila Organizada: reduz desconforto (surrogate B42) ────
    -- inventory:setMaxWeight() não existe na API Lua B42.
    -- Surrogate: reduz DISCOMFORT gradualmente (sensação de carga mais leve)
    backpack = {
        weight = 4, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.DISCOMFORT) or 0
            if cur > 0 then
                pcall(function() s:set(CharacterStat.DISCOMFORT, clamp(cur - data.rate, 0, 1)) end)
            end
        end,
    },

    -- ── Cura Natural: reduz dor gradualmente (B42: CharacterStat.PAIN) ──
    natural_heal = {
        weight = 6, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PAIN) or 0
            if cur > 0 then
                pcall(function() s:set(CharacterStat.PAIN, clamp(cur - data.rate, 0, 1)) end)
            end
        end,
    },

    -- ── Corpo Resistente: restaura endurance gradualmente ─────
    resistant = {
        weight = 6, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.004 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.ENDURANCE) or 0
            pcall(function() s:set(CharacterStat.ENDURANCE, clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    -- ── Bênção da Coragem: reduz pânico gradualmente ─────────
    courage = {
        weight = 5, duration = 300,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PANIC) or 0
            pcall(function() s:set(CharacterStat.PANIC, clamp(cur - data.rate, 0, 1)) end)
        end,
    },

    -- ── Sol Abençoado: para a chuva via RainManager (B42) ───────
    -- RainManager.isRaining() / stopRaining() confirmados no source B42
    -- (shared/Fishing/FishingUtils.lua, server/Seasons/season.lua)
    sun = {
        weight = 3, duration = 0,
        apply = function(player, legendary, data)
            pcall(function()
                if RainManager.isRaining() then
                    RainManager.stopRaining()
                end
            end)
        end,
    },

    -- ── Arco-Íris: narrativo + redução leve de infelicidade ──
    rainbow = {
        weight = 2, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.UNHAPPINESS) or 0
            pcall(function() s:set(CharacterStat.UNHAPPINESS, clamp(cur - 0.05, 0, 1)) end)
        end,
    },
}

-- ── Weighted random picker ────────────────────────────────────

local _totalWeight = 0
do
    for _, def in pairs(DEFS) do _totalWeight = _totalWeight + def.weight end
end

function DayvinhoBlessings_Blessings.pickRandom()
    local roll = ZombRandFloat(0, 1) * _totalWeight
    local acc  = 0
    for id, def in pairs(DEFS) do
        acc = acc + def.weight
        if roll <= acc then return id end
    end
    return "xp_boost"
end

function DayvinhoBlessings_Blessings.getDef(id)
    return DEFS[id]
end