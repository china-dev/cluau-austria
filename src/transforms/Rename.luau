-- Austria CLUAU
-- src/transforms/Rename.luau

local Rename = {}

local KEYWORDS = {
    ["and"] = true,
    ["break"] = true,
    ["continue"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["export"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["type"] = true,
    ["until"] = true,
    ["while"] = true,
}

local function generator(seed)
    local rng = Random.new(seed)

    return function(index)
        local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local result = ""

        repeat
            local position = rng:NextInteger(1, #alphabet)
            result ..= alphabet:sub(position, position)
        until not KEYWORDS[result]

        return result .. tostring(index)
    end
end

local function walk(node, callback)
    if type(node) ~= "table" then
        return
    end

    callback(node)

    for key, value in pairs(node) do
        if key ~= "kind" and type(value) == "table" then
            if value.kind then
                walk(value, callback)
            else
                for _, item in ipairs(value) do
                    if type(item) == "table" and item.kind then
                        walk(item, callback)
                    end
                end
            end
        end
    end
end

function Rename.transform(ast, seed)
    local makeName = generator(seed or 1)

    local scopes = {}
    local currentScope = nil
    local counter = 0

    local function newScope(parent)
        local scope = {
            parent = parent,
            names = {},
        }

        return scope
    end

    local function lookup(scope, name)
        local current = scope

        while current do
            if current.names[name] then
                return current.names[name]
            end

            current = current.parent
        end

        return nil
    end

    local function declare(scope, name)
        if KEYWORDS[name] then
            return name
        end

        if not scope.names[name] then
            counter += 1
            scope.names[name] = makeName(counter)
        end

        return scope.names[name]
    end

    local function visit(node)
        if node.kind == "Program" or node.kind == "Block" then
            local parent = currentScope
            currentScope = newScope(parent)

            for _, statement in ipairs(node.body) do
                visit(statement)
            end

            currentScope = parent
            return
        end

        if node.kind == "LocalDeclaration" then
            for _, name in ipairs(node.names) do
                if name.kind == "Identifier" then
                    name.name = declare(currentScope, name.name)
                end
            end

            for _, value in ipairs(node.values) do
                visit(value)
            end

            return
        end

        if node.kind == "FunctionDeclaration" then
            if node.isLocal and node.name.kind == "Identifier" then
                node.name.name = declare(
                    currentScope,
                    node.name.name
                )
            end

            local parent = currentScope
            currentScope = newScope(parent)

            for _, parameter in ipairs(node.parameters) do
                if parameter.kind == "Identifier"
                    and parameter.name ~= "..."
                then
                    parameter.name = declare(
                        currentScope,
                        parameter.name
                    )
                end
            end

            visit(node.body)

            currentScope = parent
            return
        end

        if node.kind == "Identifier" then
            local replacement = lookup(
                currentScope,
                node.name
            )

            if replacement then
                node.name = replacement
            end

            return
        end

        for key, value in pairs(node) do
            if key ~= "kind" and type(value) == "table" then
                if value.kind then
                    visit(value)
                else
                    for _, item in ipairs(value) do
                        if type(item) == "table" and item.kind then
                            visit(item)
                        end
                    end
                end
            end
        end
    end

    visit(ast)

    return ast
end

return Rename
