-- =============================================================================
-- STRICT APPEND-ONLY REGISTRY
-- =============================================================================
-- New modules MUST be added to the bottom of their respective lists.
-- DO NOT reorder or delete existing entries.
--
-- This registry exists solely to guarantee hash-stable module ordering.
-- Category, group, and display metadata live in each module's public.definition.

local MODULE_ORDER = {
    -- Run Modifiers
    "adamant-ForceMedea",
    "adamant-ForceArachne",
    "adamant-DisableArachnePity",
    "adamant-PreventEchoScam",
    "adamant-DisableSeleneBeforeBoon",
    "adamant-RTAMode",
    "adamant-SkipGemBossReward",
    "adamant-EscalatingFigLeaf",
    "adamant-SurfaceStructure",
    "adamant-CharybdisBehavior",

    -- QoL
    "adamant-ShowLocation",
    "adamant-SkipDialogue",
    "adamant-SkipRunEndCutscene",
    "adamant-SkipDeathCutscene",
    "adamant-SpawnLocation",
    "adamant-KBMEscape",
    "adamant-VictoryScreen",
    "adamant-SpeedrunTimer",

    -- Bug Fixes
    "adamant-CorrosionFix",
    "adamant-GGGFix",
    "adamant-BraidFix",
    "adamant-MiniBossEncounterFix",
    "adamant-ExtraDoseFix",
    "adamant-PoseidonWavesFix",
    "adamant-TidalRingFix",
    "adamant-ShimmeringFix",
    "adamant-StagedOmegaFix",
    "adamant-OmegaCastFix",
    "adamant-CardioTorchFix",
    "adamant-FamiliarDelayFix",
    "adamant-SufferingFix",
    "adamant-SeleneFix",
    "adamant-ETFix",
    "adamant-SecondStageChanneling",
}

local SPECIAL_MODULES = {
    -- Append only, never reorder — hash payload order depends on this.
    "adamant-FirstHammer",
}

Core.MODULE_ORDER = MODULE_ORDER
Core.SPECIAL_MODULES = SPECIAL_MODULES