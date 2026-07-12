-- ============================================================
--  Sidebar.lua -- Botao do Dayvinho na barra lateral (ISEquippedItem)
--
--  Padrao vanilla: monkey-patch em initialise, onOptionMouseDown e prerender.
--  O botao abre/fecha o painel de buffs do Dayvinho.
--  Icone Off = 42% alpha; icone On = 100% (full brightness).
--
--  Texturas:  media/ui/DayvinhoBlessings/Dayvinho_Off.png
--             media/ui/DayvinhoBlessings/Dayvinho_On.png
-- ============================================================

require "DayvinhoBlessings/Logger"
local Log = DayvinhoBlessings_Logger

local INTERNAL     = "DAYVINHO_HUD"
local BORDER_SPACE = 10   -- UI_BORDER_SPACING do ISEquippedItem (local naquele arquivo)

-- ── Patch: initialise ──────────────────────────────────────

local _orig_initialise = ISEquippedItem.initialise

ISEquippedItem.initialise = function(self)
    _orig_initialise(self)

    -- invBtn so existe para o jogador primario (playerNum == 0)
    if not self.invBtn then return end

    -- Herdar tamanho dos botoes vanilla ja criados
    local btnW = self.invBtn:getWidth()
    local btnH = self.invBtn:getHeight()

    -- Textura Off (dim) e On (bright) carregadas aqui (unicas por instancia)
    self.dayvinhoTexOff = getTexture("media/ui/DayvinhoBlessings/Dayvinho_Off.png")
    self.dayvinhoTexOn  = getTexture("media/ui/DayvinhoBlessings/Dayvinho_On.png")

    -- Posicao: logo abaixo do ultimo botao vanilla
    local y = self:getHeight() + BORDER_SPACE + 5

    self.dayvinhoBtn = ISButton:new(0, y, btnW, btnH, "", self, ISEquippedItem.onOptionMouseDown)
    self.dayvinhoBtn:setImage(self.dayvinhoTexOff)
    self.dayvinhoBtn.internal = INTERNAL
    self.dayvinhoBtn:initialise()
    self.dayvinhoBtn:instantiate()
    self.dayvinhoBtn:setDisplayBackground(false)
    self.dayvinhoBtn:ignoreWidthChange()
    self.dayvinhoBtn:ignoreHeightChange()
    self:addChild(self.dayvinhoBtn)
    self:addMouseOverToolTipItem(self.dayvinhoBtn, "Dayvinho's Blessings")
    self:setHeight(self.dayvinhoBtn:getBottom())

    Log.info("botao Dayvinho adicionado a barra lateral")
end

-- ── Patch: onOptionMouseDown ───────────────────────────────

local _orig_onOptionMouseDown = ISEquippedItem.onOptionMouseDown

ISEquippedItem.onOptionMouseDown = function(self, button, x, y)
    if button.internal == INTERNAL then
        if DayvinhoBlessings_HUD then
            DayvinhoBlessings_HUD.toggle()
        end
        return
    end
    _orig_onOptionMouseDown(self, button, x, y)
end

-- ── Patch: prerender ───────────────────────────────────────

local _orig_prerender = ISEquippedItem.prerender

ISEquippedItem.prerender = function(self)
    _orig_prerender(self)
    if not self.dayvinhoBtn then return end

    local isOn = DayvinhoBlessings_HUD ~= nil and DayvinhoBlessings_HUD.isVisible()
    self.dayvinhoBtn:setImage(isOn and self.dayvinhoTexOn or self.dayvinhoTexOff)
end
