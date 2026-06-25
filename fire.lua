--[[
    fireremote.lua — LuaU VM remote firing (Matcha / memory API)

    Offsets: version-1a951716f19e4638
    https://offsets.imtheo.lol/version-1a951716f19e4638/offsets.txt

    Matcha note: RemoteEvent:FireServer is nil in the external VM.
    This module validates remotes via memory, then fires through the first
    available backend (native FireServer, executor hook, or run_secure bridge).
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OFFSETS_URL = "https://offsets.imtheo.lol/version-1a951716f19e4638/offsets.txt"

-- Embedded fallback (same version as URL above)
local OFFSETS = {
    FakeDataModelPointer = 0x7be9278,
    RealDataModel = 0x1d0,
    ScriptContext = 0x440,
    Workspace = 0x178,
    StringLength = 0x10,
    Value = 0xd0,
    Instance = {
        ClassDescriptor = 0x18,
        ClassName = 0x8,
        Name = 0xb0,
        Parent = 0x70,
        ChildrenStart = 0x78,
        ChildNode = 0x8,
    },
}

local memRead = memory_read or (memory and memory.read) or (memory and memory.Read)
local memWrite = memory_write or (memory and memory.write) or (memory and memory.Write)
local memBase = getbase or (memory and memory.GetBase) or (memory and memory.Rebase and function(off)
    return memory.Rebase(off)
end)

local function hasMemoryApi()
    return type(memRead) == "function" and type(memBase) == "function"
end

local function parseOffsetLine(line)
    local key, hex = line:match("^([^=]+)=%s*(0x%x+)")
    if not key or not hex then
        return nil
    end
    return key:gsub("%s+$", ""), tonumber(hex)
end

local function applyOffsetLine(key, value)
    if key == "FakeDataModel::Pointer" then
        OFFSETS.FakeDataModelPointer = value
    elseif key == "FakeDataModel::RealDataModel" then
        OFFSETS.RealDataModel = value
    elseif key == "DataModel::ScriptContext" then
        OFFSETS.ScriptContext = value
    elseif key == "DataModel::Workspace" then
        OFFSETS.Workspace = value
    elseif key == "Misc::StringLength" then
        OFFSETS.StringLength = value
    elseif key == "Misc::Value" then
        OFFSETS.Value = value
    elseif key == "Instance::ClassDescriptor" then
        OFFSETS.Instance.ClassDescriptor = value
    elseif key == "Instance::ClassName" then
        OFFSETS.Instance.ClassName = value
    elseif key == "Instance::Name" then
        OFFSETS.Instance.Name = value
    elseif key == "Instance::Parent" then
        OFFSETS.Instance.Parent = value
    elseif key == "Instance::ChildrenStart" then
        OFFSETS.Instance.ChildrenStart = value
    end
end

local function loadOffsetsFromText(text)
    if type(text) ~= "string" then
        return false
    end
    for line in text:gmatch("[^\r\n]+") do
        local key, value = parseOffsetLine(line)
        if key and value then
            applyOffsetLine(key, value)
        end
    end
    return true
end

local function refreshOffsets()
    local ok, body = pcall(function()
        if syn and syn.request then
            return syn.request({ Url = OFFSETS_URL, Method = "GET" }).Body
        end
        return game:HttpGet(OFFSETS_URL)
    end)
    if ok and body then
        loadOffsetsFromText(body)
    end
end

refreshOffsets()

local function validAddr(addr)
    addr = tonumber(addr)
    return addr and addr > 4096
end

local function readPtr(addr)
    if not validAddr(addr) then
        return nil
    end
    local ok, value = pcall(memRead, "uintptr_t", addr)
    if ok and validAddr(value) then
        return value
    end
    ok, value = pcall(memRead, "uintptr", addr)
    if ok and validAddr(value) then
        return value
    end
    return nil
end

local function readRobloxString(addr)
    if not validAddr(addr) then
        return nil
    end
    local ok, inline = pcall(memRead, "string", addr)
    if ok and type(inline) == "string" and inline ~= "" then
        return inline
    end
    local strPtr = readPtr(addr)
    if strPtr then
        ok, inline = pcall(memRead, "string", strPtr)
        if ok and type(inline) == "string" then
            return inline
        end
    end
    return nil
end

local function readInstanceName(addr)
    return readRobloxString(addr + OFFSETS.Instance.Name)
end

local function readInstanceClassName(addr)
    local descriptor = readPtr(addr + OFFSETS.Instance.ClassDescriptor)
    if not descriptor then
        return nil
    end
    return readRobloxString(descriptor + OFFSETS.Instance.ClassName)
end

local function getBaseAddress()
    if not hasMemoryApi() then
        return nil
    end
    local ok, base = pcall(memBase)
    if ok and validAddr(base) then
        return base
    end
    return nil
end

local function getDataModelAddress()
    local base = getBaseAddress()
    if not base then
        return nil
    end
    local fake = readPtr(base + OFFSETS.FakeDataModelPointer)
    if not fake then
        return nil
    end
    return readPtr(fake + OFFSETS.RealDataModel)
end

local function getScriptContextAddress()
    local dataModel = getDataModelAddress()
    if not dataModel then
        return nil
    end
    return readPtr(dataModel + OFFSETS.ScriptContext)
end

local function memoryFindFirstChild(parentAddr, childName)
    if not validAddr(parentAddr) or type(childName) ~= "string" then
        return nil
    end
    local startNode = readPtr(parentAddr + OFFSETS.Instance.ChildrenStart)
    if not startNode then
        return nil
    end
    local node = readPtr(startNode)
    local guard = 0
    while validAddr(node) and guard < 8192 do
        guard = guard + 1
        local instance = readPtr(node + OFFSETS.Instance.ChildNode)
        if validAddr(instance) then
            local name = readInstanceName(instance)
            if name == childName then
                return instance
            end
        end
        node = readPtr(node)
        if not validAddr(node) or node == startNode then
            break
        end
    end
    return nil
end

local function memoryFindByPath(rootAddr, pathParts)
    local current = rootAddr
    for _, part in ipairs(pathParts) do
        current = memoryFindFirstChild(current, part)
        if not current then
            return nil
        end
    end
    return current
end

local REMOTE_CLASSES = {
    RemoteEvent = true,
    UnreliableRemoteEvent = true,
}

local function isRemoteInstance(remote)
    if typeof(remote) ~= "Instance" then
        return false, "expected Instance, got " .. typeof(remote)
    end
    local ok, className = pcall(function()
        return remote.ClassName
    end)
    if ok and REMOTE_CLASSES[className] then
        return true
    end
    local addr = tonumber(remote.Address)
    if validAddr(addr) and hasMemoryApi() then
        local memClass = readInstanceClassName(addr)
        if memClass and REMOTE_CLASSES[memClass] then
            return true
        end
        if memClass then
            return false, "expected RemoteEvent, got " .. memClass
        end
    end
    if ok and className then
        return false, "expected RemoteEvent, got " .. tostring(className)
    end
    return false, "could not verify RemoteEvent class"
end

local function serializeArg(arg)
    local t = typeof(arg)
    if t == "string" or t == "number" or t == "boolean" then
        return t, arg
    end
    if t == "EnumItem" then
        return "string", tostring(arg)
    end
    return nil, nil
end

local function buildFireSource(remotePath, packedArgs)
    local chunks = { "local r = game" }
    for part in string.gmatch(remotePath, "[^%.]+") do
        table.insert(chunks, ":WaitForChild(" .. HttpService:JSONEncode(part) .. ")")
    end
    table.insert(chunks, "\nr:FireServer(")
    local argChunks = {}
    for _, entry in ipairs(packedArgs) do
        local kind, value = entry[1], entry[2]
        if kind == "string" then
            table.insert(argChunks, HttpService:JSONEncode(value))
        elseif kind == "number" then
            table.insert(argChunks, tostring(value))
        elseif kind == "boolean" then
            table.insert(argChunks, value and "true" or "false")
        end
    end
    table.insert(chunks, table.concat(argChunks, ", "))
    table.insert(chunks, ")\n")
    return table.concat(chunks)
end

local function tryDirectFire(remote, args)
    local fire = remote.FireServer
    if type(fire) ~= "function" then
        return false, "FireServer unavailable in this VM"
    end
    local ok, err = pcall(fire, remote, table.unpack(args))
    if ok then
        return true
    end
    return false, tostring(err)
end

local function getCompiler()
    return rawget(_G, "compile")
        or rawget(_G, "luau_compile")
        or rawget(_G, "Compile")
        or rawget(_G, "__fireremote_compile")
end

local function tryExecutorHooks(remote, args)
    local hooks = {
        rawget(_G, "fireremote_native"),
        rawget(_G, "FireServer"),
        firesignal,
    }
    for _, hook in ipairs(hooks) do
        if type(hook) == "function" then
            local ok, err = pcall(hook, remote, table.unpack(args))
            if ok then
                return true
            end
        end
    end
    return false, "no executor fire hook found"
end

local function tryRunSecure(remote, args)
    if type(run_secure) ~= "function" or type(base64encode) ~= "function" then
        return false, "run_secure/base64encode unavailable"
    end

    local compile = getCompiler()
    if type(compile) ~= "function" then
        return false, "no Luau compiler (_G.compile / _G.__fireremote_compile) for run_secure"
    end

    local okPath, remotePath = pcall(function()
        return remote:GetFullName()
    end)
    if not okPath or type(remotePath) ~= "string" or remotePath == "" then
        return false, "could not resolve remote path"
    end

    remotePath = remotePath:gsub("^game%.", "")

    local packed = {}
    for i = 1, #args do
        local kind, value = serializeArg(args[i])
        if not kind then
            return false, ("unsupported arg #%d (%s)"):format(i, typeof(args[i]))
        end
        packed[#packed + 1] = { kind, value }
    end

    local source = buildFireSource(remotePath, packed)
    local okCompile, bytecode = pcall(compile, source)
    if not okCompile or type(bytecode) ~= "string" or #bytecode == 0 then
        return false, "compile failed: " .. tostring(bytecode)
    end

    local okRun, err = pcall(run_secure, base64encode(bytecode))
    if okRun then
        return true
    end
    return false, tostring(err)
end

local function tryMemoryInvoke(remote, args)
    if not hasMemoryApi() then
        return false, "memory api unavailable"
    end

    local invoke = rawget(_G, "invoke") or rawget(_G, "call") or rawget(_G, "rbx_call")
    if type(invoke) ~= "function" then
        return false, "no native invoke() for memory fire"
    end

    local addr = tonumber(remote.Address)
    if not validAddr(addr) then
        return false, "remote.Address missing"
    end

    local packed = { addr, "FireServer" }
    for i = 1, #args do
        packed[#packed + 1] = args[i]
    end

    local ok, err = pcall(invoke, table.unpack(packed))
    if ok then
        return true
    end
    return false, tostring(err)
end

local function fireremote(remote, ...)
    local args = { ... }
    local okRemote, remoteErr = isRemoteInstance(remote)
    if not okRemote then
        error("fireremote: " .. tostring(remoteErr), 2)
    end

    local backends = {
        tryDirectFire,
        tryExecutorHooks,
        tryRunSecure,
        tryMemoryInvoke,
    }

    local errors = {}
    for _, backend in ipairs(backends) do
        local ok, err = backend(remote, args)
        if ok then
            return true
        end
        errors[#errors + 1] = err
    end

    error("fireremote: all backends failed\n- " .. table.concat(errors, "\n- "), 2)
end

local function getRemoteByName(service, remoteName)
    if typeof(service) ~= "Instance" then
        return nil
    end
    local remote = service:FindFirstChild(remoteName)
    if remote then
        return remote
    end
    if not hasMemoryApi() then
        return nil
    end
    local addr = tonumber(service.Address)
    if not validAddr(addr) then
        return nil
    end
    local childAddr = memoryFindFirstChild(addr, remoteName)
    if not childAddr then
        return nil
    end
    for _, inst in ipairs(service:GetChildren()) do
        if tonumber(inst.Address) == childAddr then
            return inst
        end
    end
    return nil
end

local function spawnVehicle()
    local remote = getRemoteByName(ReplicatedStorage, "GarageSpawnVehicle")
    if not remote then
        warn("fireremote: GarageSpawnVehicle not found")
        return false
    end
    local okRemote = isRemoteInstance(remote)
    if not okRemote then
        warn("fireremote: GarageSpawnVehicle is not a RemoteEvent")
        return false
    end
    fireremote(remote, "Chassis", "Camaro")
    return true
end

local function registerCompiler(fn)
    if type(fn) ~= "function" then
        error("registerCompiler expected function", 2)
    end
    _G.__fireremote_compile = fn
end

local FireRemote = {
    fire = fireremote,
    fireremote = fireremote,
    spawnVehicle = spawnVehicle,
    registerCompiler = registerCompiler,
    offsets = OFFSETS,
    refreshOffsets = refreshOffsets,
    getDataModelAddress = getDataModelAddress,
    getScriptContextAddress = getScriptContextAddress,
    memoryFindFirstChild = memoryFindFirstChild,
    memoryFindByPath = memoryFindByPath,
    readInstanceClassName = readInstanceClassName,
    readInstanceName = readInstanceName,
    getRemoteByName = getRemoteByName,
    buildFireSource = buildFireSource,
}

_G.fireremote = fireremote
_G.FireRemote = FireRemote

return FireRemote
