-- ============================================================
--  Messages.lua — Chaves de tradução por habilidade (getText)
-- ============================================================

DayvinhoBlessings_Messages = {}

-- Chaves por categoria: valores são os IDs em UI.json/Translate
local _keys = {
    Fishing = {
        "UI_DayBless_Fishing_1",
        "UI_DayBless_Fishing_2",
        "UI_DayBless_Fishing_3",
        "UI_DayBless_Fishing_4",
    },
    Woodwork = {
        "UI_DayBless_Woodwork_1",
        "UI_DayBless_Woodwork_2",
        "UI_DayBless_Woodwork_3",
        "UI_DayBless_Woodwork_4",
    },
    Farming = {
        "UI_DayBless_Farming_1",
        "UI_DayBless_Farming_2",
        "UI_DayBless_Farming_3",
        "UI_DayBless_Farming_4",
    },
    Mechanics = {
        "UI_DayBless_Mechanics_1",
        "UI_DayBless_Mechanics_2",
        "UI_DayBless_Mechanics_3",
        "UI_DayBless_Mechanics_4",
    },
    MetalWelding = {
        "UI_DayBless_MetalWelding_1",
        "UI_DayBless_MetalWelding_2",
        "UI_DayBless_MetalWelding_3",
        "UI_DayBless_MetalWelding_4",
    },
    Maintenance = {
        "UI_DayBless_Maintenance_1",
        "UI_DayBless_Maintenance_2",
        "UI_DayBless_Maintenance_3",
        "UI_DayBless_Maintenance_4",
    },
    Cooking = {
        "UI_DayBless_Cooking_1",
        "UI_DayBless_Cooking_2",
        "UI_DayBless_Cooking_3",
        "UI_DayBless_Cooking_4",
    },
    Tailoring = {
        "UI_DayBless_Tailoring_1",
        "UI_DayBless_Tailoring_2",
        "UI_DayBless_Tailoring_3",
        "UI_DayBless_Tailoring_4",
    },
    Legendary = {
        "UI_DayBless_Legendary_1",
        "UI_DayBless_Legendary_2",
        "UI_DayBless_Legendary_3",
    },
    Generic = {
        "UI_DayBless_Generic_1",
        "UI_DayBless_Generic_2",
        "UI_DayBless_Generic_3",
        "UI_DayBless_Generic_4",
        "UI_DayBless_Generic_5",
    },
    End = {
        "UI_DayBless_End_1",
        "UI_DayBless_End_2",
        "UI_DayBless_End_3",
    },
}

function DayvinhoBlessings_Messages.getForSkill(skillType)
    local list = _keys[skillType] or _keys.Generic
    return getText(list[math.random(#list)])
end

function DayvinhoBlessings_Messages.getLegendary()
    local list = _keys.Legendary
    return getText(list[math.random(#list)])
end

function DayvinhoBlessings_Messages.getEnd()
    local list = _keys.End
    return getText(list[math.random(#list)])
end