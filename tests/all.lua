-- =============================================================================
-- Run all Core tests
-- =============================================================================
-- Usage: lua tests/all.lua (from the adamant-modpack-Core directory)

require('tests/TestUtils')
require('tests/TestHash')

local lu = require('luaunit')
os.exit(lu.LuaUnit.run())
