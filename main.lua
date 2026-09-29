-- EVINI Loader
-- Carrega o Nitrogen original, sem modificar seu codigo interno.
-- MoonSec V3: branding do hub, tecla Insert e transparencia NAO foram alterados.
local SOURCE_URL = "https://raw.githubusercontent.com/nitrogenhbexp/nitrogen-hitbox-expander/d44c0a5665baa885f1d93d4349b3bc4da7b2f090/nitrogen%20hitbox%20expander"

warn("[EVINI] Loader do original: nome do hub, tecla Insert e transparencia permanecem inalterados.")

local downloaded, source = pcall(function()
    return game:HttpGet(SOURCE_URL, true)
end)
if not downloaded then
    error("[EVINI] Falha ao baixar o original: " .. tostring(source), 0)
end
if type(loadstring) ~= "function" then
    error("[EVINI] Este ambiente nao disponibiliza loadstring.", 0)
end
local run, compileError = loadstring(source, "EVINI_Original")
if not run then
    error("[EVINI] Falha ao compilar o original: " .. tostring(compileError), 0)
end
return run()
