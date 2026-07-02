-- ============================================================
--  Blessings.lua — Definição dos 24 tipos de bênção
--
--  Cada entrada contém:
--    weight   : peso na rolagem aleatória (maior = mais frequente)
--    duration : duração em segundos reais (0 = instantâneo)
--    apply    : function(player, isLegendary, data) chamada ao ativar
--    onTick   : function(player, data) chamada a cada ~2s enquanto ativa
--    onRemove : function(player, data) chamada ao expirar
-- ============================================================

require "DayvinhoBlessings/Messages"

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
        weight = 15, duration = 900,  -- 15 min
        apply = function(player, legendary, data)
            data.mult = legendary and 0.20 or 0.10
        end,
        onRemove = function(player, data) data.mult = 0 end,
    },

    -- ── Sorte ────────────────────────────────────────────────
    luck = {
        weight = 8, duration = 1800,  -- 30 min
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local ok, prev = pcall(function() return s:getLuck() end)
            data.prev = ok and prev or 0
            local bonus = legendary and 15 or 10
            pcall(function() s:setLuck(data.prev + bonus) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:setLuck(data.prev or 0) end)
        end,
    },

    -- ── Achado Valioso: foraging radius +15% ─────────────────
    foraging = {
        weight = 6, duration = 600,  -- 10 min
        apply = function(player, legendary, data)
            local bonus = legendary and 0.22 or 0.15
            data.bonus = bonus
            pcall(function() player:setForagingRadius(
                (player:getForagingRadius() or 0) + bonus) end)
        end,
        onRemove = function(player, data)
            pcall(function() player:setForagingRadius(
                math.max(0, (player:getForagingRadius() or 0) - (data.bonus or 0))) end)
        end,
    },

    -- ── Presente do Jardim: item aleatório ────────────────────
    gift = {
        weight = 5, duration = 0,
        apply = function(player, legendary, data)
            local itemType = GIFT_ITEMS[math.random(#GIFT_ITEMS)]
            if legendary then
                -- dois itens no lendário
                pcall(function() player:getInventory():AddItem(itemType) end)
                local extra = GIFT_ITEMS[math.random(#GIFT_ITEMS)]
                pcall(function() player:getInventory():AddItem(extra) end)
            else
                pcall(function() player:getInventory():AddItem(itemType) end)
            end
        end,
    },

    -- ── Barriga Cheia: reduz fome ao longo do tempo ───────────
    full_belly = {
        weight = 8, duration = 1800,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.004 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getHunger() or 0
            pcall(function() s:setHunger(clamp(cur - data.rate, 0, 1)) end)
        end,
    },

    -- ── Água Fresca: reduz sede imediatamente ─────────────────
    fresh_water = {
        weight = 8, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.70 or 0.50
            local cur = s:getThirst() or 0
            pcall(function() s:setThirst(clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Descanso Revigorante: reduz fadiga ────────────────────
    rest = {
        weight = 8, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.25 or 0.15
            local cur = s:getFatigue() or 0
            pcall(function() s:setFatigue(clamp(cur - pct, 0, 1)) end)
        end,
    },

    -- ── Espírito Forte: reduz estresse e tédio gradualmente ───
    spirit = {
        weight = 7, duration = 1800,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function()
                s:setStress(clamp((s:getStress() or 0) - data.rate, 0, 1))
                s:setBoredom(clamp((s:getBoredom() or 0) - data.rate, 0, 1))
            end)
        end,
    },

    -- ── Bom Humor: reduz infelicidade ─────────────────────────
    good_mood = {
        weight = 7, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.40 or 0.25
            local cur = s:getUnhappiness() or 0
            pcall(function() s:setUnhappiness(clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Paz Interior: reduz estresse ──────────────────────────
    inner_peace = {
        weight = 7, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local pct = legendary and 0.45 or 0.30
            local cur = s:getStress() or 0
            pcall(function() s:setStress(clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Sono Tranquilo: flag para próximo sono ────────────────
    calm_sleep = {
        weight = 4, duration = 0,
        apply = function(player, legendary, data)
            local md = player:getModData()
            md.DayvinhoBlessings = md.DayvinhoBlessings or {}
            md.DayvinhoBlessings.calmSleepPending = true
            md.DayvinhoBlessings.calmSleepLegendary = legendary == true
        end,
    },

    -- ── Mãos Habilidosas: velocidade de ação +10% ─────────────
    skilled_hands = {
        weight = 5, duration = 1200,  -- 20 min
        apply = function(player, legendary, data)
            local mult = legendary and 0.15 or 0.10
            data.mult = mult
            pcall(function()
                player:getStats():setWalkingSpeed(
                    (player:getStats():getWalkingSpeed() or 1) + mult * 0.2)
            end)
        end,
        onRemove = function(player, data)
            pcall(function()
                player:getStats():setWalkingSpeed(
                    math.max(0.5, (player:getStats():getWalkingSpeed() or 1) - (data.mult or 0) * 0.2))
            end)
        end,
    },

    -- ── Pescador Abençoado: bônus de pesca ───────────────────
    fisherman = {
        weight = 4, duration = 1800,
        apply = function(player, legendary, data)
            local bonus = legendary and 0.15 or 0.10
            data.bonus = bonus
            pcall(function() player:setFishingMultiplier(
                (player:getFishingMultiplier() or 1) + bonus) end)
        end,
        onRemove = function(player, data)
            pcall(function() player:setFishingMultiplier(
                math.max(0, (player:getFishingMultiplier() or 1) - (data.bonus or 0))) end)
        end,
    },

    -- ── Colheita Feliz: crescimento de plantas ────────────────
    harvest = {
        weight = 3, duration = 1800,
        apply = function(player, legendary, data)
            -- Crescimento de plantas é server-side; aplica bônus de espírito como surrogate
            local s = stats(player); if not s then return end
            pcall(function() s:setStress(clamp((s:getStress() or 0) - 0.05, 0, 1)) end)
        end,
    },

    -- ── Lenhador Sortudo ─────────────────────────────────────
    lumberjack = {
        weight = 3, duration = 1200,
        apply = function(player, legendary, data)
            -- Rende de árvores é server-side; aplica bônus de endurance como surrogate
            local s = stats(player); if not s then return end
            local cur = s:getEndurance() or 0
            pcall(function() s:setEndurance(clamp(cur + 0.10, 0, 1)) end)
        end,
    },

    -- ── Passos Leves: menos ruído ─────────────────────────────
    light_steps = {
        weight = 5, duration = 1200,
        apply = function(player, legendary, data)
            data.applied = true
            -- Ruído interno é complex no B42; reduz pânico como efeito surrogate
            local s = stats(player); if not s then return end
            local cur = s:getPanic() or 0
            pcall(function() s:setPanic(clamp(cur - 0.05, 0, 1)) end)
        end,
    },

    -- ── Olhos Atentos: raio de foraging ──────────────────────
    sharp_eyes = {
        weight = 4, duration = 1200,
        apply = function(player, legendary, data)
            local bonus = legendary and 0.20 or 0.12
            data.bonus = bonus
            pcall(function() player:setForagingRadius(
                (player:getForagingRadius() or 0) + bonus) end)
        end,
        onRemove = function(player, data)
            pcall(function() player:setForagingRadius(
                math.max(0, (player:getForagingRadius() or 0) - (data.bonus or 0))) end)
        end,
    },

    -- ── Instinto de Sobrevivência: reduz pânico ───────────────
    instinct = {
        weight = 3, duration = 600,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            local cur = s:getPanic() or 0
            local pct = legendary and 0.20 or 0.10
            pcall(function() s:setPanic(clamp(cur * (1 - pct), 0, 1)) end)
        end,
    },

    -- ── Mochila Organizada: -5% peso efetivo ─────────────────
    backpack = {
        weight = 4, duration = 1800,
        apply = function(player, legendary, data)
            local pct = legendary and 0.10 or 0.05
            data.pct = pct
            pcall(function()
                local inv = player:getInventory()
                local max = inv:getMaxWeight() or 20
                data.origMax = max
                inv:setMaxWeight(max * (1 + pct))
            end)
        end,
        onRemove = function(player, data)
            pcall(function()
                if data.origMax then
                    player:getInventory():setMaxWeight(data.origMax)
                end
            end)
        end,
    },

    -- ── Cura Natural: recuperação de ferimentos ───────────────
    natural_heal = {
        weight = 6, duration = 1800,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            pcall(function()
                local bd = player:getBodyDamage()
                local hp = bd:getOverallBodyHealth() or 100
                if hp < 100 then
                    bd:setOverallBodyHealth(math.min(100, hp + data.rate))
                end
            end)
        end,
    },

    -- ── Corpo Resistente: restaura endurance gradualmente ─────
    resistant = {
        weight = 6, duration = 1200,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.004 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getEndurance() or 0
            pcall(function() s:setEndurance(clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    -- ── Bênção da Coragem: reduz pânico gradualmente ─────────
    courage = {
        weight = 5, duration = 1800,
        apply = function(player, legendary, data)
            data.rate = legendary and 0.003 or 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getPanic() or 0
            pcall(function() s:setPanic(clamp(cur - data.rate, 0, 1)) end)
        end,
    },

    -- ── Sol Abençoado: tenta parar a chuva ───────────────────
    sun = {
        weight = 3, duration = 0,
        apply = function(player, legendary, data)
            pcall(function()
                local climate = getClimateManager()
                if climate and climate:isRaining() then
                    climate:stopRaining()
                end
            end)
        end,
    },

    -- ── Arco-Íris: apenas mensagem + humor ───────────────────
    rainbow = {
        weight = 2, duration = 0,
        apply = function(player, legendary, data)
            local s = stats(player); if not s then return end
            pcall(function() s:setUnhappiness(clamp((s:getUnhappiness() or 0) - 0.05, 0, 1)) end)
        end,
    },
}

-- ── Weighted random picker ────────────────────────────────────

local _totalWeight = 0
do
    for _, def in pairs(DEFS) do _totalWeight = _totalWeight + def.weight end
end

function DayvinhoBlessings_Blessings.pickRandom()
    local roll = math.random() * _totalWeight
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