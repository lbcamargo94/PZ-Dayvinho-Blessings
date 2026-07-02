-- ============================================================
--  Main.lua — Motor central do sistema de bênçãos/maldições
--
--  Fluxo:
--    OnGameStart  → inicializa estado, constrói cache de perks
--    OnTick       → processa efeitos ativos; dispara timer a cada 1 dia in-game
--    LevelPerk    → aplica bônus de XP quando xp_boost está ativo
-- ============================================================

require "DayvinhoBlessings/Logger"
require "DayvinhoBlessings/Messages"
require "DayvinhoBlessings/Blessings"
require "DayvinhoBlessings/Curses"
local Log = DayvinhoBlessings_Logger

DayvinhoBlessings_Main = {}

-- ── Constantes ────────────────────────────────────────────────

local ITEM_TYPE      = "Base.DayvinhoDeBolso"
local TIMER_INTERVAL = 1440   -- segundos reais (24 min real ≈ 1 dia in-game a 60x)
local COOLDOWN_HOURS = 24     -- horas in-game entre bênçãos
local TICK_INTERVAL  = 2      -- segundos entre chamadas onTick dos efeitos

-- ── Estado global ─────────────────────────────────────────────

local _activeEffects   = {}
local _perkCache       = {}   -- typeString → Perks enum (para addXP)
local _lastTriggerTime = 0
local _lastTickTime    = 0
local _initialized     = false

-- ── ModData ───────────────────────────────────────────────────

local MD_KEY = "DayvinhoBlessings"

local function getMD(player)
    local md = player:getModData()
    if not md[MD_KEY] then md[MD_KEY] = {} end
    return md[MD_KEY]
end

-- ── Cache de perks ────────────────────────────────────────────

local function buildPerkCache()
    local cache = {}
    -- Perks.getMaxIndex() dá o limite seguro; fromIndex é 0-based
    local ok0, maxIdx = pcall(function() return Perks.getMaxIndex() end)
    if not ok0 or not maxIdx then return cache end
    for i = 0, maxIdx - 1 do
        local ok1, pe = pcall(function() return Perks.fromIndex(i) end)
        if not ok1 or pe == nil then break end
        local ok2, perk = pcall(function() return PerkFactory.getPerk(pe) end)
        if ok2 and perk then
            -- Filtra perks-raiz (categorias como Agility, Crafting, etc.) que
            -- nunca recebem XP diretamente — parent == Perks.None os identifica
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

-- ── Habilidade aleatória do cache ────────────────────────────

local function pickRandomPerkType()
    local keys = {}
    for k in pairs(_perkCache) do keys[#keys + 1] = k end
    if #keys == 0 then return nil end
    return keys[math.random(#keys)]
end

-- ── Verificação de posse do item ──────────────────────────────

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsTypeRecurse(ITEM_TYPE)
    end)
    return ok and has
end

-- ── Motor de efeitos ──────────────────────────────────────────

local function addEffect(id, kind, durationSecs, def, player, data)
    local endTime = (durationSecs and durationSecs > 0)
        and (os.time() + durationSecs) or nil
    _activeEffects[#_activeEffects + 1] = {
        id       = id,
        kind     = kind,
        endTime  = endTime,
        onTick   = def and def.onTick,
        onRemove = def and def.onRemove,
        data     = data,
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

local function tickEffects(player, now)
    local i = #_activeEffects
    while i >= 1 do
        local eff = _activeEffects[i]
        if eff.endTime and now >= eff.endTime then
            if eff.kind == "blessing" then
                pcall(player.Say, player, DayvinhoBlessings_Messages.getEnd())
            elseif eff.kind == "curse" then
                pcall(player.Say, player, DayvinhoBlessings_Messages.getCurseEnd())
            end
            removeEffect(i, player)
        elseif eff.onTick then
            pcall(eff.onTick, player, eff.data)
        end
        i = i - 1
    end
end

-- ── Aplicar bênção ────────────────────────────────────────────

local function applyBlessing(player, blessingId, isLegendary)
    local def = DayvinhoBlessings_Blessings.getDef(blessingId)
    if not def then
        Log.error("blessing desconhecida: " .. tostring(blessingId))
        return
    end

    local data = {}
    pcall(def.apply, player, isLegendary, data)

    -- XP Boost: sorteia UMA habilidade aleatória para receber o bônus
    if blessingId == "xp_boost" then
        data.perkType = pickRandomPerkType()
        Log.debug("xp_boost: habilidade sorteada = " .. tostring(data.perkType))
    end

    local dur = def.duration or 0
    if isLegendary and dur > 0 then dur = math.floor(dur * 1.5) end

    Log.info(string.format("bencao aplicada: %s | lendaria=%s | duracao=%ds",
        blessingId, tostring(isLegendary), dur))

    if dur > 0 then
        addEffect(blessingId, "blessing", dur, def, player, data)
    end

    pcall(player.Say, player, DayvinhoBlessings_Messages.getForBlessing(blessingId))
end

-- ── API pública: disparar maldição (chamada pelo Curses.lua) ──

function DayvinhoBlessings_Main.triggerCurse(player, triggerType)
    local effectId = DayvinhoBlessings_Curses.pickRandomEffect()
    local def      = DayvinhoBlessings_Curses.getDef(effectId)
    if not def then
        Log.error("efeito de maldicao desconhecido: " .. tostring(effectId))
        return
    end

    local data = {}
    pcall(def.apply, player, data)

    addEffect(effectId, "curse", DayvinhoBlessings_Curses.getDuration(), def, player, data)

    Log.info(string.format("maldicao ativada: %s | gatilho=%s", effectId, tostring(triggerType)))

    pcall(player.Say, player, DayvinhoBlessings_Messages.getCurseMsg(triggerType))
end

-- ── Lógica do timer (cada 1 dia in-game ≈ 24 min reais a 60x) ─

local function tryTrigger(player)
    local md         = getMD(player)
    local worldHours = GameTime.getInstance():getWorldAgeHours()

    local nextAllowed = md.nextBlessingWorldHours or 0
    if worldHours < nextAllowed then return end

    -- 50% de chance de falhar
    if math.random() < 0.50 then
        pcall(player.Say, player, DayvinhoBlessings_Messages.getFail())
        return
    end

    -- 5% lendária, 95% normal
    local isLegendary = math.random() < 0.05
    local blessingId  = DayvinhoBlessings_Blessings.pickRandom()

    -- Aplica cooldown de 24h in-game
    md.nextBlessingWorldHours = worldHours + COOLDOWN_HOURS

    applyBlessing(player, blessingId, isLegendary)
end

-- ── Eventos ───────────────────────────────────────────────────

local function onGameStart()
    _activeEffects   = {}
    _lastTriggerTime = os.time()
    _lastTickTime    = os.time()
    _initialized     = false

    local ok, result = pcall(buildPerkCache)
    if ok and result then
        _perkCache = result
        local count = 0
        for _ in pairs(_perkCache) do count = count + 1 end
        Log.info(string.format("inicializado — cache de perks: %d habilidades", count))
    else
        Log.warn("falha ao construir cache de perks no OnGameStart")
    end

    _initialized = true
end

local function onTick()
    if not _initialized then return end

    local player = getPlayer()
    if not player then return end

    -- Reconstrói cache de perks se vazio (falhou no onGameStart)
    -- next() não está disponível no Kahlua do PZ; usa pairs para checar vazio
    local _cacheIsEmpty = true
    for _ in pairs(_perkCache) do _cacheIsEmpty = false; break end
    if _cacheIsEmpty then
        Log.warn("cache de perks vazio — reconstruindo")
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

    if not playerHasDayvinho(player) then
        if #_activeEffects > 0 then clearAllEffects(player) end
        return
    end

    local now = os.time()

    if now - _lastTickTime >= TICK_INTERVAL then
        _lastTickTime = now
        tickEffects(player, now)
    end

    if now - _lastTriggerTime >= TIMER_INTERVAL then
        _lastTriggerTime = now
        tryTrigger(player)
    end
end

local function onLevelPerk(player, perk)
    if not _initialized then return end
    if not player or not perk then return end
    if not playerHasDayvinho(player) then return end

    -- LevelPerk passa o enum Perks.X diretamente (não um Perk object),
    -- então tostring(perk) dá a string usada como chave no cache
    local ok, typeStr = pcall(function() return tostring(perk) end)
    if not ok or not typeStr then return end

    -- Verifica se xp_boost está ativo E se esta é a habilidade sorteada
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
    -- B42: player:addXP() não existe; a API correta é player:getXp():AddXP()
    local xpOk = Log.try(function() player:getXp():AddXP(perkEnum, xpGain) end, "onLevelPerk.AddXP")
    if xpOk then
        Log.debug(string.format("xp_boost: +%d xp em %s (nivel %d, mult %.0f%%)",
            xpGain, typeStr, level, mult * 100))
    end
end

Events.OnGameStart.Add(onGameStart)
Events.OnTick.Add(onTick)
Events.LevelPerk.Add(onLevelPerk)