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
require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

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

    -- Som Aleatório: toca um som surpreendente do jogo e atrai zumbis
    random_sound = {
        apply = function(player, data)
            local SOUNDS = {
                "ZombieScream", "ZombieGroupMoan", "AlarmLoop",
                "CarHorn", "GunShot", "DogBark",
            }
            local picked = SOUNDS[ZombRand(#SOUNDS) + 1]
            data.soundName = picked
            -- Toca o som no mundo (outros jogadores e zumbis ouvem o ruído)
            pcall(function()
                local sm = getSoundManager()
                local sq  = player:getSquare()
                if not sm or not sq then return end
                local fn = sm.PlayWorldSound
                if fn then fn(sm, picked, sq, 0, 0, 50, 1, false) end
            end)
            -- Ruído para atrair zumbis próximos (raio 50, volume 20)
            pcall(function()
                addSound(player, player:getX(), player:getY(), player:getZ(), 50, 20)
            end)
        end,
    },

    -- Helicóptero: dispara o evento de helicóptero + ruído massivo de zumbis
    helicopter = {
        apply = function(player, data)
            -- Tenta disparar o evento real do jogo (B42: HeliEvent.Start)
            local triggered = false
            pcall(function()
                local fn = HeliEvent and HeliEvent.Start
                if fn then fn(); triggered = true end
            end)
            -- Fallback: tenta via GameTime
            if not triggered then
                pcall(function()
                    local gt = getGameTime and getGameTime()
                    local fn = gt and gt.triggerHelicopter
                    if fn then fn(gt); triggered = true end
                end)
            end
            -- Garantido: som de helicóptero + ruído enorme de zumbis
            pcall(function()
                local sm = getSoundManager()
                local sq  = player:getSquare()
                if sm and sq then
                    local fn = sm.PlayWorldSound
                    if fn then fn(sm, "HelicopterFly", sq, 0, 0, 200, 1, false) end
                end
            end)
            -- Ruído de 200 blocos para chamar zumbis do mapa inteiro
            pcall(function()
                addSound(player, player:getX(), player:getY(), player:getZ(), 200, 100)
            end)
            data.triggered = triggered
        end,
    },
}

local _effectIds = {}
for id in pairs(CURSE_EFFECTS) do _effectIds[#_effectIds + 1] = id end

function DayvinhoBlessings_Curses.getDef(id)
    return CURSE_EFFECTS[id]
end

function DayvinhoBlessings_Curses.pickRandomEffect()
    return _effectIds[ZombRand(#_effectIds) + 1]
end

function DayvinhoBlessings_Curses.getDuration()
    return CURSE_DURATION
end

-- ── Verificação de posse do item ──────────────────────────────

local ITEM_TYPE = "Base.DayvinhoDeBolso"

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsTypeRecurse(ITEM_TYPE)
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
-- Em B42, context.options é uma tabela Lua com entradas { name, onMouseUp, target, ... }
-- Envolvemos cada opção destrutiva encontrada com um callback extra.

local function wrapDestructiveOptions(context, player)
    local opts = context.options
    if type(opts) ~= "table" then return end

    for _, opt in ipairs(opts) do
        if type(opt) == "table" then
            local name    = rawget(opt, "name") or ""
            local trigger = triggerTypeForLabel(tostring(name))
            if trigger then
                Log.debug("opcao destrutiva detectada: " .. tostring(name) .. " -> " .. trigger)
                local origOnMouseUp = rawget(opt, "onMouseUp")
                opt.onMouseUp = function(target, ...)
                    if origOnMouseUp then
                        pcall(origOnMouseUp, target, ...)
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
-- OnFillWorldObjectContextMenu inclui opções Burn/Destroy/Explode/RunOver
-- que não aparecem no menu de inventário.

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

if not DayvinhoBlessings_Curses._contextMenuRegistered then
    Events.OnFillWorldObjectContextMenu.Add(onContextMenu)
    DayvinhoBlessings_Curses._contextMenuRegistered = true
    Log.info("hook OnFillWorldObjectContextMenu registrado")
end

-- ── Hook no menu de contexto do inventário (Descartar Dayvinho) ─
-- OnFillInventoryObjectContextMenu(playerNum, context, items)
-- Adiciona opção "Descartar" que remove o item e dispara maldição.
--
-- NÃO iteramos `items`: o formato varia entre mods (ex: CleanUI passa
-- tabelas Lua, não objetos Java). Chamar entry:getFullType() em tabelas
-- Lua lança RuntimeException no Kahlua que escapa do pcall do Lua.
-- Solução: buscar o Dayvinho direto do inventário do jogador.

local function getDayvinhoFromInventory(player)
    local found = nil
    pcall(function()
        local allItems = player:getInventory():getItems()
        for i = 0, allItems:size() - 1 do
            local it = allItems:get(i)
            if it and it:getFullType() == ITEM_TYPE then
                found = it
                return
            end
        end
    end)
    return found
end

local function onDiscardDayvinho(playerNum, dayvinhoItem)
    local player
    if type(playerNum) == "number" then
        player = getSpecificPlayer(playerNum)
    else
        player = playerNum
    end
    if not player then return end

    -- Sinaliza que esta remoção já será tratada aqui;
    -- o onTick em Main.lua vai ignorar a transição e não duplicar a maldição.
    if DayvinhoBlessings_Main then
        DayvinhoBlessings_Main.markDiscarded()
    end

    -- Som de remoção (onTick vai pular o som neste caso por causa do flag acima)
    pcall(function()
        local sm = getSoundManager()
        if sm and player:getSquare() then
            sm:PlayWorldSound("UICloseWindow", player:getSquare(), 0, 0, 0, 1, false)
        end
    end)

    pcall(function()
        player:getInventory():Remove(dayvinhoItem)
    end)

    if DayvinhoBlessings_Main then
        DayvinhoBlessings_Main.triggerCurse(player, "trash")
    end
end

local function onInventoryContextMenu(playerNum, context, items)
    local player
    if type(playerNum) == "number" then
        player = getSpecificPlayer(playerNum)
    else
        player = playerNum
    end
    if not player then return end

    -- Opção toggle do HUD: visível quando Dayvinho está no inventário ou há efeito ativo
    local hasDay = playerHasDayvinho(player)
    local hasEff = DayvinhoBlessings_Main and DayvinhoBlessings_Main.hasActiveEffects()
    if (hasDay or hasEff) and DayvinhoBlessings_HUD then
        local vis   = DayvinhoBlessings_HUD.isVisible()
        local label = vis and "Ocultar HUD Dayvinho" or "Mostrar HUD Dayvinho"
        context:addOption(label, nil, function() DayvinhoBlessings_HUD.toggle() end)
    end

    -- Opção Descartar: apenas se o item estiver no inventário
    if not hasDay then return end
    local dayvinhoItem = getDayvinhoFromInventory(player)
    if not dayvinhoItem then return end

    Log.debug("opcao Descartar do Dayvinho adicionada ao menu de inventario")
    context:addOption(getText("UI_DayCurse_DiscardLabel"), playerNum, onDiscardDayvinho, dayvinhoItem)
end

if not DayvinhoBlessings_Curses._inventoryMenuRegistered then
    Events.OnFillInventoryObjectContextMenu.Add(onInventoryContextMenu)
    DayvinhoBlessings_Curses._inventoryMenuRegistered = true
    Log.info("hook OnFillInventoryObjectContextMenu registrado")
end