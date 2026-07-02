-- ============================================================
--  HUD.lua — Overlay movel listando todos os efeitos ativos
--
--  Arrastar: click e mover (quando desbloqueado)
--  Resize: arrastar handle no canto inferior direito (largura)
--  Fechar: botao [X] no cabecalho
--  Reabrir: botao direito em item do inventario → "Mostrar HUD"
--  Fixar/soltar: botao direito NO PAINEL alterna lock
--
--  Posicao, largura, lock e visibilidade salvos em ModData
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

-- ── Nomes de exibicao ─────────────────────────────────────────

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
    _expired       = "Efeito Encerrado",
}

-- ── Descricoes detalhadas ─────────────────────────────────────

local DESCRIPTIONS = {
    -- Bencoes
    xp_boost       = "+10% XP ganho em 1 habilidade sorteada",
    luck           = "+10 de Luck enquanto ativo",
    foraging       = "Raio de coleta aumentado em 15%",
    gift           = "Item bonus no inventario",
    full_belly     = "Reduz fome gradualmente ao longo do tempo",
    fresh_water    = "Reduz sede em 50% imediatamente",
    rest           = "Reduz fadiga em 15% imediatamente",
    spirit         = "Reduz estresse e tedio gradualmente",
    good_mood      = "Reduz infelicidade em 25% imediatamente",
    inner_peace    = "Reduz estresse em 30% imediatamente",
    calm_sleep     = "Proximo sono sera mais reparador",
    skilled_hands  = "Velocidade de acao +10% enquanto ativo",
    fisherman      = "Multiplicador de pesca +10% enquanto ativo",
    harvest        = "Plantas crescem mais rapido + bonus de espirito",
    lumberjack     = "Mais toras por corte + bonus de endurance",
    light_steps    = "Menos ruido ao se mover enquanto ativo",
    sharp_eyes     = "Raio de coleta +12% enquanto ativo",
    instinct       = "Reduz panico em 10% imediatamente",
    backpack       = "Reduz desconforto de carga gradualmente",
    natural_heal   = "Recuperacao de ferimentos gradual",
    resistant      = "Restaura endurance gradualmente",
    courage        = "Reduz panico gradualmente ao longo do tempo",
    sun            = "Para a chuva imediatamente",
    rainbow        = "Reduz infelicidade levemente",
    -- Maldicoes
    bad_luck       = "Reduz Morale (surrogate de Luck) em 10%",
    panic_faster   = "Panico aumenta gradualmente a cada tick",
    hunger_up      = "+20% de fome imediata",
    thirst_up      = "+20% de sede imediata",
    endurance_down = "-10% de endurance imediata",
    more_noise     = "Panico aumenta gradualmente (ruido extra)",
    unhappiness_up = "+20% de infelicidade imediata",
    stress_up      = "+15% de estresse imediato",
    hallucination  = "Infelicidade leve + mensagem narrativa",
    -- Notificacao de expiração
    _expired       = "O efeito acabou de se encerrar",
}

-- ── Constantes de layout ──────────────────────────────────────

local MD_KEY    = "DayvinhoBlessings"
local DEFAULT_X = 10
local DEFAULT_Y = 50
local DEFAULT_W = 260
local MIN_W     = 200
local HEADER_H  = 26   -- altura do cabecalho (titulo + botao X)
local ROW_H     = 54   -- altura de cada linha de efeito (3 linhas de texto)
local FOOTER_H  = 14   -- espaco inferior para handle de resize
local HANDLE    = 12   -- tamanho do handle de resize

-- ── Classe HUD ────────────────────────────────────────────────

DayvinhoBlessings_HUDPanel = ISPanel:derive("DayvinhoBlessings_HUDPanel")

function DayvinhoBlessings_HUDPanel:new(x, y, w)
    -- Altura calculada com base no numero de efeitos (minimo 1 linha)
    local h = HEADER_H + ROW_H + FOOTER_H
    local o = ISPanel.new(self, x, y, w or DEFAULT_W, h)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = { r=0.05, g=0.05, b=0.05, a=0.82 }
    o.borderColor     = { r=0.60, g=0.45, b=0.08, a=1.00 }
    o._moving   = false
    o._resizing = false
    o._locked   = false
    return o
end

function DayvinhoBlessings_HUDPanel:initialise()
    ISPanel.initialise(self)
end

-- ── Interacao com mouse ───────────────────────────────────────

function DayvinhoBlessings_HUDPanel:onMouseDown(x, y)
    local w = self:getWidth()

    -- Botao [X] no cabecalho (area: x > w-26, y < HEADER_H)
    if y < HEADER_H and x >= w - 26 then
        self:setVisible(false)
        self:_saveLayout()
        Log.info("HUD fechado pelo botao X")
        return true
    end

    if self._locked then return end
    self:bringToTop()

    local h = self:getHeight()
    -- Handle de resize no canto inferior direito
    if x >= w - HANDLE and y >= h - HANDLE then
        self._resizing = true
        self._moving   = false
    else
        self._moving   = true
        self._resizing = false
    end
    return true
end

function DayvinhoBlessings_HUDPanel:onMouseMove(dx, dy)
    if self._moving then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    elseif self._resizing then
        -- Apenas largura; altura e calculada automaticamente pelo conteudo
        self:setWidth(math.max(MIN_W, self:getWidth() + dx))
    end
end

function DayvinhoBlessings_HUDPanel:onMouseMoveOutside(dx, dy)
    if self._moving then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    elseif self._resizing then
        self:setWidth(math.max(MIN_W, self:getWidth() + dx))
    end
end

function DayvinhoBlessings_HUDPanel:onMouseUp(x, y)
    if self._moving or self._resizing then
        self._moving   = false
        self._resizing = false
        self:_saveLayout()
    end
end

function DayvinhoBlessings_HUDPanel:onMouseUpOutside(x, y)
    if self._moving or self._resizing then
        self._moving   = false
        self._resizing = false
        self:_saveLayout()
    end
end

-- Botao direito NO PAINEL: fixa/solta
function DayvinhoBlessings_HUDPanel:onRightMouseDown(x, y)
    self._locked = not self._locked
    self:_saveLayout()
    Log.info("HUD " .. (self._locked and "fixado" or "solto"))
    return true
end

-- ── Persistencia ──────────────────────────────────────────────

function DayvinhoBlessings_HUDPanel:_saveLayout()
    pcall(function()
        local player = getPlayer()
        if not player then return end
        local md = player:getModData()
        md[MD_KEY] = md[MD_KEY] or {}
        md[MD_KEY].hudX       = self:getX()
        md[MD_KEY].hudY       = self:getY()
        md[MD_KEY].hudW       = self:getWidth()
        md[MD_KEY].hudLocked  = self._locked
        md[MD_KEY].hudVisible = self:isVisible()
    end)
end

-- ── Render ────────────────────────────────────────────────────

function DayvinhoBlessings_HUDPanel:render()
    local infoList = DayvinhoBlessings_Main and DayvinhoBlessings_Main.getHUDInfoAll()
    local n = infoList and #infoList or 0

    local w = self:getWidth()

    -- Ajuste automatico de altura com base no numero de efeitos
    local targetH = HEADER_H + math.max(1, n) * ROW_H + FOOTER_H
    if math.abs(self:getHeight() - targetH) > 1 then
        self:setHeight(targetH)
    end
    local h = self:getHeight()

    -- Borda: ouro se bencao dominante, vermelho se maldicao, cinza se expirado
    local hasBlessing, hasCurse, hasExpired = false, false, false
    if infoList then
        for _, info in ipairs(infoList) do
            if info.isExpired then hasExpired = true
            elseif info.isCurse then hasCurse = true
            else hasBlessing = true end
        end
    end
    if hasCurse then
        self.borderColor = { r=0.80, g=0.08, b=0.08, a=1 }
    elseif hasBlessing then
        self.borderColor = { r=0.65, g=0.48, b=0.08, a=1 }
    else
        self.borderColor = { r=0.40, g=0.40, b=0.40, a=1 }
    end

    ISPanel.render(self)  -- fundo + borda

    -- ── Cabecalho ────────────────────────────────────────────

    self:drawText("== Dayvinho ==", 8, 5, 0.75, 0.58, 0.12, 1, UIFont.Small)

    -- Botao [X] fechar
    self:drawRect(w - 24, 4, 20, 18, 0.85, 0.60, 0.10, 0.10)
    self:drawText("X",    w - 18, 5, 1, 1, 1, 1, UIFont.Small)

    -- Indicador de lock
    if self._locked then
        self:drawText("[F]", w - 52, 5, 0.45, 0.45, 0.45, 0.8, UIFont.Small)
    end

    -- Linha separadora do cabecalho
    self:drawRect(0, HEADER_H - 2, w, 1, 0.6, 0.35, 0.25, 0.08, 0.08)

    -- ── Linha "nenhum efeito" ─────────────────────────────────

    if n == 0 then
        self:drawText("Nenhum efeito ativo", 8, HEADER_H + 18, 0.38, 0.38, 0.38, 1, UIFont.Small)
        -- Handle de resize
        self:drawRect(w - HANDLE, h - HANDLE, HANDLE, HANDLE, 0.7, 0.40, 0.40, 0.50)
        return
    end

    -- ── Linhas de efeito ─────────────────────────────────────

    for idx, info in ipairs(infoList) do
        local ry = HEADER_H + (idx - 1) * ROW_H

        -- Cor do tipo
        local nr, ng, nb
        if info.isExpired then
            nr, ng, nb = 0.55, 0.55, 0.55
        elseif info.isCurse then
            nr, ng, nb = 1.00, 0.28, 0.28
        else
            nr, ng, nb = 1.00, 0.85, 0.18
        end

        -- Linha 1: tipo + nome
        local nameStr
        if info.isExpired then
            nameStr = info.isCurse and "[ Maldicao Encerrada ]" or "[ Bencao Encerrada ]"
        else
            local prefix = info.isCurse and "[Maldicao] " or "[Bencao] "
            nameStr = prefix .. (DISPLAY_NAMES[info.id] or info.id)
        end
        self:drawText(nameStr, 8, ry + 4, nr, ng, nb, 1, UIFont.Small)

        -- Linha 2: descricao
        local desc = DESCRIPTIONS[info.id] or ""
        if desc ~= "" then
            self:drawText(desc, 12, ry + 20, 0.62, 0.62, 0.62, 1, UIFont.Small)
        end

        -- Linha 3: timer
        self:drawText(info.timerText, 12, ry + 36, 0.50, 0.50, 0.50, 1, UIFont.Small)

        -- Separador entre linhas (exceto a ultima)
        if idx < n then
            self:drawRect(8, ry + ROW_H - 2, w - 16, 1, 0.5, 0.25, 0.25, 0.25, 0.25)
        end
    end

    -- Handle de resize (canto inferior direito)
    self:drawRect(w - HANDLE, h - HANDLE, HANDLE, HANDLE, 0.7, 0.40, 0.40, 0.50)
end

-- ── API global ────────────────────────────────────────────────

DayvinhoBlessings_HUD = {}

function DayvinhoBlessings_HUD.toggle()
    if not _hudPanel then return end
    local newVis = not _hudPanel:isVisible()
    _hudPanel:setVisible(newVis)
    _hudPanel:_saveLayout()
    Log.info("HUD " .. (newVis and "mostrado" or "ocultado"))
end

function DayvinhoBlessings_HUD.isVisible()
    return _hudPanel ~= nil and _hudPanel:isVisible()
end

function DayvinhoBlessings_HUD.show()
    if not _hudPanel then return end
    if not _hudPanel:isVisible() then
        _hudPanel:setVisible(true)
        _hudPanel:_saveLayout()
    end
end

-- ── Criacao e registro ────────────────────────────────────────

local _hudPanel = nil

local function _loadLayout()
    local x, y, w, locked, visible = DEFAULT_X, DEFAULT_Y, DEFAULT_W, false, true
    pcall(function()
        local player = getPlayer()
        if not player then return end
        local md = player:getModData()
        if not (md and md[MD_KEY]) then return end
        x      = md[MD_KEY].hudX      or x
        y      = md[MD_KEY].hudY      or y
        w      = md[MD_KEY].hudW      or w
        locked = md[MD_KEY].hudLocked or locked
        local v = md[MD_KEY].hudVisible
        visible = (v == nil) and true or v
    end)
    return x, y, w, locked, visible
end

local function createHUD()
    if _hudPanel then return end
    local x, y, w, locked, visible = _loadLayout()
    _hudPanel = DayvinhoBlessings_HUDPanel:new(x, y, w)
    _hudPanel._locked = locked
    _hudPanel:initialise()
    _hudPanel:addToUIManager()
    _hudPanel:setVisible(visible)
    Log.info(string.format("HUD criado em (%d,%d) w=%d locked=%s vis=%s",
        x, y, w, tostring(locked), tostring(visible)))
end

local function onLoad()
    if not _hudPanel then
        createHUD()
        return
    end
    local x, y, w, locked, visible = _loadLayout()
    _hudPanel:setX(x)
    _hudPanel:setY(y)
    _hudPanel:setWidth(w)
    _hudPanel._locked = locked
    _hudPanel:setVisible(visible)
end

Events.OnGameStart.Add(createHUD)
Events.OnLoad.Add(onLoad)