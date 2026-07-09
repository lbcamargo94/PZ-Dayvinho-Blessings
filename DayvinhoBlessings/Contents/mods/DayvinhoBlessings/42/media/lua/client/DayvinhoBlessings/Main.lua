-- ============================================================
--  Main.lua aEUR" Motor central do sistema de bAanA?A?os/maldiA?A?es
--
--  Fluxo:
--    OnGameStart  a?' inicializa estado, constrA3i cache de perks
--    OnLoad       a?' restaura efeitos salvos no ModData (ao carregar save)
--    OnTick       a?' processa efeitos ativos; dispara timer a cada TIMER_INTERVAL segundos
--    LevelPerk    a?' aplica bA nus de XP quando xp_boost estA? ativo
--
--  APIs do PZ (Kahlua) aEUR" NA?O disponA?veis:
--    math.random()  a?' ZombRandFloat(0, 1)
--    math.random(n) a?' ZombRand(n) + 1
--    os.time()      a?' math.floor(getTimeInMillis() / 1000)
-- ============================================================

require "DayvinhoBlessings/Logger"
require "DayvinhoBlessings/Messages"
require "DayvinhoBlessings/Blessings"
require "DayvinhoBlessings/Curses"
local Log = DayvinhoBlessings_Logger

DayvinhoBlessings_Main = {}

-- a"EURa"EUR Constantes a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local ITEM_TYPE      = "Base.DayvinhoDeBolso"
local TIMER_INTERVAL = 1200   -- segundos reais entre cada rolagem (20 min; producao)
local TICK_INTERVAL  = 2      -- segundos entre chamadas onTick dos efeitos

-- a"EURa"EUR Estado global a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local _activeEffects   = {}
local _perkCache       = {}   -- typeString a?' Perks enum (para addXP)
local _lastTriggerTime = 0
local _lastTickTime    = 0
local _initialized     = false
local _hadDayvinho     = false
local _expiryNotif     = nil  -- { isCurse, showUntil } aEUR" exibido no HUD por ~6s
local _justDiscarded   = false  -- sinaliza que Curses.lua jA? tratou a remoA?A?o

-- a"EURa"EUR Helpers a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function now()
    return math.floor(getTimeInMillis() / 1000)
end

-- a"EURa"EUR Sons do mod a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR
-- B42: ISoundManager.addSound() foi removido. Arquivos .ogg em
-- media/sound/ sA?o descobertos automaticamente pelo mod loader.
-- Usamos o nome do arquivo (sem extensA?o) direto em PlayWorldSound.
-- REGRA: sempre verificar se o mA?todo existe antes de chamar aEUR"
-- chamar nil escapa do pcall no Kahlua (RuntimeException Java).

local MOD_SOUNDS = {
    pickup   = "UIActivateButton",    -- Dayvinho entrou no inventA?rio (PZ nativo)
    blessing = "bencao-concedida",    -- media/sound/bencao-concedida.ogg
    curse    = "maldicao-ativada",    -- media/sound/maldicao-ativada.ogg
    remove   = "UICloseWindow",       -- item saiu do inventA?rio (PZ nativo)
}

local function playModSound(player, key)
    local name = MOD_SOUNDS[key]
    if not name then return end
    pcall(function()
        local sm = getSoundManager()
        if not sm then return end
        local sq = player and player:getSquare()
        if sq then
            local fn = sm.PlayWorldSound
            if fn then fn(sm, name, sq, 0, 0, 0, 1, false) end
        else
            -- playUISound: inicial minuscula (nome Java exato do metodo)
            local fn = sm.playUISound
            if fn then fn(sm, name) end
        end
    end)
end

-- a"EURa"EUR Fala do Dayvinho a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR
-- Exibe a mensagem na bolha de fala acima do personagem.

local function dayvinhaSay(player, msg)
    if not msg or msg == "" then return end
    -- Kahlua: chamar nil escapa do pcall como RuntimeException; verificar existencia antes.
    local fn = player.Say
    if fn then pcall(fn, player, msg) end
    -- HUD: bolha acima dura ~3-5s (controlado pelo PZ); exibe 15s no HUD para leitura.
    if DayvinhoBlessings_HUD then
        pcall(DayvinhoBlessings_HUD.showSpeech, msg, 15)
    end
end

-- a"EURa"EUR ModData a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local MD_KEY = "DayvinhoBlessings"

local function getMD(player)
    local md = player:getModData()
    if not md[MD_KEY] then md[MD_KEY] = {} end
    return md[MD_KEY]
end

-- a"EURa"EUR PersistAancia de efeitos a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR
-- Salva a lista de efeitos ativos no ModData do jogador.
-- O PZ serializa o ModData automaticamente ao salvar o jogo.

local function saveEffects(player)
    pcall(function()
        local md = getMD(player)
        local saved = {}
        for _, eff in ipairs(_activeEffects) do
            if eff.endTime then
                saved[#saved + 1] = {
                    id      = eff.id,
                    kind    = eff.kind,
                    endTime = eff.endTime,
                    persist = eff.persist,
                    data    = eff.data,
                }
            end
        end
        md.effects = saved
    end)
end

-- Restaura efeitos do ModData ao carregar um save.
-- Efeitos jA? expirados sA?o descartados.
-- As funA?A?es onTick/onRemove sA?o reconectadas via getDef().

local function restoreEffects(player)
    pcall(function()
        local md = getMD(player)
        local saved = md.effects
        if not saved or #saved == 0 then return end
        local t       = now()
        local restored = 0
        for _, entry in ipairs(saved) do
            local remaining = entry.endTime and (entry.endTime - t) or nil
            if remaining and remaining > 0 then
                local def
                if entry.kind == "blessing" then
                    def = DayvinhoBlessings_Blessings.getDef(entry.id)
                elseif entry.kind == "curse" then
                    def = DayvinhoBlessings_Curses.getDef(entry.id)
                end
                if def then
                    -- addEffect usa remaining como duraA?A?o a?' endTime a?? original
                    local endTime = now() + remaining
                    local eff = {
                        id       = entry.id,
                        kind     = entry.kind,
                        endTime  = endTime,
                        onTick   = def.onTick,
                        onRemove = def.onRemove,
                        data     = entry.data or {},
                        persist  = entry.persist == true,
                    }
                    _activeEffects[#_activeEffects + 1] = eff
                    restored = restored + 1
                end
            end
        end
        Log.info(string.format("efeitos restaurados: %d/%d", restored, #saved))
    end)
end

-- a"EURa"EUR Cache de perks a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function buildPerkCache()
    local cache = {}
    local ok0, maxIdx = pcall(function() return Perks.getMaxIndex() end)
    if not ok0 or not maxIdx then return cache end
    for i = 0, maxIdx - 1 do
        local ok1, pe = pcall(function() return Perks.fromIndex(i) end)
        if not ok1 or pe == nil then break end
        local ok2, perk = pcall(function() return PerkFactory.getPerk(pe) end)
        if ok2 and perk then
            local ok3, parent = pcall(function() return perk:getParent() end)
            if ok3 and parent ~= Perks.None then
                local ok4, typeStr = pcall(function() return tostring(pe) end)
                if ok4 and typeStr and typeStr ~= "" and typeStr ~= "nil" then
                    cache[typeStr] = pe
                end
            end
        end
    end
    return cache
end

-- a"EURa"EUR Habilidade aleatA3ria do cache a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function pickRandomPerkType()
    local keys = {}
    for k in pairs(_perkCache) do keys[#keys + 1] = k end
    if #keys == 0 then return nil end
    return keys[ZombRand(#keys) + 1]
end

-- a"EURa"EUR VerificaA?A?o de posse do item a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsTypeRecurse(ITEM_TYPE)
    end)
    return ok and has
end

-- a"EURa"EUR Motor de efeitos a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

-- persist=true: efeito continua mesmo sem o Dayvinho no inventA?rio (ex: maldiA?A?es)
local function addEffect(id, kind, durationSecs, def, player, data, persist)
    local endTime = (durationSecs and durationSecs > 0)
        and (now() + durationSecs) or nil
    _activeEffects[#_activeEffects + 1] = {
        id       = id,
        kind     = kind,
        endTime  = endTime,
        onTick   = def and def.onTick,
        onRemove = def and def.onRemove,
        data     = data,
        persist  = persist == true,
    }
end

local function removeEffect(idx, player)
    local eff = _activeEffects[idx]
    if eff and eff.onRemove then
        pcall(eff.onRemove, player, eff.data)
    end
    table.remove(_activeEffects, idx)
end

local function clearAllEffects(player)
    for i = #_activeEffects, 1, -1 do
        removeEffect(i, player)
    end
end

local function tickEffects(player, t)
    local changed = false
    local i = #_activeEffects
    while i >= 1 do
        local eff = _activeEffects[i]
        if eff.endTime and t >= eff.endTime then
            local msg
            if eff.kind == "blessing" then
                msg = DayvinhoBlessings_Messages.getEnd()
            elseif eff.kind == "curse" then
                msg = DayvinhoBlessings_Messages.getCurseEnd()
            end
            if msg then
                dayvinhaSay(player, msg)
                _expiryNotif = { isCurse = eff.kind == "curse", showUntil = t + 6 }
            end
            removeEffect(i, player)
            changed = true
        elseif eff.onTick then
            pcall(eff.onTick, player, eff.data)
        end
        i = i - 1
    end
    return changed
end

-- a"EURa"EUR Aplicar bAanA?A?o a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function applyBlessing(player, blessingId, isLegendary)
    local def = DayvinhoBlessings_Blessings.getDef(blessingId)
    if not def then
        Log.error("blessing desconhecida: " .. tostring(blessingId))
        return
    end

    local data = {}
    pcall(def.apply, player, isLegendary, data)
    playModSound(player, "blessing")

    local xpPerkName = nil
    if blessingId == "xp_boost" then
        data.perkType = pickRandomPerkType()
        Log.debug("xp_boost: habilidade sorteada = " .. tostring(data.perkType))
        pcall(function()
            local pe = _perkCache[data.perkType]
            if pe then
                local perk = PerkFactory.getPerk(pe)
                if perk then xpPerkName = perk:getName() end
            end
        end)
    end

    local dur = def.duration or 0
    if isLegendary and dur > 0 then dur = math.floor(dur * 1.5) end

    Log.info(string.format("bencao aplicada: %s | lendaria=%s | duracao=%ds",
        blessingId, tostring(isLegendary), dur))

    if dur > 0 then
        addEffect(blessingId, "blessing", dur, def, player, data)
    end

    local msg = DayvinhoBlessings_Messages.getForBlessing(blessingId)
    if xpPerkName then
        msg = msg .. " (" .. xpPerkName .. ")"
    end
    dayvinhaSay(player, msg)
    saveEffects(player)
end

-- a"EURa"EUR API pAoblica: marca que Curses.lua jA? tratou a remoA?A?o a"EURa"EURa"EURa"EURa"EUR

function DayvinhoBlessings_Main.markDiscarded()
    _justDiscarded = true
end

-- a"EURa"EUR API pAoblica: verificar se hA? efeitos ativos a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

function DayvinhoBlessings_Main.hasActiveEffects()
    return #_activeEffects > 0 or (_expiryNotif ~= nil)
end

-- a"EURa"EUR API pAoblica: disparar maldiA?A?o (chamada pelo Curses.lua) a"EURa"EUR

function DayvinhoBlessings_Main.triggerCurse(player, triggerType)
    local effectId = DayvinhoBlessings_Curses.pickRandomEffect()
    local def      = DayvinhoBlessings_Curses.getDef(effectId)
    if not def then
        Log.error("efeito de maldicao desconhecido: " .. tostring(effectId))
        return
    end

    local data = {}
    pcall(def.apply, player, data)

    addEffect(effectId, "curse", DayvinhoBlessings_Curses.getDuration(), def, player, data, true)
    playModSound(player, "curse")
    saveEffects(player)

    Log.info(string.format("maldicao ativada: %s | gatilho=%s", effectId, tostring(triggerType)))

    dayvinhaSay(player, DayvinhoBlessings_Messages.getCurseMsg(triggerType))
end

-- a"EURa"EUR LA3gica do timer a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR
-- A cada TIMER_INTERVAL segundos: 70% bAanA?A?o comum, 5% lendA?ria, 20% maldiA?A?o, 5% nada.

local function tryTrigger(player)
    local roll       = ZombRandFloat(0, 1)
    local blessingId = DayvinhoBlessings_Blessings.pickRandom()

    if roll < 0.20 then
        -- 20%: maldiA?A?o aleatA3ria
        DayvinhoBlessings_Main.triggerCurse(player, "random")
    elseif roll < 0.25 then
        -- 5%: bAanA?A?o lendA?ria
        applyBlessing(player, blessingId, true)
    elseif roll < 0.95 then
        -- 70%: bAanA?A?o comum
        applyBlessing(player, blessingId, false)
    end
    -- 5%: nada acontece
end

-- a"EURa"EUR Eventos a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

local function onGameStart()
    _activeEffects   = {}
    _lastTriggerTime = now()
    _lastTickTime    = now()
    _initialized     = false
    _hadDayvinho     = false
    _expiryNotif     = nil

    local ok, result = pcall(buildPerkCache)
    if ok and result then
        _perkCache = result
        local count = 0
        for _ in pairs(_perkCache) do count = count + 1 end
        Log.info(string.format("inicializado - cache de perks: %d habilidades", count))
    else
        Log.warn("falha ao construir cache de perks no OnGameStart")
    end

    _initialized = true
end

-- OnLoad dispara ao carregar um save existente (apA3s OnGameStart).
-- Restaura efeitos do ModData e inicializa _hadDayvinho para
-- evitar a mensagem de boas-vindas espAoria e maldiA?A?o falsa.
local function onLoad()
    local player = getSpecificPlayer(0)
    if not player then return end
    restoreEffects(player)
    _hadDayvinho     = playerHasDayvinho(player)
    _lastTriggerTime = now()
    _lastTickTime    = now()
    Log.info("estado restaurado no OnLoad")
end

local function onTick()
    if not _initialized then return end

    local player = getPlayer()
    if not player then return end

    -- ReconstrA3i cache de perks se vazio (next() nA?o existe no Kahlua)
    local cacheIsEmpty = true
    for _ in pairs(_perkCache) do cacheIsEmpty = false; break end
    if cacheIsEmpty then
        Log.warn("cache de perks vazio - reconstruindo")
        local ok, result = pcall(buildPerkCache)
        if ok and result then
            _perkCache = result
            local count = 0
            for _ in pairs(_perkCache) do count = count + 1 end
            Log.info(string.format("cache reconstruido: %d habilidades", count))
        else
            Log.error("falha ao reconstruir cache de perks")
        end
    end

    local hasDayvinho = playerHasDayvinho(player)

    -- Detecta Dayvinho saindo do inventA?rio a?' maldiA?A?o automA?tica
    -- NA?o re-cursifica quando "Descartar" jA? tratou (_justDiscarded = true).
    if _hadDayvinho and not hasDayvinho then
        if _justDiscarded then
            _justDiscarded = false
        else
            playModSound(player, "remove")
            DayvinhoBlessings_Main.triggerCurse(player, "removed")
        end
    end

    -- Mensagem de boas-vindas + som na primeira vez que o item entra no inventA?rio
    if hasDayvinho and not _hadDayvinho then
        playModSound(player, "pickup")
        dayvinhaSay(player, DayvinhoBlessings_Messages.getGreeting())
        _lastTriggerTime = now() - TIMER_INTERVAL + 20
    end
    _hadDayvinho = hasDayvinho

    -- Sem o item: remove apenas efeitos nA?o-persistentes (bAanA?A?os).
    -- MaldiA?A?es (persist=true) continuam atA? expirar naturalmente.
    if not hasDayvinho then
        local removed = false
        for i = #_activeEffects, 1, -1 do
            if not _activeEffects[i].persist then
                removeEffect(i, player)
                removed = true
            end
        end
        if removed then saveEffects(player) end
    end

    local t = now()

    -- Processa todos os efeitos ativos (inclusive maldiA?A?es sem o item)
    if #_activeEffects > 0 and t - _lastTickTime >= TICK_INTERVAL then
        _lastTickTime = t
        local changed = tickEffects(player, t)
        if changed then saveEffects(player) end
    end

    -- Limpa notificaA?A?o de expiraA?A?o expirada
    if _expiryNotif and t >= _expiryNotif.showUntil then
        _expiryNotif = nil
    end

    -- Dispara novo timer apenas quando o Dayvinho estA? presente
    if hasDayvinho and t - _lastTriggerTime >= TIMER_INTERVAL then
        _lastTriggerTime = t
        tryTrigger(player)
    end
end

local function onLevelPerk(player, perk)
    if not _initialized then return end
    if not player or not perk then return end
    if not playerHasDayvinho(player) then return end

    local ok, typeStr = pcall(function() return tostring(perk) end)
    if not ok or not typeStr then return end

    local mult = 0
    for _, eff in ipairs(_activeEffects) do
        if eff.id == "xp_boost" and eff.kind == "blessing" and eff.data then
            if eff.data.perkType == typeStr then
                mult = eff.data.mult or 0
                break
            end
        end
    end
    if mult <= 0 then return end

    local perkEnum = _perkCache[typeStr]
    if not perkEnum then return end

    local level  = player:getPerkLevel(perkEnum) or 1
    local xpGain = math.max(1, math.floor(level * 75 * mult))
    local xpOk = Log.try(function() player:getXp():AddXP(perkEnum, xpGain) end, "onLevelPerk.AddXP")
    if xpOk then
        Log.debug(string.format("xp_boost: +%d xp em %s (nivel %d, mult %.0f%%)",
            xpGain, typeStr, level, mult * 100))
    end
end

-- a"EURa"EUR API pAoblica: lista completa de efeitos para o HUD a"EURa"EURa"EURa"EURa"EURa"EURa"EURa"EUR

function DayvinhoBlessings_Main.getHUDInfoAll()
    local t = now()
    local results = {}

    -- Todos os efeitos ativos com timer
    for i = 1, #_activeEffects do
        local eff = _activeEffects[i]
        if eff.endTime then
            local remaining = eff.endTime - t
            if remaining > 0 then
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60
                results[#results + 1] = {
                    id        = eff.id,
                    isCurse   = eff.kind == "curse",
                    timerText = string.format("%d:%02d", mins, secs),
                    remaining = remaining,
                    isExpired = false,
                }
            end
        end
    end

    -- NotificaA?A?o de expiraA?A?o recente (apA3s o efeito acabar)
    if _expiryNotif and t < _expiryNotif.showUntil then
        results[#results + 1] = {
            id        = "_expired",
            isCurse   = _expiryNotif.isCurse,
            timerText = "Encerrado",
            remaining = 0,
            isExpired = true,
        }
    end

    return #results > 0 and results or nil
end

Events.OnGameStart.Add(onGameStart)
Events.OnLoad.Add(onLoad)
Events.OnTick.Add(onTick)
Events.LevelPerk.Add(onLevelPerk)