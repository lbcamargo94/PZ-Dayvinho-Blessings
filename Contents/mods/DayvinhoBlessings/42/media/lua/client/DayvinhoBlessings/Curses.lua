-- ============================================================
--  Curses.lua — Sistema de maldições do Dayvinho de Bolso
--
--  Acionado quando o jogador tem o item no inventário e executa
--  uma ação destrutiva via menu de contexto de objeto no mundo.
--
--  Hook: OnFillWorldObjectContextMenu
--    (OnFillInventoryObjectContextMenu NÃO recebe opções
--     Burn/Destroy/Trash/Explode/RunOver no B42)
--
--  9 efeitos possíveis, duração 10 minutos reais (600s)
--
--  API de stats (B42): CharacterStat enum
--    getLuck/setLuck (inexistentes) → CharacterStat.MORALE
-- ============================================================

require "DayvinhoBlessings/Messages"

DayvinhoBlessings_Curses = {}

-- ── Helpers internos ──────────────────────────────────────────

local function stats(player)
    local ok, s = pcall(function() return player:getStats() end)
    return ok and s or nil
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local CURSE_DURATION = 600  -- 10 minutos reais

-- ── 9 definições de efeito de maldição ───────────────────────

local CURSE_EFFECTS = {

    -- Má Sorte: reduz morale (surrogate; getLuck/setLuck não existem no B42)
    bad_luck = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local prev   = s:get(CharacterStat.MORALE) or 0
            data.prev    = prev
            pcall(function() s:set(CharacterStat.MORALE, clamp(prev - 0.10, 0, 1)) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:set(CharacterStat.MORALE, data.prev or 0) end)
        end,
    },

    -- Pânico Acelerado: aumenta pânico gradualmente
    panic_faster = {
        apply = function(player, data)
            data.rate = 0.003
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PANIC) or 0
            pcall(function() s:set(CharacterStat.PANIC, clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    -- Fome Repentina: +20% de fome imediata
    hunger_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.HUNGER) or 0
            pcall(function() s:set(CharacterStat.HUNGER, clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    -- Sede Repentina: +20% de sede imediata
    thirst_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.THIRST) or 0
            pcall(function() s:set(CharacterStat.THIRST, clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    -- Corpo Fraco: -10% de endurance imediata
    endurance_down = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.ENDURANCE) or 0
            pcall(function() s:set(CharacterStat.ENDURANCE, clamp(cur - 0.10, 0, 1)) end)
        end,
    },

    -- Mais Barulho: aumento de pânico gradual (ruído surrogate)
    more_noise = {
        apply = function(player, data)
            data.rate = 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.PANIC) or 0
            pcall(function() s:set(CharacterStat.PANIC, clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    -- Infelicidade: +20% de infelicidade imediata
    unhappiness_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.UNHAPPINESS) or 0
            pcall(function() s:set(CharacterStat.UNHAPPINESS, clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    -- Estresse: +15% de estresse imediato
    stress_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.STRESS) or 0
            pcall(function() s:set(CharacterStat.STRESS, clamp(cur + 0.15, 0, 1)) end)
        end,
    },

    -- Alucinação: narrativo + infelicidade leve
    hallucination = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.UNHAPPINESS) or 0
            pcall(function() s:set(CharacterStat.UNHAPPINESS, clamp(cur + 0.10, 0, 1)) end)
        end,
    },
}

local _effectIds = {}
for id in pairs(CURSE_EFFECTS) do _effectIds[#_effectIds + 1] = id end

function DayvinhoBlessings_Curses.getDef(id)
    return CURSE_EFFECTS[id]
end

function DayvinhoBlessings_Curses.pickRandomEffect()
    return _effectIds[math.random(#_effectIds)]
end

function DayvinhoBlessings_Curses.getDuration()
    return CURSE_DURATION
end

-- ── Verificação de posse do item ──────────────────────────────

local ITEM_TYPE = "Base.DayvinhoDeBolso"

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsType(ITEM_TYPE)
    end)
    return ok and has
end

-- ── Mapeamento nome de opção → tipo de maldição ───────────────

local TRIGGER_LABELS = {
    burn    = { "burn", "queimar", "light fire", "atear fogo", "set fire" },
    destroy = { "destroy", "destruir", "smash", "quebrar", "break" },
    trash   = { "trash", "lixo", "throw away", "discard", "descartar", "delete", "deletar", "remove" },
    explode = { "explode", "explodir", "detonate", "detonar" },
    run     = { "run over", "atropelar", "drive over", "crush" },
}

local function triggerTypeForLabel(label)
    if not label then return nil end
    local lo = label:lower()
    for triggerType, patterns in pairs(TRIGGER_LABELS) do
        for _, pattern in ipairs(patterns) do
            if lo:find(pattern, 1, true) then return triggerType end
        end
    end
    return nil
end

-- ── Wrapping de opções do menu de contexto ────────────────────
-- Em B42, context.options é uma tabela Lua com entradas { name, onSelect, ... }
-- Envolvemos cada opção destrutiva encontrada com um callback extra.

local function wrapDestructiveOptions(context, player)
    local opts = rawget(context, "options")
    if type(opts) ~= "table" then return end

    for _, opt in ipairs(opts) do
        if type(opt) == "table" then
            local name    = rawget(opt, "name") or ""
            local trigger = triggerTypeForLabel(tostring(name))
            if trigger then
                local origOnSelect = rawget(opt, "onSelect")
                opt.onSelect = function(...)
                    if origOnSelect then
                        pcall(origOnSelect, ...)
                    end
                    if DayvinhoBlessings_Main then
                        DayvinhoBlessings_Main.triggerCurse(player, trigger)
                    end
                end
            end
        end
    end
end

-- ── Hook no menu de contexto de objetos no mundo ─────────────
-- OnFillWorldObjectContextMenu inclui opções Burn/Destroy que
-- OnFillInventoryObjectContextMenu não possui no B42.

local function onContextMenu(playerNum, context, worldobjects, test)
    local player
    if type(playerNum) == "number" then
        player = getSpecificPlayer(playerNum)
    else
        player = playerNum
    end
    if not player then return end
    if not playerHasDayvinho(player) then return end

    pcall(wrapDestructiveOptions, context, player)
end

-- Registra apenas uma vez
if not DayvinhoBlessings_Curses._contextMenuRegistered then
    Events.OnFillWorldObjectContextMenu.Add(onContextMenu)
    DayvinhoBlessings_Curses._contextMenuRegistered = true
end