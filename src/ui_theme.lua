-- =============================================================================
-- UI THEME & LAYOUT CONSTANTS
-- =============================================================================
-- Purely declarative — no runtime dependencies.
-- Imported by ui.lua via `import 'ui_theme.lua'`.

local ui = rom.ImGui
local uiCol = rom.ImGuiCol

-- =============================================================================
-- COLORS
-- =============================================================================

local colors = {
    text          = {0.92, 0.90, 0.95, 1.0},
    textDisabled  = {0.45, 0.40, 0.55, 1.0},
    info          = {0.90, 0.75, 0.20, 1.0},
    warning       = {0.85, 0.20, 0.25, 1.0},
    success       = {0.30, 0.85, 0.55, 1.0},
    error         = {0.90, 0.35, 0.50, 1.0},
    mixed         = {0.30, 0.70, 0.90, 1.0},

    windowBg      = {0.08, 0.06, 0.12, 0.95},
    childBg       = {0.10, 0.08, 0.15, 0.90},
    header        = {0.28, 0.18, 0.45, 1.0},
    headerHover   = {0.38, 0.25, 0.58, 1.0},
    headerActive  = {0.45, 0.30, 0.65, 1.0},
    button        = {0.30, 0.20, 0.48, 1.0},
    buttonHover   = {0.40, 0.28, 0.60, 1.0},
    buttonActive  = {0.50, 0.35, 0.70, 1.0},
    frameBg       = {0.14, 0.10, 0.22, 1.0},
    frameBgHover  = {0.20, 0.15, 0.30, 1.0},
    frameBgActive = {0.25, 0.18, 0.38, 1.0},
    checkMark     = {0.75, 0.55, 1.00, 1.0},
    tab           = {0.18, 0.12, 0.28, 1.0},
    tabHover      = {0.35, 0.22, 0.52, 1.0},
    tabActive     = {0.40, 0.28, 0.60, 1.0},
    separator     = {0.30, 0.20, 0.45, 0.6},
    border        = {0.25, 0.18, 0.38, 0.5},
}

-- =============================================================================
-- IMGUI FLAG CONSTANTS
-- =============================================================================

local ImGuiTreeNodeFlags = {
    DefaultOpen = 32,
}

-- =============================================================================
-- LAYOUT PROPORTIONS
-- =============================================================================

local SIDEBAR_RATIO = 0.2    -- sidebar takes 20% of window
local FIELD_MEDIUM  = 0.5    -- combos, hash inputs
local FIELD_NARROW  = 0.3    -- short inputs (name, slot selector)
local FIELD_WIDE    = 0.85   -- long text (tooltip)
local LABEL_OFFSET  = 0.25   -- hammer label alignment

-- =============================================================================
-- THEME HELPERS
-- =============================================================================

local function DrawColoredText(color, text)
    ui.TextColored(color[1], color[2], color[3], color[4], text)
end

local function PushTextColor(color)
    ui.PushStyleColor(uiCol.Text, color[1], color[2], color[3], color[4])
end

local THEME_COLOR_COUNT = 20
local function PushTheme()
    local push = ui.PushStyleColor
    push(uiCol.Text,            table.unpack(colors.text))
    push(uiCol.TextDisabled,    table.unpack(colors.textDisabled))
    push(uiCol.WindowBg,        table.unpack(colors.windowBg))
    push(uiCol.ChildBg,         table.unpack(colors.childBg))
    push(uiCol.Header,          table.unpack(colors.header))
    push(uiCol.HeaderHovered,   table.unpack(colors.headerHover))
    push(uiCol.HeaderActive,    table.unpack(colors.headerActive))
    push(uiCol.Button,          table.unpack(colors.button))
    push(uiCol.ButtonHovered,   table.unpack(colors.buttonHover))
    push(uiCol.ButtonActive,    table.unpack(colors.buttonActive))
    push(uiCol.FrameBg,         table.unpack(colors.frameBg))
    push(uiCol.FrameBgHovered,  table.unpack(colors.frameBgHover))
    push(uiCol.FrameBgActive,   table.unpack(colors.frameBgActive))
    push(uiCol.CheckMark,       table.unpack(colors.checkMark))
    push(uiCol.Tab,             table.unpack(colors.tab))
    push(uiCol.TabHovered,      table.unpack(colors.tabHover))
    push(uiCol.TabActive,       table.unpack(colors.tabActive))
    push(uiCol.Separator,       table.unpack(colors.separator))
    push(uiCol.Border,          table.unpack(colors.border))
    push(uiCol.TitleBgActive,   table.unpack(colors.header))
end

local function PopTheme()
    ui.PopStyleColor(THEME_COLOR_COUNT)
end

-- =============================================================================
-- EXPORT TO CORE
-- =============================================================================

Core.Theme = {
    colors            = colors,
    ImGuiTreeNodeFlags = ImGuiTreeNodeFlags,
    SIDEBAR_RATIO     = SIDEBAR_RATIO,
    FIELD_MEDIUM      = FIELD_MEDIUM,
    FIELD_NARROW      = FIELD_NARROW,
    FIELD_WIDE        = FIELD_WIDE,
    LABEL_OFFSET      = LABEL_OFFSET,
    DrawColoredText   = DrawColoredText,
    PushTextColor     = PushTextColor,
    PushTheme         = PushTheme,
    PopTheme          = PopTheme,
}
