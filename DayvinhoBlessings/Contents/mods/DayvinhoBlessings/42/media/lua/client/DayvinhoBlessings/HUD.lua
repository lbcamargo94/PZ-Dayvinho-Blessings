-- ============================================================
--  HUD.lua — Overlay movel com bencao/maldicao ativa
--
--  Arrastar: segurar e mover o painel (quando desbloqueado)
--  Redimensionar: arrastar o canto inferior direito (handle)
--  Fixar/soltar: clique direito alterna o modo de bloqueio
--
--  Posicao e tamanho persistidos em player:getModData()
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
}

-- ── Constantes ────────────────────────────────────────────────

local MD_KEY    = "DayvinhoBlessings"
local DEFAULT_X = 10
local DEFAULT_Y = 50
local DEFAULT_W = 240
local DEFAULT_H = 68
local MIN_W     = 180
local MIN_H     = 56
local HANDLE    = 12   -- tamanho em px do canto de redimensionamento

-- ── Classe HUD ────────────────────────────────────────────────

DayvinhoBlessings_HUDPanel = ISPanel:derive("DayvinhoBlessings_HUDPanel")

function DayvinhoBlessings_HUDPanel:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w or DEFAULT_W, h or DEFAULT_H)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = { r=0.05, g=0.05, b=0.05, a=0.78 }
    o.borderColor     = { r=0.75, g=0.55, b=0.10, a=1.00 }
    o._moving   = false
    o._resizing = false
    o._locked   = false
    o._lastId   = nil   -- detecta mudanca de efeito para log
    return o
end

function DayvinhoBlessings_HUDPanel:initialise()
    ISPanel.initialise(self)
end

-- ── Drag para mover ───────────────────────────────────────────

function DayvinhoBlessings_HUDPanel:onMouseDown(x, y)
    if self._locked then return end
    self:bringToTop()
    local w, h = self:getWidth(), self:getHeight()
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
        self:setWidth( math.max(MIN_W, self:getWidth()  + dx))
        self:setHeight(math.max(MIN_H, self:getHeight() + dy))
    end
end

function DayvinhoBlessings_HUDPanel:onMouseMoveOutside(dx, dy)
    if self._moving then
        self:setX(self:getX() + dx)
        self:setY(self:getY() + dy)
    elseif self._resizing then
        self:setWidth( math.max(MIN_W, self:getWidth()  + dx))
        self:setHeight(math.max(MIN_H, self:getHeight() + dy))
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

-- ── Click direito: fixar/soltar ───────────────────────────────

function DayvinhoBlessings_HUDPanel:onRightMouseDown(x, y)
    self._locked = not self._locked
    self:_saveLayout()
    Log.info("HUD " .. (self._locked and "fixado" or "solto"))
    return true
end

-- ── Persistencia de posicao/tamanho ──────────────────────────

function DayvinhoBlessings_HUDPanel:_saveLayout()
    pcall(function()
        local player = getPlayer()
        if not player then return end
        local md = player:getModData()
        md[MD_KEY] = md[MD_KEY] or {}
        md[MD_KEY].hudX      = self:getX()
        md[MD_KEY].hudY      = self:getY()
        md[MD_KEY].hudW      = self:getWidth()
        md[MD_KEY].hudH      = self:getHeight()
        md[MD_KEY].hudLocked = self._locked
    end)
end

-- ── Render ────────────────────────────────────────────────────

function DayvinhoBlessings_HUDPanel:render()
    local info = DayvinhoBlessings_Main and DayvinhoBlessings_Main.getHUDInfo()

    local w, h = self:getWidth(), self:getHeight()

    if not info then
        -- Limpa explicitamente para nao deixar conteudo antigo visivel
        -- quando o efeito encerra e outro ainda nao comecou.
        self:drawRect(0, 0, w, h, 0, 0, 0, 0)
        return
    end

    -- Log de transicao entre efeitos
    if info.id ~= self._lastId then
        Log.debug("HUD: " .. tostring(self._lastId) .. " -> " .. tostring(info.id))
        self._lastId = info.id
    end

    -- Borda dinamica por tipo
    if info.isExpired then
        self.borderColor = { r=0.45, g=0.45, b=0.45, a=1 }
    elseif info.isCurse then
        self.borderColor = { r=0.85, g=0.10, b=0.10, a=1 }
    else
        self.borderColor = { r=0.75, g=0.55, b=0.10, a=1 }
    end

    ISPanel.render(self)  -- limpa area e desenha fundo + borda

    -- Cor do nome
    local r, g, b = 1, 0.85, 0.20          -- dourado (bencao)
    if info.isCurse   then r, g, b = 1,    0.30, 0.30 end   -- vermelho
    if info.isExpired then r, g, b = 0.60, 0.60, 0.60 end   -- cinza

    local label
    if info.isExpired then
        label = info.isCurse and "[ Maldicao Encerrada ]" or "[ Bencao Encerrada ]"
    else
        local prefix = info.isCurse and "Maldicao: " or "Bencao: "
        label = prefix .. (DISPLAY_NAMES[info.id] or info.id)
    end

    self:drawText(label,          8, 6,       r,    g,    b,    1, UIFont.Small)
    self:drawText(info.timerText, 8, h/2 + 2, 0.80, 0.80, 0.80, 1, UIFont.Small)

    -- Handle de redimensionamento (canto inferior direito)
    self:drawRect(w - HANDLE, h - HANDLE, HANDLE, HANDLE, 0.7, 0.45, 0.45, 0.55)

    -- Indicador de bloqueio
    if self._locked then
        self:drawText("[F]", w - HANDLE - 22, h - HANDLE, 0.5, 0.5, 0.5, 0.7, UIFont.Small)
    end
end

-- ── Criacao e registro ────────────────────────────────────────

local _hudPanel = nil

local function _loadLayout()
    local x, y, w, h, locked = DEFAULT_X, DEFAULT_Y, DEFAULT_W, DEFAULT_H, false
    pcall(function()
        local player = getPlayer()
        if not player then return end
        local md = player:getModData()
        if not (md and md[MD_KEY]) then return end
        x      = md[MD_KEY].hudX      or x
        y      = md[MD_KEY].hudY      or y
        w      = md[MD_KEY].hudW      or w
        h      = md[MD_KEY].hudH      or h
        locked = md[MD_KEY].hudLocked or locked
    end)
    return x, y, w, h, locked
end

local function createHUD()
    if _hudPanel then return end
    local x, y, w, h, locked = _loadLayout()
    _hudPanel = DayvinhoBlessings_HUDPanel:new(x, y, w, h)
    _hudPanel._locked = locked
    _hudPanel:initialise()
    _hudPanel:addToUIManager()
    Log.info(string.format("HUD criado em (%d,%d) %dx%d locked=%s", x, y, w, h, tostring(locked)))
end

local function onLoad()
    if not _hudPanel then
        createHUD()
        return
    end
    -- Reposiciona com layout salvo ao carregar save
    local x, y, w, h, locked = _loadLayout()
    _hudPanel:setX(x)
    _hudPanel:setY(y)
    _hudPanel:setWidth(w)
    _hudPanel:setHeight(h)
    _hudPanel._locked = locked
end

Events.OnGameStart.Add(createHUD)
Events.OnLoad.Add(onLoad)