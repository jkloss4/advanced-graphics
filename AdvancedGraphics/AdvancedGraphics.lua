-- Advanced Graphics: graphics settings (console variables) that aren't in the game's options menus, on one options
-- page in Blizzard's settings style. Each control reads and sets the game's own setting, so nothing is saved by the
-- addon; the game keeps them in its config. A setting the client doesn't have is left off the page (HDR, linear
-- lighting and bloom are WoW: Forever only), and a section with none is left out.
--
-- Several of these (clutter, object detail) are also set by the menus' quality presets: changing the matching menu
-- slider later puts the preset's value back.

local _, ns = ...
local Kit = ns.SettingsKit

-- Whether this client has the setting
local function Exists(cvar)
    return C_CVar.GetCVarDefault(cvar) ~= nil
end

local function GetNumber(cvar)
    return tonumber(C_CVar.GetCVar(cvar)) or tonumber(C_CVar.GetCVarDefault(cvar)) or 0
end

local function SetNumber(cvar, value)
    -- whole numbers without a decimal point, others to 2 places (what the sliders step by)
    C_CVar.SetCVar(cvar, value == math.floor(value) and tostring(value) or ("%.2f"):format(value))
end

local function On(cvar)
    return C_CVar.GetCVarBool(cvar) and true or false
end

local used = {} -- every setting on the page, for Defaults

local page = Kit.NewPage("Advanced Graphics", {
    onDefaults = function()
        for cvar in pairs(used) do C_CVar.SetCVar(cvar, C_CVar.GetCVarDefault(cvar)) end
    end,
})

-- A section's header, only when the client has at least one of its settings
local function Section(title, ...)
    for i = 1, select("#", ...) do
        if Exists((select(i, ...))) then
            page:Header(title)
            return
        end
    end
end

local function Checkbox(label, cvar, tooltip, opts)
    if not Exists(cvar) then return end
    used[cvar] = true
    page:Checkbox(label, function() return On(cvar) end, function(value) C_CVar.SetCVar(cvar, value and "1" or "0") end,
        tooltip, opts)
end

local function Slider(label, cvar, minValue, maxValue, step, format, tooltip, opts)
    if not Exists(cvar) then return end
    used[cvar] = true
    page:Slider(label, minValue, maxValue, step, function() return GetNumber(cvar) end,
        function(value) SetNumber(cvar, value) end, format, tooltip, opts)
end

local function Dropdown(label, cvar, options, tooltip, opts)
    if not Exists(cvar) then return end
    used[cvar] = true
    page:Dropdown(label, options, function() return GetNumber(cvar) end, function(value) SetNumber(cvar, value) end,
        tooltip, opts)
end

local function Nits(value) return ("%d nits"):format(value) end
local function Times(value) return ("%.2fx"):format(value) end
local function Percent(value) return ("%d%%"):format(math.floor(value * 100 + 0.5)) end
local function Plain(value) return tostring(value) end
local function Yards(value) return ("%d yd"):format(value) end

local function OnlyWith(cvar)
    return { indent = true, enabled = function() return On(cvar) end }
end

---------------------------------------------------------------------------
-- HDR (WoW: Forever)
---------------------------------------------------------------------------
Section("HDR", "HDROutput")
Checkbox("HDR Output", "HDROutput",
    "Render in HDR. Needs Windows HDR turned on, a monitor that supports it, and Linear Lighting. If nothing changes, "
        .. "restart the game.")
Slider("Highlight Strength", "HDRFactor", 1, 5, 0.05, Times,
    "How far above normal brightness highlights (sun, fire, spell effects) can go. It's capped at your monitor's peak "
        .. "brightness.", OnlyWith("HDROutput"))
Checkbox("Set Peak Brightness", "useHDRPeakBrightness",
    "Use the peak brightness below instead of the one detected from your monitor. Helps when highlights clip or look "
        .. "dim.", OnlyWith("HDROutput"))
Slider("Peak Brightness", "HDRPeakBrightness", 300, 2000, 50, Nits,
    "Your monitor's real peak brightness, in nits.", {
        indent = 2,
        enabled = function() return On("HDROutput") and On("useHDRPeakBrightness") end,
    })
Checkbox("Set Paper White", "useHDRBrightness",
    "Use the brightness below for normal (non-highlight) content instead of the detected one. Raise it if the game "
        .. "looks dim in HDR.", OnlyWith("HDROutput"))
Slider("Paper White", "HDRBrightness", 80, 500, 1, Nits,
    "Brightness of normal content, in nits. 203 is the standard level.", {
        indent = 2,
        enabled = function() return On("HDROutput") and On("useHDRBrightness") end,
    })

---------------------------------------------------------------------------
-- Lighting
---------------------------------------------------------------------------
Section("Lighting", "linear", "bloomEnable", "specular", "maxLightDist")
Checkbox("Linear Lighting", "linear",
    "WoW: Forever's new lighting. Off is the original look. HDR and the menu's Bloom setting need it.")
Checkbox("Bloom", "bloomEnable",
    "A separate bloom switch, off by default. With Linear Lighting, bloom mostly comes from the menu's Bloom setting.")
Slider("Shine", "specular", 0, 1, 0.05, Percent,
    "How strong shine and highlights on surfaces are.")
Slider("Light Distance", "maxLightDist", 256, 2048, 128, Yards,
    "How far away lights (torches, lamps, spell lights) are drawn. The game allows up to 2048, its default, so this "
        .. "can only lower it (for performance).")

---------------------------------------------------------------------------
-- Sharpening
---------------------------------------------------------------------------
Section("Sharpening", "ResampleAlwaysSharpen", "CMAA2ExtraSharpness")
Checkbox("Always Sharpen", "ResampleAlwaysSharpen",
    "Apply the sharpening pass even when the game isn't upscaling. The menu's Sharpness setting normally only works "
        .. "with FSR upscaling.")
-- Laid out like the menu's Sharpness slider: 2.0 on the left to 0.0 on the right in steps of 0.1 (lower is sharper),
-- so the slider runs over 2 minus the setting
if Exists("ResampleSharpness") then
    used.ResampleSharpness = true
    page:Slider("Sharpness", 0, 2, 0.1,
        function() return 2 - GetNumber("ResampleSharpness") end,
        function(value) SetNumber("ResampleSharpness", math.floor((2 - value) * 10 + 0.5) / 10) end,
        function(value) return ("%.1f"):format(2 - value) end,
        "How much sharpening is applied, the same setting and layout as the menu's Sharpness: further right is "
            .. "sharper.", OnlyWith("ResampleAlwaysSharpen"))
end
Checkbox("Crisper CMAA2", "CMAA2ExtraSharpness",
    "With CMAA2 anti-aliasing, keep text and edges crisper at the cost of slightly less smoothing.")

---------------------------------------------------------------------------
-- World Detail
---------------------------------------------------------------------------
Section("World Detail", "groundEffectDensity", "weatherDensity", "doodadLodScale")
Slider("Ground Clutter Density", "groundEffectDensity", 16, 256, 8, Plain,
    "How thick grass and small ground clutter are. The menu's Ground Clutter setting changes this too.")
Slider("Ground Clutter Distance", "groundEffectDist", 40, 500, 5, Yards,
    "How far out grass and ground clutter are drawn.")
Slider("Ground Clutter Fade", "groundEffectFade", 0, 600, 10, Yards,
    "How gradually grass and ground clutter fade out toward their distance limit. Higher is a softer fade.")
Dropdown("Weather Density", "weatherDensity", {
    { label = "Off", value = 0 },
    { label = "Low", value = 1 },
    { label = "Medium", value = 2 },
    { label = "High", value = 3 },
}, "How much rain and snow falls.")
Dropdown("Cloud Detail", "SkyCloudLOD", {
    { label = "Low", value = 0 },
    { label = "Medium", value = 1 },
    { label = "High", value = 2 },
    { label = "Ultra", value = 3 },
}, "Texture resolution of the clouds in the sky.")
Slider("Object Detail Distance", "doodadLodScale", 50, 200, 5, function(v) return v .. "%" end,
    "How far out objects (trees, rocks, props) keep full detail before switching to simpler models.")
Slider("Object Fade Distance", "lodObjectFadeScale", 50, 300, 5, function(v) return v .. "%" end,
    "How far out small objects fade out.")
Checkbox("Footprints", "showfootprintparticles", "Footprint effects as you walk.")
Checkbox("Soft Edges", "DepthBasedOpacity",
    "Effects like fog and spell clouds fade softly where they meet surfaces instead of cutting off sharply.")

---------------------------------------------------------------------------
-- Distance & Detail: how far things keep full detail. The menu's View Distance and Environment Detail set several
-- of these too, so moving those later replaces them.
---------------------------------------------------------------------------
Section("Distance & Detail", "terrainLodDist", "wmoLodDist", "entityLodDist", "horizonStart", "lodObjectCullSize",
    "componentCompress")
Slider("Terrain Detail Distance", "terrainLodDist", 200, 2000, 50, Yards,
    "How far out the ground keeps full detail before switching to a simpler version.")
Slider("Building Detail Distance", "wmoLodDist", 100, 2000, 50, Yards,
    "How far out buildings keep full detail before switching to simpler models.")
Slider("Character Detail Distance", "entityLodDist", 5, 1000, 5, Yards,
    "How far out characters and creatures keep full detail before switching to simpler models.")
Slider("Distant Landscape Start", "horizonStart", 400, 24000, 200, Yards,
    "Where the low-detail distant landscape begins. Further out keeps more of the view at full detail.")
Slider("Small Object Culling", "lodObjectCullSize", 1, 30, 1, Plain,
    "How small an object can be before it's left out in the distance. Lower keeps more small objects.")
Slider("Smallest Object Size", "lodObjectMinSize", 0, 40, 1, Plain,
    "Objects smaller than this are never drawn far away. 0 draws them all.")
-- On is the setting at 0 (uncompressed), so the box is the opposite of the setting
if Exists("componentCompress") then
    used.componentCompress = true
    page:Checkbox("Full-Quality Character Textures",
        function() return not On("componentCompress") end,
        function(value) C_CVar.SetCVar("componentCompress", value and "0" or "1") end,
        "Keep character textures (armor, skin) uncompressed, for sharper detail. Uses more video memory. Shows on "
            .. "characters as they're loaded again, e.g. after a reload.")
end

---------------------------------------------------------------------------
-- Screen Effects
---------------------------------------------------------------------------
Section("Screen Effects", "ffxGlow", "ffxDeath", "ffxNether")
Checkbox("Full-Screen Glow", "ffxGlow", "The soft glow over the whole screen.")
Checkbox("Death Effect", "ffxDeath", "The screen turns gray while you're dead.")
Checkbox("Nether Effect", "ffxNether", "The full-screen nether effect some abilities and places use.")

Kit.Register(page)

-- The game or another addon can change these: keep the page showing the current values
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CVAR_UPDATE")
events:SetScript("OnEvent", function() page:Refresh() end)

SLASH_ADVANCEDGRAPHICS1 = "/advancedgraphics"
SLASH_ADVANCEDGRAPHICS2 = "/advgfx"
SlashCmdList["ADVANCEDGRAPHICS"] = function() Kit.Open(page) end
