-- ============================================================
--  Curses.lua â€” Sistema de maldiÃ§Ãµes do Dayvinho de Bolso
--
--  MaldiÃ§Ãµes sÃ£o acionadas de duas formas:
--    1. Aleatoriamente com 2% de chance a cada ciclo do timer
--       (via Main.lua â†’ tryTrigger â†’ triggerCurse("random"))
--    2. Explicitamente pelo jogador via opÃ§Ã£o "Descartar"
--       no menu de contexto do inventÃ¡rio.
--
--  11 efeitos possÃ­veis, duraÃ§Ã£o 10 minutos reais (600s)
--
--  API de stats (B42): CharacterStat enum
--    getLuck/setLuck (inexistentes) â†’ CharacterStat.MORALE
-- ============================================================

require "DayvinhoBlessings/Messages"
require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

DayvinhoBlessings_Curses = {}

-- â”€â”€ Helpers internos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local function stats(player)
    local ok, s = pcall(function() return player:getStats() end)
    return ok and s or nil
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local CURSE_DURATION = 1200  -- 20 minutos reais

-- â”€â”€ 9 definiÃ§Ãµes de efeito de maldiÃ§Ã£o â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local CURSE_EFFECTS = {

    -- MÃ¡ Sorte: reduz morale (surrogate; getLuck/setLuck nÃ£o existem no B42)
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

    -- PÃ¢nico Acelerado: aumenta pÃ¢nico gradualmente
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

    -- Mais Barulho: aumento de pÃ¢nico gradual (ruÃ­do surrogate)
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

    -- AlucinaÃ§Ã£o: narrativo + infelicidade leve
    hallucination = {
        apply = function(player, data)
            local s = stats(player); if not s then return end
            local cur = s:get(CharacterStat.UNHAPPINESS) or 0
            pcall(function() s:set(CharacterStat.UNHAPPINESS, clamp(cur + 0.10, 0, 1)) end)
        end,
    },

    -- Som AleatÃ³rio: toca um som surpreendente do jogo e atrai zumbis
    random_sound = {
        apply = function(player, data)
            local SOUNDS = {
                "ZombieScream", "ZombieGroupMoan", "AlarmLoop",
                "CarHorn", "GunShot", "DogBark",
            }
            local picked = SOUNDS[ZombRand(#SOUNDS) + 1]
            data.soundName = picked
            -- Toca o som no mundo (outros jogadores e zumbis ouvem o ruÃ­do)
            pcall(function()
                local sm = getSoundManager()
                local sq  = player:getSquare()
                if not sm or not sq then return end
                local fn = sm.PlayWorldSound
                if fn then fn(sm, picked, sq, 0, 0, 50, 1, false) end
            end)
            -- RuÃ­do para atrair zumbis prÃ³ximos (raio 50, volume 20)
            pcall(function()
                addSound(player, player:getX(), player:getY(), player:getZ(), 50, 20)
            end)
        end,
    },

    -- HelicÃ³ptero: dispara o evento de helicÃ³ptero + ruÃ­do massivo de zumbis
    helicopter = {
        apply = function(player, data)
            -- testHelicopter() e global Lua registrado por LuaManager$GlobalObject
            -- (mesmo que o painel de debug do PZ usa). Chamar nil escapa do pcall
            -- no Kahlua, entao verificamos existencia antes de chamar.
            local triggered = false
            pcall(function()
                local fn = testHelicopter
                if fn then fn(); triggered = true end
            end)
            -- RuÃ­do de 200 blocos para garantir que zumbis sejam atraÃ­dos
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

-- â”€â”€ VerificaÃ§Ã£o de posse do item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local ITEM_TYPE = "Base.DayvinhoDeBolso"

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsTypeRecurse(ITEM_TYPE)
    end)
    return ok and has
end

-- â”€â”€ Hook no menu de contexto do inventÃ¡rio (Descartar Dayvinho) â”€
-- OnFillInventoryObjectContextMenu(playerNum, context, items)
-- Adiciona opÃ§Ã£o "Descartar" que remove o item e dispara maldiÃ§Ã£o.
--
-- NÃƒO iteramos `items`: o formato varia entre mods (ex: CleanUI passa
-- tabelas Lua, nÃ£o objetos Java). Chamar entry:getFullType() em tabelas
-- Lua lanÃ§a RuntimeException no Kahlua que escapa do pcall do Lua.
-- SoluÃ§Ã£o: buscar o Dayvinho direto do inventÃ¡rio do jogador.

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

    -- Sinaliza para o onTick em Main.lua ignorar esta remoÃ§Ã£o (evita dupla maldiÃ§Ã£o).
    if DayvinhoBlessings_Main then
        DayvinhoBlessings_Main.markDiscarded()
    end

    -- Som de remoÃ§Ã£o
    -- playUISound: inicial minuscula (nome Java exato). "UICloseWindow" e som de UI,
    -- nao de mundo â€” usar PlayWorldSound com ele nao dispara o audio correto.
    pcall(function()
        local sm = getSoundManager()
        if not sm then return end
        local fn = sm.playUISound
        if fn then fn(sm, "UICloseWindow") end
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

    -- OpÃ§Ã£o toggle do HUD: visÃ­vel quando Dayvinho estÃ¡ no inventÃ¡rio ou hÃ¡ efeito ativo
    local hasDay = playerHasDayvinho(player)
    local hasEff = DayvinhoBlessings_Main and DayvinhoBlessings_Main.hasActiveEffects()
    if (hasDay or hasEff) and DayvinhoBlessings_HUD then
        local vis   = DayvinhoBlessings_HUD.isVisible()
        local label = vis and "Ocultar HUD Dayvinho" or "Mostrar HUD Dayvinho"
        context:addOption(label, nil, function() DayvinhoBlessings_HUD.toggle() end)
    end

    -- OpÃ§Ã£o Descartar: apenas se o item estiver no inventÃ¡rio
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