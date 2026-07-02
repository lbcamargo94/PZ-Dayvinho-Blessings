-- ============================================================
--  Main.lua — Sistema de Bênçãos do Dayvinho (B42.19+)
--
--  Mecânica:
--    1. O jogador precisa do item "Base.DayvinhoDeBollo" no inventário.
--    2. A cada level-up de qualquer habilidade: rola 0,5% de chance de
--       ativar uma Bênção (ou 0,05% para Lendária).
--    3. Cooldown de 12 horas in-game entre ativações.
--    4. Bênção dura 10 minutos reais: skills suportadas ganham XP bônus
--       a cada level-up enquanto ativa.
--    5. Cooldown persiste via ModData (sobrevive a reloads).
-- ============================================================

require "DayvinhoBlessings/Messages"

-- ── Constantes ───────────────────────────────────────────────

local ITEM_TYPE         = "Base.DayvinhoDeBollo"
local MOD_KEY           = "DayvinhoBlessings"
local BLESSING_CHANCE   = 0.005    -- 0,5% por level-up
local LEGENDARY_CHANCE  = 0.0005   -- 0,05% (1 em 2000) — Lendária
local COOLDOWN_HOURS    = 12       -- horas in-game de cooldown
local BLESSING_DURATION = 600      -- 10 minutos em segundos (tempo real)

-- XP bônus fixo concedido quando um skill suportado sobe de nível
-- durante a bênção ativa. Escala pelo multiplicador lendário.
local SKILL_XP_BONUS = {
    Fishing      = 150,
    Woodwork     = 100,
    Farming      = 100,
    Mechanics    = 125,
    MetalWelding = 100,
    Maintenance  = 100,
    Cooking      = 125,
    Tailoring    = 125,
}
local LEGENDARY_MULT = 1.5  -- bênção lendária dá 1,5× o bônus

-- ── Estado em memória ─────────────────────────────────────────

local _blessingEnd    = 0      -- os.time() quando a bênção expira
local _isLegendary    = false
local _isStartingUp   = false
local _perkCache      = {}     -- { [typeString] = perkEnum }
local _warnedExpiry   = false

-- ── Helpers ───────────────────────────────────────────────────

local function getModData(player)
    local ok, md = pcall(function() return player:getModData() end)
    if not ok or not md then return {} end
    if not md[MOD_KEY] then md[MOD_KEY] = {} end
    return md[MOD_KEY]
end

local function getWorldHours()
    local ok, gt = pcall(GameTime.getInstance)
    if not ok or not gt then return 0 end
    local hok, h = pcall(function() return gt:getWorldAgeHours() end)
    return (hok and h) or 0
end

local function hasItem(player)
    local ok, inv = pcall(function() return player:getInventory() end)
    if not ok or not inv then return false end
    local cok, has = pcall(function() return inv:contains(ITEM_TYPE) end)
    return cok and has == true
end

local function isBlessingActive()
    return os.time() < _blessingEnd
end

-- Exibe mensagem: tenta Say() com fallback silencioso
local function notify(player, text)
    pcall(function() player:Say(text) end)
end

-- Constrói cache de perkEnum por tipo string uma vez por sessão
local function buildPerkCache()
    _perkCache = {}
    pcall(function()
        local maxIdx = Perks.getMaxIndex()
        for i = 0, maxIdx - 1 do
            local pe  = Perks.fromIndex(i)
            local pd  = PerkFactory.getPerk(pe)
            if pd then
                _perkCache[tostring(pd:getType())] = pe
            end
        end
    end)
end

-- ── Ativação da bênção ────────────────────────────────────────

local function activateBlessing(player, legendary)
    _blessingEnd  = os.time() + BLESSING_DURATION
    _isLegendary  = legendary == true
    _warnedExpiry = false

    -- Persiste horário in-game do cooldown
    local md = getModData(player)
    md.lastBlessingHours = getWorldHours()

    local msg = legendary
        and DayvinhoBlessings_Messages.getLegendary()
        or  DayvinhoBlessings_Messages.getForSkill("Generic")
    notify(player, msg)
end

-- ── Verificação de trigger ────────────────────────────────────

local function checkTrigger(player)
    if not hasItem(player)    then return false end
    if isBlessingActive()     then return false end

    -- Cooldown in-game
    local md           = getModData(player)
    local lastH        = md.lastBlessingHours or 0
    local currentH     = getWorldHours()
    if (currentH - lastH) < COOLDOWN_HOURS then return false end

    -- Rolagem
    local roll = math.random()
    if roll < LEGENDARY_CHANCE then
        activateBlessing(player, true)
        return true
    elseif roll < BLESSING_CHANCE then
        activateBlessing(player, false)
        return true
    end
    return false
end

-- ── Aplicação do bônus de XP ──────────────────────────────────

local function applyXPBonus(player, perkTypeStr)
    if not isBlessingActive() then return end

    local base = SKILL_XP_BONUS[perkTypeStr]
    if not base then return end

    local bonus    = _isLegendary and math.floor(base * LEGENDARY_MULT) or base
    local perkEnum = _perkCache[perkTypeStr]
    if not perkEnum then return end

    pcall(function() player:addXP(perkEnum, bonus) end)

    local msg = _isLegendary
        and DayvinhoBlessings_Messages.getLegendary()
        or  DayvinhoBlessings_Messages.getForSkill(perkTypeStr)
    notify(player, msg)
end

-- ── Evento: level-up de habilidade ───────────────────────────

Events.LevelPerk.Add(function(player, perk, level, isNew)
    if _isStartingUp then return end
    if not player    then return end

    local isLocal = false
    pcall(function() isLocal = player:isLocalPlayer() == true end)
    if not isLocal then return end

    local perkTypeStr = ""
    pcall(function()
        local pd = PerkFactory.getPerk(perk)
        if pd then perkTypeStr = tostring(pd:getType()) end
    end)

    -- 1. Tenta ativar bênção
    checkTrigger(player)

    -- 2. Aplica bônus XP ao skill que subiu de nível (se bênção ativa)
    applyXPBonus(player, perkTypeStr)
end)

-- ── Evento: início de sessão ──────────────────────────────────

Events.OnGameStart.Add(function()
    _blessingEnd  = 0
    _isLegendary  = false
    _warnedExpiry = false
    _isStartingUp = true

    buildPerkCache()

    -- Grace period: ignora eventos dos primeiros ~2 segundos de carregamento
    local ticks = 0
    local clearStartup
    clearStartup = function()
        ticks = ticks + 1
        if ticks >= 120 then
            _isStartingUp = false
            pcall(function() Events.OnTick.Remove(clearStartup) end)
        end
    end
    pcall(function() Events.OnTick.Add(clearStartup) end)
end)

-- ── Ticker: notificação de expiração ─────────────────────────

local _tickCount = 0
Events.OnTick.Add(function()
    _tickCount = _tickCount + 1
    if _tickCount < 600 then return end  -- verifica a cada ~10s
    _tickCount = 0

    if _blessingEnd == 0 or _warnedExpiry then return end
    if isBlessingActive()                  then return end

    _warnedExpiry = true
    local ok, player = pcall(getPlayer)
    if ok and player then
        notify(player, DayvinhoBlessings_Messages.getEnd())
    end
end)