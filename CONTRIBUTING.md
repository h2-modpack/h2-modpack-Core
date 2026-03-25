# Contributing to adamant-Modpack_Core

Thin coordinator for the adamant H2 modpack. Owns pack identity, config, and default profiles — delegates all orchestration to `adamant-Modpack_Framework`.

## Architecture

```
src/
  main.lua    -- ENVY wiring, config, def, Framework.init call
config.lua    -- Chalk config schema (ModEnabled, DebugMode, Profiles)
```

Core has no other source files. All discovery, hashing, HUD, and UI logic lives in [adamant-Modpack_Framework](https://github.com/h2-modpack/adamant-modpack-Framework). See its [CONTRIBUTING.md](https://github.com/h2-modpack/adamant-modpack-Framework/blob/main/CONTRIBUTING.md) for architecture, key systems, and guidelines.

## What Core owns

**`packId`** — `"h2-modpack"`. This is the discovery filter: only modules with `definition.modpack = "h2-modpack"` are picked up.

**`windowTitle`** — `"Speedrun Modpack"`. Displayed as the ImGui window title.

**`def.defaultProfiles`** — The three shipped presets (AnyFear, HighFear, RTA). To add or update a preset, edit `def` in `src/main.lua`. Get the hash string from the Profiles tab export field in-game.

**`config.lua`** — Chalk schema: `ModEnabled`, `DebugMode`, `Profiles` array. The Profiles array length determines `def.NUM_PROFILES` and must match the number of slots rendered in the UI.

## No tests

Tests live in `adamant-Modpack_Framework`. Run them from there:

```
cd adamant-modpack-Framework
lua5.1 tests/all.lua
```
