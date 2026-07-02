-- ============================================================
--  HUD.lua — Overlay on-screen com bênção/maldição ativa
--
--  Mostra uma caixinha no canto superior esquerdo com:
--    • Nome do efeito ativo (dourado = bênção, vermelho = maldição)
--    • Timer de duração (M:SS)
--    • "Encerrado" por 6 segundos após o efeito acabar
--
--  Atualizado a cada render frame via ISPanel:render()
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

-- ── Nomes de exibição ─────────────────────────────────────────

local DISPLAY_NAMES = {
    xp_boost       = "XP Boost",
    luck           = "Sorte",
    foraging       = "Achado Valioso",
    gift           = "Presente do Jardim",
    full_belly     = "Barriga Cheia",
    fresh_water    = "Agua Fresca",
    rest           = "Descanso Revigorante",
    spirit         = "Espirito Forte",
    good_mood      = "Bom Humor",
    inner_peace    = "Paz Interior",
    calm_sleep     = "Sono Tranquilo",
    skilled_hands  = "Maos Habilidosas",
    fisherman      = "Pescador Abencado",
    harvest        = "Colheita Feliz",
    lumberjack     = "Lenhador Sortudo",
    light_steps    = "Passos Leves",
    sharp_eyes     = "Olhos Atentos",
    instinct       = "Instinto de Sobrev.",
    backpack       = "Mochila Organizada",
    natural_heal   = "Cura Natural",
    resistant      = "Corpo Resistente",
    courage        = "Bencao da Coragem",
    sun            = "Sol Abencado",
    rainbow        = "Arco-iris",
    bad_luck       = "Ma Sorte",
    panic_faster   = "Panico Acelerado",
    hunger_up      = "Fome Repentina",
    thirst_up      = "Sede Repentina",
    endurance_down = "Corpo Fraco",
    more_noise     = "Mais Barulho",
    unhappiness_up = "Infelicidade",
    stress_up      = "Estresse",
    hallucination  = "Alucinacao",
}

-- ── Classe HUD ────────────────────────────────────────────────

DayvinhoBlessings_HUDPanel = ISPanel:derive("DayvinhoBlessings_HUDPanel")

function DayvinhoBlessings_HUDPanel:new(x, y)
    local o = ISPanel.new(self, x, y, 230, 64)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.78 }
    o.borderColor     = { r = 0.75, g = 0.55, b = 0.10, a = 1.00 }
    return o
end

function DayvinhoBlessings_HUDPanel:initialise()
    ISPanel.initialise(self)
end

function DayvinhoBlessings_HUDPanel:render()
    -- Acessa Main em tempo de execucao (evita dependencia de ordem de carga)
    local info = DayvinhoBlessings_Main and DayvinhoBlessings_Main.getHUDInfo()
    if not info then return end  -- nenhum efeito ativo: painel invisivel

    -- Borda: vermelha para maldicao, dourada para bencao, cinza para expirado
    if info.isExpired then
        self.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
    elseif info.isCurse then
        self.borderColor = { r = 0.85, g = 0.10, b = 0.10, a = 1 }
    else
        self.borderColor = { r = 0.75, g = 0.55, b = 0.10, a = 1 }
    end

    ISPanel.render(self)  -- desenha fundo + borda

    -- Linha 1: nome do efeito
    local r, g, b = 1, 0.85, 0.20          -- dourado (bencao)
    if info.isCurse   then r, g, b = 1, 0.30, 0.30 end  -- vermelho (maldicao)
    if info.isExpired then r, g, b = 0.60, 0.60, 0.60 end  -- cinza (expirado)

    local label
    if info.isExpired then
        label = info.isCurse and "[ Maldicao Encerrada ]" or "[ Bencao Encerrada ]"
    else
        local prefix = info.isCurse and "Maldicao: " or "Bencao: "
        label = prefix .. (DISPLAY_NAMES[info.id] or info.id)
    end

    self:drawText(label,          10, 8,  r, g, b, 1, UIFont.Small)
    self:drawText(info.timerText, 10, 30, 0.80, 0.80, 0.80, 1, UIFont.Small)
end

-- ── Criação e registro ────────────────────────────────────────

local _hudPanel = nil

local function createHUD()
    if _hudPanel then
        return  -- ja criado; render() trata visibilidade dinamicamente
    end
    local x = 10
    local y = 50
    _hudPanel = DayvinhoBlessings_HUDPanel:new(x, y)
    _hudPanel:initialise()
    _hudPanel:addToUIManager()
    Log.info("HUD criado em (" .. x .. ", " .. y .. ")")
end

Events.OnGameStart.Add(createHUD)
Events.OnLoad.Add(createHUD)