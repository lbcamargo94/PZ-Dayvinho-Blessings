-- ============================================================
--  Distributions.lua — Spawn do Dayvinho de Bolso no mundo
--  Raro: ~1% por container elegível (quartos, lojas)
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

local ITEM_TYPE    = "Base.DayvinhoDeBolso"
local SPAWN_CHANCE = 0.01   -- 1%

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

Events.OnFillContainer.Add(function(location, container, containerobj)
    if not containerobj then return end
    if not matchesAny(location, VALID_ROOMS)      then return end
    if not matchesAny(container, VALID_CONTAINERS) then return end
    if math.random() >= SPAWN_CHANCE               then return end

    local ok = Log.try(function()
        containerobj:AddItem(ITEM_TYPE)
    end, "Distributions.AddItem")

    if ok then
        Log.debug("spawn: " .. ITEM_TYPE .. " em " .. tostring(location) .. "/" .. tostring(container))
    end
end)