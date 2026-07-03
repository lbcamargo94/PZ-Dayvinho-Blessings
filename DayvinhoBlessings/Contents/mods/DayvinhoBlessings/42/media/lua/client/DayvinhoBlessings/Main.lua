-- ============================================================
--  Main.lua — Motor central do sistema de bênçãos/maldições
--
--  Fluxo:
--    OnGameStart  → inicializa estado, constrói cache de perks
--    OnTick       → processa efeitos ativos; dispara timer a cada 1 dia in-game
--    LevelPerk    → aplica bônus de XP quando xp_boost está ativo
--
--  APIs do PZ (Kahlua) — NÃO disponíveis:
--    math.random()  → ZombRandFloat(0, 1)
--    math.random(n) → ZombRand(n) + 1
--    os.time()      → math.floor(getTimeInMillis() / 1000)
-- ============================================================

require "DayvinhoBlessings/Logger"
require "DayvinhoBlessings/Messages"
require "DayvinhoBlessings/Blessings"
require "DayvinhoBlessings/Curses"
local Log = DayvinhoBlessings_Logger

DayvinhoBlessings_Main = {}

-- ── Constantes ────────────────────────────────────────────────

local ITEM_TYPE      = "Base.DayvinhoDeBolso"
local TIMER_INTERVAL = 60     -- segundos reais (1 hora in-game a 60x) — teste
local COOLDOWN_HOURS = 1      -- horas in-game entre bênçãos — teste
local TICK_INTERVAL  = 2      -- segundos entre chamadas onTick dos efeitos

-- ── Estado global ─────────────────────────────────────────────

local _activeEffects   = {}
local _perkCache       = {}   -- typeString → Perks enum (para addXP)
local _lastTriggerTime = 0
local _lastTickTime    = 0
local _initialized     = false
local _hadDayvinho     = false
local _expiryNotif     = nil  -- { isCurse, showUntil } — exibido no HUD por ~6s
local _justDiscarded   = false  -- sinaliza que Curses.lua já tratou a remoção

-- ── Helpers ───────────────────────────────────────────────────

local function now()
    return math.floor(getTimeInMillis() / 1000)
end

-- ── Sons do mod ───────────────────────────────────────────────
-- B42: ISoundManager.addSound() foi removido. Arquivos .ogg em
-- media/sound/ são descobertos automaticamente pelo mod loader.
-- Usamos o nome do arquivo (sem extensão) direto em PlayWorldSound.
-- REGRA: sempre verificar se o método existe antes de chamar —
-- chamar nil escapa do pcall no Kahlua (RuntimeException Java).

local MOD_SOUNDS = {
    pickup   = "UIActivateButton",    -- Dayvinho entrou no inventário (PZ nativo)
    blessing = "bencao-concedida",    -- media/sound/bencao-concedida.ogg
    curse    = "maldicao-ativada",    -- media/sound/maldicao-ativada.ogg
    remove   = "UICloseWindow",       -- item saiu do inventário (PZ nativo)
}

local function playModSound(player, key)
    local name = MOD_SOUNDS[key]
    if not name then return end
    pcall(function()
        local sm = getSoundManager()
        if not sm then return end
        local sq = player and player:getSquare()
        if sq then
            -- Verifica existência do método antes de chamar (evita nil escape)
            local fn = sm.PlayWorldSound
            if fn then fn(sm, name, sq, 0, 0, 0, 1, false) end
        else
            local fn = sm.PlayUISound
            if fn then fn(sm, name) end
        end
    end)
end

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

-- ── Habilidade aleatória do cache ────────────────────────────

local function pickRandomPerkType()
    local keys = {}
    for k in pairs(_perkCache) do keys[#keys + 1] = k end
    if #keys == 0 then return nil end
    return keys[ZombRand(#keys) + 1]
end

-- ── Verificação de posse do item ──────────────────────────────

local function playerHasDayvinho(player)
    local ok, has = pcall(function()
        return player:getInventory():containsTypeRecurse(ITEM_TYPE)
    end)
    return ok and has
end

-- ── Motor de efeitos ──────────────────────────────────────────

-- persist=true: efeito continua mesmo sem o Dayvinho no inventário (ex: maldições)
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
                pcall(player.Say, player, msg)
                _expiryNotif = { isCurse = eff.kind == "curse", showUntil = t + 6 }
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
    playModSound(player, "blessing")

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

-- ── API pública: marca que Curses.lua já tratou a remoção ─────
-- Evita dupla maldição quando "Descartar" já chamou triggerCurse.

function DayvinhoBlessings_Main.markDiscarded()
    _justDiscarded = true
end

-- ── API pública: verificar se há efeitos ativos ───────────────

function DayvinhoBlessings_Main.hasActiveEffects()
    return #_activeEffects > 0 or (_expiryNotif ~= nil)
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

    addEffect(effectId, "curse", DayvinhoBlessings_Curses.getDuration(), def, player, data, true)
    playModSound(player, "curse")

    Log.info(string.format("maldicao ativada: %s | gatilho=%s", effectId, tostring(triggerType)))

    pcall(player.Say, player, DayvinhoBlessings_Messages.getCurseMsg(triggerType))
end

-- ── Lógica do timer (cada 1 dia in-game ≈ 24 min reais a 60x) ─

local function tryTrigger(player)
    local md         = getMD(player)
    local worldHours = getGameTime():getWorldAgeHours()

    local nextAllowed = md.nextBlessingWorldHours or 0
    if worldHours < nextAllowed then return end

    -- 50% de chance de falhar
    if ZombRandFloat(0, 1) < 0.50 then
        pcall(player.Say, player, DayvinhoBlessings_Messages.getFail())
        return
    end

    -- 5% lendária, 95% normal
    local isLegendary = ZombRandFloat(0, 1) < 0.05
    local blessingId  = DayvinhoBlessings_Blessings.pickRandom()

    md.nextBlessingWorldHours = worldHours + COOLDOWN_HOURS

    applyBlessing(player, blessingId, isLegendary)
end

-- ── Eventos ───────────────────────────────────────────────────

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

    -- Reconstrói cache de perks se vazio (next() não existe no Kahlua)
    local cacheIsEmpty = true
    for _ in pairs(_perkCache) do cacheIsEmpty = false; break end
    if cacheIsEmpty then
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

    local hasDayvinho = playerHasDayvinho(player)

    -- Detecta Dayvinho saindo do inventário → maldição automática
    -- Cobre: jogar no chão, colocar em móvel, mochila, zumbi, qualquer container.
    -- Não re-cursifica quando "Descartar" já tratou (_justDiscarded = true).
    if _hadDayvinho and not hasDayvinho then
        if _justDiscarded then
            _justDiscarded = false
        else
            playModSound(player, "remove")
            DayvinhoBlessings_Main.triggerCurse(player, "removed")
        end
    end

    -- Mensagem de boas-vindas + som na primeira vez que o item entra no inventário
    if hasDayvinho and not _hadDayvinho then
        playModSound(player, "pickup")
        pcall(player.Say, player, DayvinhoBlessings_Messages.getGreeting())
    end
    _hadDayvinho = hasDayvinho

    -- Sem o item: remove apenas efeitos não-persistentes (bênçãos).
    -- Maldições (persist=true) continuam até expirar naturalmente.
    if not hasDayvinho then
        for i = #_activeEffects, 1, -1 do
            if not _activeEffects[i].persist then
                removeEffect(i, player)
            end
        end
    end

    local t = now()

    -- Processa todos os efeitos ativos (inclusive maldições sem o item)
    if #_activeEffects > 0 and t - _lastTickTime >= TICK_INTERVAL then
        _lastTickTime = t
        tickEffects(player, t)
    end

    -- Dispara novo timer apenas quando o Dayvinho está presente
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

-- ── API pública: lista completa de efeitos para o HUD ────────

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

    -- Notificação de expiração recente (após o efeito acabar)
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
Events.OnTick.Add(onTick)
Events.LevelPerk.Add(onLevelPerk)