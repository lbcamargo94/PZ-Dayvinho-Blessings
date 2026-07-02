-- ============================================================
--  Distributions.lua — Spawn do Dayvinho de Bolso no mundo
--  Muito Raro: ~0.1% por container elegível (quartos, lojas)
-- ============================================================

local ITEM_TYPE    = "Base.DayvinhoDeBollo"
local SPAWN_CHANCE = 0.001  -- 0.1%

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
    if not matchesAny(location, VALID_ROOMS)     then return end
    if not matchesAny(container, VALID_CONTAINERS) then return end
    if math.random() >= SPAWN_CHANCE               then return end

    pcall(function()
        containerobj:AddItem(ITEM_TYPE)
    end)
end)