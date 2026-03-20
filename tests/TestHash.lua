local lu = require('luaunit')

-- =============================================================================
-- Load hash.lua in test harness
-- =============================================================================
-- TestUtils.lua has already set up Core, lib, and rom mocks.
-- We load hash.lua which attaches Hash to Core.
-- hash.lua reads Core.Discovery at call time, so each test sets it via withDiscovery().

dofile("src/hash.lua")

local Hash = Core.Hash

-- =============================================================================
-- BASE62 TESTS
-- =============================================================================

TestBase62 = {}

function TestBase62:testEncodeZero()
    lu.assertEquals(Hash.EncodeBase62(0), "0")
end

function TestBase62:testEncodeSingleDigit()
    lu.assertEquals(Hash.EncodeBase62(9), "9")
    lu.assertEquals(Hash.EncodeBase62(10), "A")
    lu.assertEquals(Hash.EncodeBase62(61), "z")
end

function TestBase62:testEncodeMultiDigit()
    lu.assertEquals(Hash.EncodeBase62(62), "10")
    lu.assertEquals(Hash.EncodeBase62(124), "20")
end

function TestBase62:testRoundTrip()
    for _, n in ipairs({0, 1, 42, 61, 62, 100, 999, 123456, 1073741823}) do
        lu.assertEquals(Hash.DecodeBase62(Hash.EncodeBase62(n)), n)
    end
end

function TestBase62:testDecodeInvalidChar()
    lu.assertIsNil(Hash.DecodeBase62("!invalid"))
end

-- =============================================================================
-- HASH ROUND-TRIP: BOOL-ONLY MODULES
-- =============================================================================

-- Helper: set up Core.Discovery from a MockDiscovery, run hash functions
local function withDiscovery(discovery)
    Core.Discovery = discovery
    return Hash.GetConfigHash, Hash.ApplyConfigHash
end

TestHashBoolOnly = {}

function TestHashBoolOnly:testAllEnabled()
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true },
        { id = "B", category = "Cat1", enabled = true },
        { id = "C", category = "Cat1", enabled = true },
    })

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Flip all to false
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = false
    end

    ApplyHash(hash)

    for _, m in ipairs(discovery.modules) do
        lu.assertTrue(m.mod.config.Enabled)
    end
end

function TestHashBoolOnly:testMixedStates()
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true },
        { id = "B", category = "Cat1", enabled = false },
        { id = "C", category = "Cat2", enabled = true },
        { id = "D", category = "Cat2", enabled = false },
    })

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Flip everything
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = not m.mod.config.Enabled
    end

    ApplyHash(hash)

    lu.assertTrue(discovery.modulesById["A"].mod.config.Enabled)
    lu.assertFalse(discovery.modulesById["B"].mod.config.Enabled)
    lu.assertTrue(discovery.modulesById["C"].mod.config.Enabled)
    lu.assertFalse(discovery.modulesById["D"].mod.config.Enabled)
end

function TestHashBoolOnly:testAllDisabled()
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = false },
        { id = "B", category = "Cat1", enabled = false },
    })

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Enable all
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = true
    end

    ApplyHash(hash)

    lu.assertFalse(discovery.modulesById["A"].mod.config.Enabled)
    lu.assertFalse(discovery.modulesById["B"].mod.config.Enabled)
end

-- =============================================================================
-- HASH ROUND-TRIP: WITH INLINE OPTIONS
-- =============================================================================

TestHashWithOptions = {}

function TestHashWithOptions:testDropdownOptionRoundTrip()
    local opts = {
        { type = "dropdown", configKey = "Mode", values = {"Vanilla", "Always", "Never"}, default = "Vanilla" },
    }
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true, options = opts },
    })
    -- Set the option value on the mock config
    discovery.modules[1].mod.config.Mode = "Always"

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Reset
    discovery.modules[1].mod.config.Enabled = false
    discovery.modules[1].mod.config.Mode = "Vanilla"

    ApplyHash(hash)

    lu.assertTrue(discovery.modules[1].mod.config.Enabled)
    lu.assertEquals(discovery.modules[1].mod.config.Mode, "Always")
end

function TestHashWithOptions:testCheckboxOptionRoundTrip()
    local opts = {
        { type = "checkbox", configKey = "Strict" },
    }
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true, options = opts },
    })
    discovery.modules[1].mod.config.Strict = true

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    discovery.modules[1].mod.config.Strict = false
    ApplyHash(hash)

    lu.assertTrue(discovery.modules[1].mod.config.Strict)
end

-- =============================================================================
-- HASH ROUND-TRIP: WITH SPECIAL MODULES
-- =============================================================================

TestHashWithSpecials = {}

function TestHashWithSpecials:testSpecialSchemaRoundTrip()
    local discovery = MockDiscovery.create(
        { { id = "A", category = "Cat1", enabled = true } },
        {},
        {
            {
                modName = "adamant-Special",
                config = { Weapon = "Axe", Aspect = "Default" },
                stateSchema = {
                    { type = "dropdown", configKey = "Weapon", values = {"Axe", "Staff", "Daggers"}, default = "Axe" },
                    { type = "dropdown", configKey = "Aspect", values = {"Default", "Alpha", "Beta"}, default = "Default" },
                },
            },
        }
    )

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Reset special config
    discovery.specials[1].mod.config.Weapon = "Staff"
    discovery.specials[1].mod.config.Aspect = "Beta"

    ApplyHash(hash)

    lu.assertEquals(discovery.specials[1].mod.config.Weapon, "Axe")
    lu.assertEquals(discovery.specials[1].mod.config.Aspect, "Default")
end

-- =============================================================================
-- HASH STABILITY
-- =============================================================================

TestHashStability = {}

function TestHashStability:testSameConfigProducesSameHash()
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true },
        { id = "B", category = "Cat1", enabled = false },
        { id = "C", category = "Cat2", enabled = true },
    })

    local GetHash = withDiscovery(discovery)
    local hash1 = GetHash()
    local hash2 = GetHash()

    lu.assertEquals(hash1, hash2)
end

function TestHashStability:testDifferentConfigProducesDifferentHash()
    local discovery = MockDiscovery.create({
        { id = "A", category = "Cat1", enabled = true },
        { id = "B", category = "Cat1", enabled = false },
    })

    local GetHash = withDiscovery(discovery)
    local hash1 = GetHash()

    discovery.modules[2].mod.config.Enabled = true
    local hash2 = GetHash()

    lu.assertNotEquals(hash1, hash2)
end

-- =============================================================================
-- CHUNK BOUNDARY (30-bit boundary)
-- =============================================================================

TestHashChunkBoundary = {}

-- Helper: create N modules with a given enabled pattern
local function createModules(n, enabledFn)
    local modules = {}
    for i = 1, n do
        table.insert(modules, {
            id = "M" .. i,
            category = "Cat" .. math.ceil(i / 10),
            enabled = enabledFn(i),
        })
    end
    return modules
end

function TestHashChunkBoundary:testExactly30Modules()
    -- 30 bools = exactly one full chunk, no overflow
    local modules = createModules(30, function(i) return i % 2 == 1 end)
    local discovery = MockDiscovery.create(modules)
    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Flip all
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = not m.mod.config.Enabled
    end

    ApplyHash(hash)

    for i, m in ipairs(discovery.modules) do
        if i % 2 == 1 then
            lu.assertTrue(m.mod.config.Enabled, "Module " .. m.id .. " should be enabled")
        else
            lu.assertFalse(m.mod.config.Enabled, "Module " .. m.id .. " should be disabled")
        end
    end
end

function TestHashChunkBoundary:test31ModulesCrossesBoundary()
    -- 31 bools = one full 30-bit chunk + 1 bit in second chunk
    local modules = createModules(31, function(i) return i % 3 == 0 end)
    local discovery = MockDiscovery.create(modules)
    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Hash should contain a dot (two chunks)
    lu.assertStrContains(hash, ".")

    -- Flip all and restore
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = not m.mod.config.Enabled
    end

    ApplyHash(hash)

    for i, m in ipairs(discovery.modules) do
        if i % 3 == 0 then
            lu.assertTrue(m.mod.config.Enabled, "Module " .. m.id .. " should be enabled")
        else
            lu.assertFalse(m.mod.config.Enabled, "Module " .. m.id .. " should be disabled")
        end
    end
end

function TestHashChunkBoundary:test60ModulesTwoFullChunks()
    -- 60 bools = exactly two full 30-bit chunks
    local modules = createModules(60, function(i) return i <= 30 end)
    local discovery = MockDiscovery.create(modules)
    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Flip all
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = not m.mod.config.Enabled
    end

    ApplyHash(hash)

    for i, m in ipairs(discovery.modules) do
        if i <= 30 then
            lu.assertTrue(m.mod.config.Enabled, "Module " .. m.id .. " should be enabled")
        else
            lu.assertFalse(m.mod.config.Enabled, "Module " .. m.id .. " should be disabled")
        end
    end
end

function TestHashChunkBoundary:testAllEnabledAcrossBoundary()
    -- 35 modules all enabled — verifies no data loss at boundary
    local modules = createModules(35, function() return true end)
    local discovery = MockDiscovery.create(modules)
    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = false
    end

    ApplyHash(hash)

    for _, m in ipairs(discovery.modules) do
        lu.assertTrue(m.mod.config.Enabled, "Module " .. m.id .. " should be enabled")
    end
end

function TestHashChunkBoundary:testOptionsAfterChunkBoundary()
    -- 31 bool modules + a module with a dropdown option
    -- Tests that options decode correctly after a multi-chunk bool section
    local modules = createModules(31, function(i) return i % 2 == 0 end)
    local opts = {
        { type = "dropdown", configKey = "Style", values = {"A", "B", "C", "D"}, default = "A" },
    }
    table.insert(modules, {
        id = "WithOpt", category = "Cat4", enabled = true, options = opts,
    })

    local discovery = MockDiscovery.create(modules)
    discovery.modules[32].mod.config.Style = "C"

    local GetHash, ApplyHash = withDiscovery(discovery)
    local hash = GetHash()

    -- Reset everything
    for _, m in ipairs(discovery.modules) do
        m.mod.config.Enabled = not m.mod.config.Enabled
    end
    discovery.modules[32].mod.config.Style = "A"

    ApplyHash(hash)

    -- Verify bools restored
    for i = 1, 31 do
        local m = discovery.modules[i]
        if i % 2 == 0 then
            lu.assertTrue(m.mod.config.Enabled, "Module " .. m.id .. " should be enabled")
        else
            lu.assertFalse(m.mod.config.Enabled, "Module " .. m.id .. " should be disabled")
        end
    end
    -- Verify option restored
    lu.assertTrue(discovery.modules[32].mod.config.Enabled)
    lu.assertEquals(discovery.modules[32].mod.config.Style, "C")
end

-- =============================================================================
-- ERROR HANDLING
-- =============================================================================

TestHashErrors = {}

function TestHashErrors:testEmptyHash()
    local discovery = MockDiscovery.create({})
    withDiscovery(discovery)
    lu.assertFalse(Hash.ApplyConfigHash(""))
    lu.assertFalse(Hash.ApplyConfigHash(nil))
end

function TestHashErrors:testInvalidBase62()
    local discovery = MockDiscovery.create({})
    withDiscovery(discovery)
    lu.assertFalse(Hash.ApplyConfigHash("!!!"))
end
