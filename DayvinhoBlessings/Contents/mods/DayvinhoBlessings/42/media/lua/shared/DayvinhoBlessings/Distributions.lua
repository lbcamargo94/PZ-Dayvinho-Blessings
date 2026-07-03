-- ============================================================
--  Distributions.lua — Spawn do Dayvinho de Bolso no mundo
--  Raro: ~2% por container elegível (quartos, lojas)
--  Limite global: no máximo MAX_SPAWNS itens por mundo
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

local ITEM_TYPE    = "Base.DayvinhoDeBolso"
local SPAWN_CHANCE = 0.02   -- 2% por container elegível (calibrado para loot 0.04 do Brasileirão)
local MAX_SPAWNS   = 3      -- máximo de Dayvinhos que podem ser gerados em todo o mapa

-- Tipos de cômodo onde o item pode aparecer (substrings, case insensitive)
local VALID_ROOMS = {
    "bedroom", "child", "toystore", "toy", "retail",
    "livingroom", "lounge", "storeroom", "gift",
}

-- Tipos de container onde o item pode aparecer (substrings, case insensitive)
local VALID_CONTAINERS = {
    "dresser", "wardrobe", "shelves", "shelf", "crate",
    "counter", "display", "chest",
}

local function matchesAny(str, list)
    if not str then return false end
    local lower = str:lower()
    for _, v in ipairs(list) do
        if lower:find(v, 1, true) then return true end
    end
    return false
end

-- getGameModData() retorna uma tabela global persistida com o mundo (B42).
-- Disponível nos contextos server e client; é o lugar correto para
-- guardar contadores que valem para o mapa inteiro (não por jogador).

local function getSpawnCount()
    local ok, md = pcall(function() return getGameModData() end)
    if not ok or not md then return 0 end
    md.DayvinhoBlessings = md.DayvinhoBlessings or {}
    return md.DayvinhoBlessings.spawnCount or 0
end

local function incrementSpawnCount()
    local ok, md = pcall(function() return getGameModData() end)
    if not ok or not md then return end
    md.DayvinhoBlessings = md.DayvinhoBlessings or {}
    md.DayvinhoBlessings.spawnCount = (md.DayvinhoBlessings.spawnCount or 0) + 1
end

Events.OnFillContainer.Add(function(location, container, containerobj)
    if not containerobj then return end
    if not matchesAny(location, VALID_ROOMS)       then return end
    if not matchesAny(container, VALID_CONTAINERS)  then return end
    if getSpawnCount() >= MAX_SPAWNS               then return end
    -- OnFillContainer roda no contexto server; math.random nao existe la.
    -- ZombRandFloat(0,1) e a API correta do PZ para float aleatorio.
    if ZombRandFloat(0, 1) >= SPAWN_CHANCE          then return end

    local ok = Log.try(function()
        containerobj:AddItem(ITEM_TYPE)
    end, "Distributions.AddItem")

    if ok then
        incrementSpawnCount()
        local count = getSpawnCount()
        Log.debug(string.format("spawn: %s em %s/%s (total: %d/%d)",
            ITEM_TYPE, tostring(location), tostring(container), count, MAX_SPAWNS))
    end
end)