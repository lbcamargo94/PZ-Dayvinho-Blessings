-- ============================================================
--  Curses.lua — Sistema de maldições do Dayvinho de Bolso
--
--  Acionado quando o jogador tem o item no inventário e executa
--  uma das 5 ações proibidas no menu de contexto:
--    burn, destroy, trash, explode, run (atropelar)
--
--  9 efeitos possíveis, duração 10 minutos reais (600s)
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
    bad_luck = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local ok, prev = pcall(function() return s:getLuck() end)
            data.prev = ok and prev or 0
            pcall(function() s:setLuck(data.prev - 10) end)
        end,
        onRemove = function(player, data)
            local s = stats(player); if not s then return end
            pcall(function() s:setLuck(data.prev or 0) end)
        end,
    },

    panic_faster = {
        apply = function(player, data)
            data.rate = 0.003
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getPanic() or 0
            pcall(function() s:setPanic(clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    hunger_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getHunger() or 0
            pcall(function() s:setHunger(clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    thirst_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getThirst() or 0
            pcall(function() s:setThirst(clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    endurance_down = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getEndurance() or 0
            pcall(function() s:setEndurance(clamp(cur - 0.10, 0, 1)) end)
        end,
    },

    -- Ruído interno do B42 não tem API cliente direta;
    -- aumento de pânico gradual como substituto
    more_noise = {
        apply = function(player, data)
            data.rate = 0.002
        end,
        onTick = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getPanic() or 0
            pcall(function() s:setPanic(clamp(cur + data.rate, 0, 1)) end)
        end,
    },

    unhappiness_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getUnhappiness() or 0
            pcall(function() s:setUnhappiness(clamp(cur + 0.20, 0, 1)) end)
        end,
    },

    stress_up = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getStress() or 0
            pcall(function() s:setStress(clamp(cur + 0.15, 0, 1)) end)
        end,
    },

    -- Efeito visual: apenas narrativo + infelicidade leve
    hallucination = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:getUnhappiness() or 0
            pcall(function() s:setUnhappiness(clamp(cur + 0.10, 0, 1)) end)
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
            local name = rawget(opt, "name") or ""
            local trigger = triggerTypeForLabel(tostring(name))
            if trigger then
                local origOnSelect = rawget(opt, "onSelect")
                opt.onSelect = function(...)
                    if origOnSelect then
                        local ok = pcall(origOnSelect, ...)
                    end
                    if DayvinhoBlessings_Main then
                        DayvinhoBlessings_Main.triggerCurse(player, trigger)
                    end
                end
            end
        end
    end
end

-- ── Hook no menu de contexto ──────────────────────────────────

local function onContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    if not playerHasDayvinho(player) then return end

    pcall(wrapDestructiveOptions, context, player)
end

-- Registra apenas uma vez
if not DayvinhoBlessings_Curses._contextMenuRegistered then
    Events.OnFillInventoryObjectContextMenu.Add(onContextMenu)
    DayvinhoBlessings_Curses._contextMenuRegistered = true
end