-- ============================================================
--  HUD.lua -- Overlay movel listando todos os efeitos ativos
--
--  Arrastar: click e mover (quando desbloqueado)
--  Resize: arrastar handle no canto inferior direito (largura)
--  Fechar: botao [X] no cabecalho
--  Scroll: roda do mouse ou clique no track da barra de rolagem
--  Fixar/soltar: botao direito NO PAINEL alterna lock
--
--  Layout (topo para baixo):
--    1. Cabecalho (titulo + botao X)
--    2. Fala do Dayvinho (se ativa)
--    3. Lista de efeitos (max MAX_ROWS visiveis, rolavel)
--    4. Handle de resize
--
--  Efeitos exibidos do mais recente para o mais antigo.
--  Posicao, largura, lock e visibilidade salvos em ModData.
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

-- -- Nomes de exibicao -----------------------------------------

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
    random_sound   = "Som Assustador",
    helicopter     = "O Helicoptero do Dayvinho",
    _expired       = "Efeito Encerrado",
}

-- -- Descricoes detalhadas -------------------------------------

local DESCRIPTIONS = {
    xp_boost       = "+100% XP ganho em 1 habilidade sorteada",
    luck           = "+20% Morale enquanto ativo",
    foraging       = "+25% Morale enquanto ativo",
    gift           = "2 itens aleatorios no inventario (3 se lendaria)",
    full_belly     = "Reduz fome gradualmente ao longo do tempo",
    fresh_water    = "Reduz sede em 70% imediatamente",
    rest           = "Reduz fadiga em 30% imediatamente",
    spirit         = "Reduz estresse e tedio gradualmente",
    good_mood      = "Reduz infelicidade em 50% imediatamente",
    inner_peace    = "Reduz estresse em 50% imediatamente",
    calm_sleep     = "Proximo sono sera mais reparador",
    skilled_hands  = "Endurance +20% enquanto ativo",
    fisherman      = "+20% Morale enquanto ativo",
    harvest        = "Reduz estresse em 15% imediatamente",
    lumberjack     = "Endurance +20% imediatamente",
    light_steps    = "Reduz panico em 15% imediatamente",
    sharp_eyes     = "+25% Morale enquanto ativo",
    instinct       = "Reduz panico em 30% imediatamente",
    backpack       = "Reduz desconforto de carga gradualmente",
    natural_heal   = "Reduz dor gradualmente",
    resistant      = "Restaura endurance gradualmente",
    courage        = "Reduz panico gradualmente ao longo do tempo",
    sun            = "Para a chuva imediatamente",
    rainbow        = "Reduz infelicidade em 15% imediatamente",
    bad_luck       = "Reduz Morale em 10%",
    panic_faster   = "Panico aumenta gradualmente a cada tick",
    hunger_up      = "+20% de fome imediata",
    thirst_up      = "+20% de sede imediata",
    endurance_down = "-10% de endurance imediata",
    more_noise     = "Panico aumenta gradualmente (ruido extra)",
    unhappiness_up = "+20% de infelicidade imediata",
    stress_up      = "+15% de estresse imediato",
    hallucination  = "Infelicidade leve + mensagem narrativa",
    random_sound   = "Toca som assustador e atrai zumbis proximos",
    helicopter     = "Helicoptero + zumbis em raio de 200 blocos",
    _expired       = "O efeito acabou de se encerrar",
}

-- -- Constantes de layout --------------------------------------

local MD_KEY    = "DayvinhoBlessings"
local DEFAULT_X = 10
local DEFAULT_Y = 50
local DEFAULT_W = 260
local MIN_W     = 200
local HEADER_H  = 26   -- cabecalho (titulo + botao X)
local ROW_H     = 54   -- altura de cada linha de efeito
local SPEECH_H  = 32   -- altura da fala do Dayvinho (topo da lista)
local FOOTER_H  = 14   -- espaco inferior para handle de resize
local HANDLE    = 12   -- tamanho do handle de resize
local MAX_ROWS  = 5    -- maximo de linhas visiveis antes da barra de rolagem
local SCROLL_W  = 8    -- largura da barra de rolagem
local CHAR_W    = 7    -- largura media de caractere em UIFont.Small (px)

-- -- Helpers ----------------------------------------------------

-- Trunca texto para caber em maxPx pixels (estimativa por char).
local function trunc(str, maxPx)
    if not str or str == "" then return "" end
    local maxChars = math.floor(maxPx / CHAR_W)
    if maxChars <= 3 then return "..." end
    if #str <= maxChars then return str end
    return str:sub(1, maxChars - 3) .. "..."
end

-- -- Estado -----------------------------------------------------

local _hudPanel     = nil
local _speechText   = nil
local _speechUntil  = 0
local _scrollOffset = 0   -- indice base (0=mais recente no topo)
local _lastN        = 0   -- detecta chegada de novo efeito para reset do scroll

-- -- Classe HUD -------------------------------------------------

DayvinhoBlessings_HUDPanel = ISPanel:derive("DayvinhoBlessings_HUDPanel")

function DayvinhoBlessings_HUDPanel:new(x, y, w)
    local h = HEADER_H + ROW_H + FOOTER_H
    local o = ISPanel.new(self, x, y, w or DEFAULT_W, h)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = { r=0.05, g=0.05, b=0.05, a=0.82 }
    o.borderColor     = { r=0.60, g=0.45, b=0.08, a=1.00 }
    o._moving         = false
    o._resizing       = false
    o._locked         = false
    -- cache para onMouseDown/onMouseWheel
    o._scrollNeeded        = false
    o._effectStartY        = HEADER_H
    o._visibleRows         = 1
    o._maxScroll           = 0
    o._totalN              = 0
    -- drag da barra de rolagem
    o._scrollDragging      = false
    o._scrollDragPxAccum   = 0
    o._scrollDragBaseOffset = 0
    return o
end

function DayvinhoBlessings_HUDPanel:initialise()
    ISPanel.initialise(self)
end

-- -- Interacao com mouse ----------------------------------------

function DayvinhoBlessings_HUDPanel:onMouseDown(x, y)
    local w = self:getWidth()

    -- Botao [X] fechar (canto superior direito do cabecalho)
    if y < HEADER_H and x >= w - 26 then
        self:setVisible(false)
        self:_saveLayout()
        Log.info("HUD fechado pelo botao X")
        return true
    end

    -- Barra de rolagem: thumb drag ou clique no track
    if self._scrollNeeded then
        local trackX = w - SCROLL_W
        local trackY = self._effectStartY
        local trackH = self._visibleRows * ROW_H
        if x >= trackX and y >= trackY and y <= trackY + trackH then
            -- Calcular posicao atual do thumb (mesma formula do render)
            local thumbH    = math.max(14, math.floor(trackH * self._visibleRows / math.max(1, self._totalN)))
            local thumbMaxY = math.max(1, trackH - thumbH)
            local thumbAbsY = trackY + (self._maxScroll > 0
                and math.floor(thumbMaxY * _scrollOffset / self._maxScroll) or 0)

            if y >= thumbAbsY and y < thumbAbsY + thumbH then
                -- Clique SOBRE o thumb: inicia drag
                self._scrollDragging       = true
                self._scrollDragPxAccum    = 0
                self._scrollDragBaseOffset = _scrollOffset
            else
                -- Clique fora do thumb: salta para posicao clicada
                local rel = math.max(0, y - trackY)
                _scrollOffset = math.max(0, math.min(self._maxScroll,
                    math.floor(rel / trackH * self._maxScroll + 0.5)))
            end
            self:setCapture(true)
            return true
        end
    end

    if self._locked then return end
    self:bringToTop()

    local h = self:getHeight()
    if x >= w - HANDLE and y >= h - HANDLE then
        self._resizing = true
        self._moving   = false
    else
        self._moving   = true
        self._resizing = false
    end
    self:setCapture(true)
    return true
end

local function _applyScrollDrag(self, dy)
    if not self._scrollDragging or self._maxScroll <= 0 then return end
    local trackH    = self._visibleRows * ROW_H
    local thumbH    = math.max(14, math.floor(trackH * self._visibleRows / math.max(1, self._totalN)))
    local thumbMaxY = math.max(1, trackH - thumbH)
    self._scrollDragPxAccum = self._scrollDragPxAccum + dy
    local newOffset = self._scrollDragBaseOffset +
        math.floor(self._scrollDragPxAccum * self._maxScroll / thumbMaxY + 0.5)
    _scrollOffset = math.max(0, math.min(self._maxScroll, newOffset))
end

function DayvinhoBlessings_HUDPanel:onMouseMove(dx, dy)
    if self._scrollDragging then
        _applyScrollDrag(self, dy)
    elseif self._moving then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    elseif self._resizing then
        self:setWidth(math.max(MIN_W, self:getWidth() + dx))
    end
end

function DayvinhoBlessings_HUDPanel:onMouseMoveOutside(dx, dy)
    if self._scrollDragging then
        _applyScrollDrag(self, dy)
    elseif self._moving then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    elseif self._resizing then
        self:setWidth(math.max(MIN_W, self:getWidth() + dx))
    end
end

function DayvinhoBlessings_HUDPanel:onMouseUp(x, y)
    local wasDragging = self._scrollDragging or self._moving or self._resizing
    self._scrollDragging = false
    if self._moving or self._resizing then
        self._moving   = false
        self._resizing = false
        self:_saveLayout()
    end
    if wasDragging then self:setCapture(false) end
end

function DayvinhoBlessings_HUDPanel:onMouseUpOutside(x, y)
    local wasDragging = self._scrollDragging or self._moving or self._resizing
    self._scrollDragging = false
    if self._moving or self._resizing then
        self._moving   = false
        self._resizing = false
        self:_saveLayout()
    end
    if wasDragging then self:setCapture(false) end
end

-- Roda do mouse: rolar pelos efeitos
-- del > 0 = rolar para baixo (ver mais antigos) | del < 0 = rolar para cima (ver mais recentes)
function DayvinhoBlessings_HUDPanel:onMouseWheel(del)
    if not self._scrollNeeded then return false end
    _scrollOffset = math.max(0, math.min(self._maxScroll, _scrollOffset + del))
    return true
end

-- Botao direito NO PAINEL: fixa/solta
function DayvinhoBlessings_HUDPanel:onRightMouseDown(x, y)
    self._locked = not self._locked
    self:_saveLayout()
    Log.info("HUD " .. (self._locked and "fixado" or "solto"))
    return true
end

-- -- Persistencia -----------------------------------------------

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

-- -- Render -----------------------------------------------------

function DayvinhoBlessings_HUDPanel:render()
    local infoList = DayvinhoBlessings_Main and DayvinhoBlessings_Main.getHUDInfoAll()
    local n = infoList and #infoList or 0

    -- Novo efeito chegou: reset scroll para mostrar o mais recente
    if n ~= _lastN then
        if n > _lastN then _scrollOffset = 0 end
        _lastN = n
    end

    local w = self:getWidth()
    local t = math.floor(getTimeInMillis() / 1000)

    -- Fala ativa?
    local hasSpeech = _speechText ~= nil and t < _speechUntil
    if not hasSpeech then _speechText = nil end

    -- Calcular layout
    local speechH       = hasSpeech and SPEECH_H or 0
    local effectStartY  = HEADER_H + speechH
    local visibleRows   = math.min(math.max(n, 1), MAX_ROWS)
    local scrollNeeded  = n > MAX_ROWS
    local maxScroll     = math.max(0, n - MAX_ROWS)
    _scrollOffset       = math.max(0, math.min(maxScroll, _scrollOffset))

    local effectH  = visibleRows * ROW_H
    local targetH  = HEADER_H + speechH + effectH + FOOTER_H
    if math.abs(self:getHeight() - targetH) > 1 then
        self:setHeight(targetH)
    end
    local h = self:getHeight()

    -- Guardar cache para handlers de mouse
    self._scrollNeeded  = scrollNeeded
    self._effectStartY  = effectStartY
    self._visibleRows   = visibleRows
    self._maxScroll     = maxScroll
    self._totalN        = n

    -- Largura util para texto (desconta scrollbar e padding)
    local scrollPad = scrollNeeded and (SCROLL_W + 4) or 0
    local textW     = w - 8 - scrollPad   -- 8 = padding esquerda

    -- Cor da borda (cursa > bencao > neutro)
    local hasBlessing, hasCurse = false, false
    if infoList then
        for _, info in ipairs(infoList) do
            if not info.isExpired then
                if info.isCurse then hasCurse = true
                else hasBlessing = true end
            end
        end
    end
    if hasCurse then
        self.borderColor = { r=0.80, g=0.08, b=0.08, a=1 }
    elseif hasBlessing then
        self.borderColor = { r=0.65, g=0.48, b=0.08, a=1 }
    else
        self.borderColor = { r=0.40, g=0.40, b=0.40, a=1 }
    end

    ISPanel.render(self)

    -- --------------------------------------------------------
    -- 1. CABECALHO
    -- --------------------------------------------------------
    self:drawText("== Dayvinho ==", 8, 5, 0.75, 0.58, 0.12, 1, UIFont.Small)

    self:drawRect(w - 24, 4, 20, 18, 0.85, 0.60, 0.10, 0.10)
    self:drawText("X", w - 18, 5, 1, 1, 1, 1, UIFont.Small)

    if self._locked then
        self:drawText("[F]", w - 52, 5, 0.45, 0.45, 0.45, 0.8, UIFont.Small)
    end

    self:drawRect(0, HEADER_H - 2, w, 1, 0.6, 0.35, 0.25, 0.08)

    -- --------------------------------------------------------
    -- 2. FALA DO DAYVINHO (logo apos o cabecalho)
    -- --------------------------------------------------------
    if hasSpeech then
        -- Fundo levemente destacado
        self:drawRect(0, HEADER_H, w, SPEECH_H, 0.10, 0.08, 0.04, 0.55)
        -- Texto da fala (truncado para a largura)
        local speechStr = trunc("[Dayvinho] " .. _speechText, textW + scrollPad - 4)
        self:drawText(speechStr, 8, HEADER_H + 8, 0.95, 0.82, 0.28, 1, UIFont.Small)
        -- Linha separadora inferior da fala
        self:drawRect(0, HEADER_H + SPEECH_H - 1, w, 1, 0.5, 0.70, 0.55, 0.20)
    end

    -- --------------------------------------------------------
    -- 3. LISTA DE EFEITOS (mais recente no topo = lista invertida)
    -- --------------------------------------------------------
    if n == 0 then
        self:drawText("Nenhum efeito ativo", 8, effectStartY + 18,
            0.38, 0.38, 0.38, 1, UIFont.Small)
    else
        for row = 1, visibleRows do
            -- Indice na lista original (invertida: n = mais recente)
            local srcIdx = n - (_scrollOffset + row - 1)
            if srcIdx < 1 then break end

            local info = infoList[srcIdx]
            local ry   = effectStartY + (row - 1) * ROW_H

            -- Cor do tipo
            local nr, ng, nb
            if info.isExpired then
                nr, ng, nb = 0.55, 0.55, 0.55
            elseif info.isCurse then
                nr, ng, nb = 1.00, 0.28, 0.28
            else
                nr, ng, nb = 1.00, 0.85, 0.18
            end

            -- Linha 1: tipo + nome (truncado)
            local nameStr
            if info.isExpired then
                nameStr = info.isCurse and "[ Maldicao Encerrada ]" or "[ Bencao Encerrada ]"
            else
                local prefix = info.isCurse and "[Maldicao] " or "[Bencao] "
                nameStr = prefix .. (DISPLAY_NAMES[info.id] or info.displayName or info.id)
            end
            self:drawText(trunc(nameStr, textW), 8, ry + 4, nr, ng, nb, 1, UIFont.Small)

            -- Linha 2: descricao (truncada, recuada)
            local desc = DESCRIPTIONS[info.id] or info.description or ""
            if desc ~= "" then
                self:drawText(trunc(desc, textW - 4), 12, ry + 20,
                    0.62, 0.62, 0.62, 1, UIFont.Small)
            end

            -- Linha 3: timer
            self:drawText(trunc(info.timerText or "", textW - 4), 12, ry + 36,
                0.50, 0.50, 0.50, 1, UIFont.Small)

            -- Separador entre linhas (exceto a ultima visivel)
            if row < visibleRows and srcIdx > 1 then
                self:drawRect(8, ry + ROW_H - 2, w - 16 - scrollPad, 1,
                    0.5, 0.25, 0.25, 0.25)
            end
        end
    end

    -- --------------------------------------------------------
    -- 4. BARRA DE ROLAGEM (quando n > MAX_ROWS)
    -- --------------------------------------------------------
    if scrollNeeded then
        local trackX = w - SCROLL_W
        local trackY = effectStartY
        local trackH = visibleRows * ROW_H

        -- Track (fundo da barra)
        self:drawRect(trackX, trackY, SCROLL_W, trackH, 0.7, 0.15, 0.15, 0.15)

        -- Thumb (posicao atual)
        local thumbH   = math.max(14, math.floor(trackH * visibleRows / n))
        local thumbMaxY = trackH - thumbH
        local thumbY   = trackY + math.floor(thumbMaxY * _scrollOffset / maxScroll)
        self:drawRect(trackX + 1, thumbY, SCROLL_W - 2, thumbH, 0.85, 0.55, 0.42, 0.18)

        -- Indicador de scroll no cabecalho (discreto)
        local scrollLabel = string.format("%d/%d", _scrollOffset + 1,
            math.max(1, n - MAX_ROWS + 1))
        self:drawText(scrollLabel, trackX - 28, 5, 0.40, 0.40, 0.40, 0.7, UIFont.Small)
    end

    -- --------------------------------------------------------
    -- 5. HANDLE DE RESIZE (canto inferior direito)
    -- --------------------------------------------------------
    self:drawRect(w - HANDLE, h - HANDLE, HANDLE, HANDLE, 0.7, 0.40, 0.40, 0.50)
end

-- -- API global -------------------------------------------------

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

-- Exibe a fala do Dayvinho no HUD por `duration` segundos.
-- Abre o HUD automaticamente se estiver fechado.
-- O scroll e resetado para o topo para garantir visibilidade da fala.
function DayvinhoBlessings_HUD.showSpeech(msg, duration)
    if not msg or msg == "" then return end
    _speechText   = msg
    _speechUntil  = math.floor(getTimeInMillis() / 1000) + (duration or 20)
    _scrollOffset = 0
    if _hudPanel and not _hudPanel:isVisible() then
        _hudPanel:setVisible(true)
        _hudPanel:_saveLayout()
    end
end

-- -- Criacao e registro -----------------------------------------

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
    _scrollOffset = 0
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
    _scrollOffset = 0
end

Events.OnGameStart.Add(createHUD)
Events.OnLoad.Add(onLoad)
