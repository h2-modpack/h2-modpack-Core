-- =============================================================================
-- ADAMANT-COORDINATOR: Modpack Coordinator
-- =============================================================================
-- Thin coordinator: wires globals, owns config and def, delegates everything
-- else to adamant-ModpackFramework.

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk   = mods['SGG_Modding-Chalk']
reload  = mods['SGG_Modding-ReLoad']

config = chalk.auto('config.lua')
public.config = config

local def = {
    NUM_PROFILES    = #config.Profiles,
    defaultProfiles = {
        { Name = "AnyFear",  Hash = "1AfB0V.3", Tooltip = "RTA Disabled. Arachne Pity Disabled" },
        { Name = "HighFear", Hash = "1AfB0t.3", Tooltip = "RTA Disabled. Arachne Spawn Forced" },
        { Name = "RTA",      Hash = "1AfB20.3", Tooltip = "RTA Enabled. Arachne Pity Enabled. Medea/Arachne Spawns Not Forced" },
    },
}

local PACK_ID = "showcase"

local function init()
    local Framework = mods['adamant-ModpackFramework']
    Framework.init({
        packId      = PACK_ID,
        windowTitle = "Showcase Modpack",
        config      = config,
        def         = def,
        modutil     = modutil,
    })
end

local loader = reload.auto_single()
modutil.once_loaded.game(function()
    local Framework = mods['adamant-ModpackFramework']
    rom.gui.add_imgui(Framework.getRenderer(PACK_ID))
    rom.gui.add_to_menu_bar(Framework.getMenuBar(PACK_ID))
    loader.load(init, init)
end)
