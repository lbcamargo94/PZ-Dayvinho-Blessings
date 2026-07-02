-- ============================================================
--  Logger.lua — Sistema de logs exclusivo do DayvinhoBlessings
--
--  Uso:
--    local Log = DayvinhoBlessings_Logger
--    Log.info("mensagem")
--    Log.warn("aviso")
--    Log.error("erro")
--    Log.debug("detalhe verboso")
--    Log.try(fn, "contexto")   -- pcall + log automático do erro
--
--  Nível padrão: INFO  (DEBUG fica silencioso em produção)
--  Para ativar DEBUG em runtime: Log.setLevel("DEBUG")
-- ============================================================

DayvinhoBlessings_Logger = {}

local PREFIX    = "[DayvinhoBlessings]"
local _enabled  = true
local _LEVELS   = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local _minLevel = _LEVELS.INFO

local function emit(label, msg)
    if not _enabled then return end
    print(string.format("%s [%s] %s", PREFIX, label, tostring(msg)))
end

function DayvinhoBlessings_Logger.debug(msg)
    if _LEVELS.DEBUG >= _minLevel then emit("DEBUG", msg) end
end

function DayvinhoBlessings_Logger.info(msg)
    if _LEVELS.INFO >= _minLevel then emit("INFO", msg) end
end

function DayvinhoBlessings_Logger.warn(msg)
    if _LEVELS.WARN >= _minLevel then emit("WARN", msg) end
end

function DayvinhoBlessings_Logger.error(msg)
    if _LEVELS.ERROR >= _minLevel then emit("ERROR", msg) end
end

-- Wrapper de pcall: executa fn, loga erro com contexto se falhar.
-- Retorna ok, result — compatível com pcall nativo.
function DayvinhoBlessings_Logger.try(fn, context)
    local ok, result = pcall(fn)
    if not ok then
        local ctx = context and (context .. ": ") or ""
        emit("ERROR", ctx .. tostring(result))
    end
    return ok, result
end

function DayvinhoBlessings_Logger.setEnabled(v)
    _enabled = (v == true)
end

function DayvinhoBlessings_Logger.setLevel(name)
    _minLevel = _LEVELS[name] or _LEVELS.INFO
end