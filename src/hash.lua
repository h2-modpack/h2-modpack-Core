-- =============================================================================
-- CONFIG HASH: Encoding / Decoding
-- =============================================================================
-- Pure hash logic — no engine dependencies. Testable in standalone Lua.
-- Depends on: Core.Discovery (module ordering), lib (field encode/decode)

local lib = rom.mods['adamant-Modpack_Lib']

local Hash = {}

local BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local CHUNK_BITS = 30

-- =============================================================================
-- BASE62 ENCODING / DECODING
-- =============================================================================

function Hash.EncodeBase62(n)
    if n == 0 then return "0" end
    local result = ""
    while n > 0 do
        local idx = (n % 62) + 1
        result = string.sub(BASE62, idx, idx) .. result
        n = math.floor(n / 62)
    end
    return result
end

function Hash.DecodeBase62(str)
    local n = 0
    for i = 1, #str do
        local c = string.sub(str, i, i)
        local idx = string.find(BASE62, c, 1, true)
        if not idx then return nil end
        n = n * 62 + (idx - 1)
    end
    return n
end

local function PackChunks(chunks, chunk, bit)
    if bit > 0 then table.insert(chunks, chunk) end
    local parts = {}
    for _, c in ipairs(chunks) do
        table.insert(parts, Hash.EncodeBase62(c))
    end
    if #parts == 0 then return "0" end
    return table.concat(parts, ".")
end

-- =============================================================================
-- CONFIG HASH (driven by discovery order)
-- =============================================================================

--- Compute config hash from a staging table or from live module configs.
--- @param source table|nil If provided, reads source.modules[id] for bools. Otherwise reads Chalk configs.
--- @return string fullHash, string boolHash
function Hash.GetConfigHash(source)
    local chunks = {}
    local chunk = 0
    local bit = 0

    local function addBits(value, numBits)
        for b = 0, numBits - 1 do
            if math.floor(value / (2 ^ b)) % 2 == 1 then
                chunk = chunk + (2 ^ bit)
            end
            bit = bit + 1
            if bit >= CHUNK_BITS then
                table.insert(chunks, chunk)
                chunk = 0
                bit = 0
            end
        end
    end

    -- Boolean flags in MODULE_ORDER (registry order determines bit positions)
    for _, m in ipairs(Core.Discovery.modules) do
        local enabled
        if source then
            enabled = source.modules and source.modules[m.id]
        else
            enabled = Core.Discovery.isModuleEnabled(m)
        end
        addBits(enabled and 1 or 0, 1)
    end

    -- Flush partial bool chunk
    if bit > 0 then
        table.insert(chunks, chunk)
        chunk = 0
        bit = 0
    end
    local boolHash = PackChunks(chunks, 0, 0)

    -- Inline option payloads (in discovery order, only modules with options)
    for _, m in ipairs(Core.Discovery.modulesWithOptions) do
        for _, opt in ipairs(m.options) do
            local current
            if source then
                current = source.options and source.options[m.id]
                    and source.options[m.id][opt.configKey]
            end
            if current == nil then
                current = Core.Discovery.getOptionValue(m, opt.configKey)
            end
            lib.encodeField(opt, current, addBits)
        end
    end

    -- Special module payloads (in discovery order, driven by stateSchema)
    for _, special in ipairs(Core.Discovery.specials) do
        local schema = special.stateSchema
        if schema then
            local cfg = special.mod.config
            for _, field in ipairs(schema) do
                local current = lib.readPath(cfg, field.configKey)
                lib.encodeField(field, current, addBits)
            end
        end
    end

    local fullHash = PackChunks(chunks, chunk, bit)
    return fullHash, boolHash
end

--- Apply a config hash directly to module configs (Chalk).
--- @param hash string The hash to decode
--- @return boolean success
function Hash.ApplyConfigHash(hash)
    if not hash or hash == "" then
        lib.warn("ApplyConfigHash: empty or nil hash")
        return false
    end

    local chunksList = {}
    for part in string.gmatch(hash, "[^%.]+") do
        local decoded = Hash.DecodeBase62(part)
        if not decoded then
            lib.warn("ApplyConfigHash: invalid base62 chunk '" .. part .. "'")
            return false
        end
        table.insert(chunksList, decoded)
    end
    if #chunksList == 0 then
        lib.warn("ApplyConfigHash: no chunks decoded")
        return false
    end

    local chunkIdx = 1
    local chunkVal = chunksList[1]
    local bit = 0

    local function readBits(numBits)
        local val = 0
        for b = 0, numBits - 1 do
            if chunkIdx <= #chunksList then
                if math.floor(chunkVal / (2 ^ bit)) % 2 == 1 then
                    val = val + (2 ^ b)
                end
                bit = bit + 1
                if bit >= CHUNK_BITS then
                    chunkIdx = chunkIdx + 1
                    chunkVal = chunksList[chunkIdx] or 0
                    bit = 0
                end
            end
        end
        return val
    end

    -- Boolean flags in MODULE_ORDER — write directly to module configs
    for _, m in ipairs(Core.Discovery.modules) do
        local enabled = readBits(1) == 1
        Core.Discovery.setModuleEnabled(m, enabled)
    end

    -- Skip remaining bits in last bool chunk
    if bit > 0 then
        chunkIdx = chunkIdx + 1
        chunkVal = chunksList[chunkIdx] or 0
        bit = 0
    end

    -- Inline option payloads (in discovery order, only modules with options)
    if chunkIdx <= #chunksList then
        for _, m in ipairs(Core.Discovery.modulesWithOptions) do
            for _, opt in ipairs(m.options) do
                local val = lib.decodeField(opt, readBits)
                if val ~= nil then
                    Core.Discovery.setOptionValue(m, opt.configKey, val)
                end
            end
        end
    end

    -- Special module payloads (in discovery order, driven by stateSchema)
    if chunkIdx <= #chunksList then
        for _, special in ipairs(Core.Discovery.specials) do
            local schema = special.stateSchema
            if schema then
                local cfg = special.mod.config
                for _, field in ipairs(schema) do
                    local val = lib.decodeField(field, readBits)
                    if val ~= nil then
                        lib.writePath(cfg, field.configKey, val)
                    end
                end
                if special.mod.SnapshotStaging then
                    special.mod.SnapshotStaging()
                end
            end
        end
    end

    return true
end

Core.Hash = Hash
