-- ============================================================
--  Messages.lua -- Chaves de traducao (getText) para todas as
--  bencaos, maldicoes e mensagens de falha.
-- ============================================================

require "DayvinhoBlessings/Logger"

DayvinhoBlessings_Messages = {}

-- Tabela de chaves: categoria -> lista de chaves UI_*
local _keys = {
    -- -- Primeiro pickup (mensagem de boas-vindas) -------------
    Found = { "UI_DayBless_Found_1","UI_DayBless_Found_2","UI_DayBless_Found_3","UI_DayBless_Found_4" },

    -- -- Bencaos -----------------------------------------------
    xp_boost     = { "UI_DayBless_XpBoost_1",    "UI_DayBless_XpBoost_2",    "UI_DayBless_XpBoost_3",    "UI_DayBless_XpBoost_4"    },
    luck         = { "UI_DayBless_Luck_1",        "UI_DayBless_Luck_2",        "UI_DayBless_Luck_3",        "UI_DayBless_Luck_4"        },
    foraging     = { "UI_DayBless_Foraging_1",    "UI_DayBless_Foraging_2",    "UI_DayBless_Foraging_3",    "UI_DayBless_Foraging_4"    },
    gift         = { "UI_DayBless_Gift_1",        "UI_DayBless_Gift_2",        "UI_DayBless_Gift_3",        "UI_DayBless_Gift_4"        },
    full_belly   = { "UI_DayBless_FullBelly_1",   "UI_DayBless_FullBelly_2",   "UI_DayBless_FullBelly_3",   "UI_DayBless_FullBelly_4"   },
    fresh_water  = { "UI_DayBless_FreshWater_1",  "UI_DayBless_FreshWater_2",  "UI_DayBless_FreshWater_3",  "UI_DayBless_FreshWater_4"  },
    rest         = { "UI_DayBless_Rest_1",        "UI_DayBless_Rest_2",        "UI_DayBless_Rest_3",        "UI_DayBless_Rest_4"        },
    spirit       = { "UI_DayBless_Spirit_1",      "UI_DayBless_Spirit_2",      "UI_DayBless_Spirit_3",      "UI_DayBless_Spirit_4"      },
    good_mood    = { "UI_DayBless_GoodMood_1",    "UI_DayBless_GoodMood_2",    "UI_DayBless_GoodMood_3",    "UI_DayBless_GoodMood_4"    },
    inner_peace  = { "UI_DayBless_InnerPeace_1",  "UI_DayBless_InnerPeace_2",  "UI_DayBless_InnerPeace_3",  "UI_DayBless_InnerPeace_4"  },
    calm_sleep   = { "UI_DayBless_CalmSleep_1",   "UI_DayBless_CalmSleep_2",   "UI_DayBless_CalmSleep_3",   "UI_DayBless_CalmSleep_4"   },
    skilled_hands= { "UI_DayBless_SkilledHands_1","UI_DayBless_SkilledHands_2","UI_DayBless_SkilledHands_3","UI_DayBless_SkilledHands_4"},
    fisherman    = { "UI_DayBless_Fisherman_1",   "UI_DayBless_Fisherman_2",   "UI_DayBless_Fisherman_3",   "UI_DayBless_Fisherman_4"   },
    harvest      = { "UI_DayBless_Harvest_1",     "UI_DayBless_Harvest_2",     "UI_DayBless_Harvest_3",     "UI_DayBless_Harvest_4"     },
    lumberjack   = { "UI_DayBless_Lumberjack_1",  "UI_DayBless_Lumberjack_2",  "UI_DayBless_Lumberjack_3",  "UI_DayBless_Lumberjack_4"  },
    light_steps  = { "UI_DayBless_LightSteps_1",  "UI_DayBless_LightSteps_2",  "UI_DayBless_LightSteps_3",  "UI_DayBless_LightSteps_4"  },
    sharp_eyes   = { "UI_DayBless_SharpEyes_1",   "UI_DayBless_SharpEyes_2",   "UI_DayBless_SharpEyes_3",   "UI_DayBless_SharpEyes_4"   },
    instinct     = { "UI_DayBless_Instinct_1",    "UI_DayBless_Instinct_2",    "UI_DayBless_Instinct_3",    "UI_DayBless_Instinct_4"    },
    backpack     = { "UI_DayBless_Backpack_1",    "UI_DayBless_Backpack_2",    "UI_DayBless_Backpack_3",    "UI_DayBless_Backpack_4"    },
    natural_heal = { "UI_DayBless_NatHeal_1",     "UI_DayBless_NatHeal_2",     "UI_DayBless_NatHeal_3",     "UI_DayBless_NatHeal_4"     },
    resistant    = { "UI_DayBless_Resistant_1",   "UI_DayBless_Resistant_2",   "UI_DayBless_Resistant_3",   "UI_DayBless_Resistant_4"   },
    courage      = { "UI_DayBless_Courage_1",     "UI_DayBless_Courage_2",     "UI_DayBless_Courage_3",     "UI_DayBless_Courage_4"     },
    sun          = { "UI_DayBless_Sun_1",         "UI_DayBless_Sun_2",         "UI_DayBless_Sun_3",         "UI_DayBless_Sun_4"         },
    rainbow      = { "UI_DayBless_Rainbow_1",     "UI_DayBless_Rainbow_2",     "UI_DayBless_Rainbow_3",     "UI_DayBless_Rainbow_4"     },

    -- -- Fim da bencao -----------------------------------------
    End = { "UI_DayBless_End_1","UI_DayBless_End_2","UI_DayBless_End_3" },

    -- -- Maldicoes (por tipo de acao) --------------------------
    curse_burn    = { "UI_DayCurse_Burn_1",    "UI_DayCurse_Burn_2",    "UI_DayCurse_Burn_3",    "UI_DayCurse_Burn_4"    },
    curse_destroy = { "UI_DayCurse_Destroy_1", "UI_DayCurse_Destroy_2", "UI_DayCurse_Destroy_3", "UI_DayCurse_Destroy_4" },
    curse_trash   = { "UI_DayCurse_Trash_1",   "UI_DayCurse_Trash_2",   "UI_DayCurse_Trash_3",   "UI_DayCurse_Trash_4"   },
    curse_explode = { "UI_DayCurse_Explode_1", "UI_DayCurse_Explode_2", "UI_DayCurse_Explode_3", "UI_DayCurse_Explode_4" },
    curse_run     = { "UI_DayCurse_Run_1",     "UI_DayCurse_Run_2",     "UI_DayCurse_Run_3",     "UI_DayCurse_Run_4"     },
    curse_removed = { "UI_DayCurse_Removed_1", "UI_DayCurse_Removed_2", "UI_DayCurse_Removed_3", "UI_DayCurse_Removed_4" },
    curse_random  = { "UI_DayCurse_Random_1",  "UI_DayCurse_Random_2",  "UI_DayCurse_Random_3",  "UI_DayCurse_Random_4"  },

    -- -- Fim da maldicao ---------------------------------------
    CurseEnd = { "UI_DayCurse_End_1","UI_DayCurse_End_2","UI_DayCurse_End_3" },
}

local function pick(list)
    return getText(list[ZombRand(#list) + 1])
end

function DayvinhoBlessings_Messages.getForBlessing(blessingId)
    return pick(_keys[blessingId] or _keys.xp_boost)
end

function DayvinhoBlessings_Messages.getEnd()
    return pick(_keys.End)
end

function DayvinhoBlessings_Messages.getCurseMsg(triggerType)
    return pick(_keys["curse_" .. (triggerType or "destroy")] or _keys.curse_destroy)
end

function DayvinhoBlessings_Messages.getCurseEnd()
    return pick(_keys.CurseEnd)
end

function DayvinhoBlessings_Messages.getGreeting()
    return pick(_keys.Found)
end