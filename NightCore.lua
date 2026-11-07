-- Builders combine plain fields into fresh tables; inputs are not modified.
-- Nested values are shared and treated as read-only.
NightCore = {
    Version = "0.1.0-dev",

    SpeedMods = {
        Type = {
            X = "x-mod",
            C = "c-mod",
            M = "m-mod",
        },

        RowType = {
            Basic = "basic",
            Advanced = "advanced",
            Pro = "pro",
        },
    },

    addField = function(name, value)
        return { [name] = value }
    end,

    build = function(tree, fields)
        for _, field in ipairs(fields) do
            local nextTree = {}
            for name, value in pairs(tree) do
                nextTree[name] = value
            end
            for name, value in pairs(field) do
                nextTree[name] = value
            end
            tree = nextTree
        end
        return tree
    end,

    group = function(name, fields)
        return NightCore.addField(name, NightCore.build({}, fields))
    end,

    enum = function(values)
        return NightCore.build({}, { values })
    end,

    -- Capture subsequent module scripts and return a function to build their tree.
    -- Each module needs a unique NN.NN prefix; dots in its filename form namespaces.
    bootstrap = function()
        Trace("[NightCore] Bootstrapping " .. NightCore.Version .. " (" .. _VERSION .. ")")

        local globals = _G
        local modules = {}
        local moduleTree = {}

        local function addModule(tree, path, values)
            local _, _, name, rest = string.find(path, "^([%w_]+)%.(.+)$")
            if name then
                local branch = tree[name] or {}
                assert(type(branch) == "table" and getmetatable(branch) == nil,
                    "Module namespace already defined: " .. path)
                values = addModule(branch, rest, values)
            else
                assert(string.find(path, "^[%w_]+$"), "Invalid module name: " .. path)
                name = path
                assert(tree[name] == nil, "Duplicate module: " .. path)
            end
            return NightCore.build(tree, {
                NightCore.addField(name, values),
            })
        end

        local function lookup(_, name)
            if moduleTree[name] ~= nil then
                return moduleTree[name]
            end
            return globals[name]
        end

        local moduleEnvironment = setmetatable({
            -- Lua 5.0's pairs/ipairs read these directly from the thread environment.
            next = globals.next,
            ipairs = globals.ipairs,
        }, {
            __index = lookup,
            __newindex = function(_, name, value)
                -- Lua 5.0 exposes the caller's location through a caught error.
                local _, message = pcall(error, "", 3)
                local _, _, source = string.find(message, '^%[string "(.-)"%]:')
                local modulePath

                if source and string.find(source, "/Scripts/") then
                    if string.sub(source, -3) == "..." then
                        -- The complete number and following space must survive truncation.
                        local _, _, prefix = string.find(source, "^(.-/Scripts/%d%d%.%d%d )")
                        assert(prefix, "Cannot identify module script: " .. source)
                        source = THEME:GetPath(EC_OTHER, "", "../../../" .. prefix .. "*.lua")
                    end
                    _, _, modulePath = string.find(source, "/Scripts/%d%d%.%d%d ([%w_%.]+)%.lua$")
                end

                if modulePath then
                    local values = setmetatable({}, { __index = lookup })
                    rawset(values, name, value)
                    moduleTree = addModule(moduleTree, modulePath, values)
                    modules[modulePath] = values
                    -- Subsequent declarations belong to this module's table.
                    setfenv(2, values)
                else
                    rawset(globals, name, value)
                end
            end,
        })

        -- New scripts inherit this environment; existing engine functions keep theirs.
        setfenv(0, moduleEnvironment)

        return function()
            -- Restore normal globals for the engine and the initialisation script.
            setfenv(0, globals)
            setfenv(2, globals)

            local tree = {}
            for path, values in pairs(modules) do
                -- Copy the declarations without their environment's lookup metatable.
                tree = addModule(tree, path, NightCore.build({}, { values }))
            end
            return tree
        end
    end,
}
