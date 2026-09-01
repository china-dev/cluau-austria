-- Austria CLUAU
-- src/AST.luau

local AST = {}

export type Node = {
    kind: string,
    [string]: any,
}

local function node(kind: string, data: {[string]: any}?): Node
    local result = data or {}
    result.kind = kind
    return result
end

-- Program
function AST.Program(body: {Node}): Node
    return node("Program", {
        body = body,
    })
end

-- Identifiers / literals
function AST.Identifier(name: string): Node
    return node("Identifier", {
        name = name,
    })
end

function AST.StringLiteral(value: string): Node
    return node("StringLiteral", {
        value = value,
    })
end

function AST.NumberLiteral(value: string): Node
    return node("NumberLiteral", {
        value = value,
    })
end

function AST.BooleanLiteral(value: boolean): Node
    return node("BooleanLiteral", {
        value = value,
    })
end

function AST.NilLiteral(): Node
    return node("NilLiteral")
end

-- Expressions
function AST.BinaryExpression(
    left: Node,
    operator: string,
    right: Node
): Node
    return node("BinaryExpression", {
        left = left,
        operator = operator,
        right = right,
    })
end

function AST.UnaryExpression(
    operator: string,
    operand: Node
): Node
    return node("UnaryExpression", {
        operator = operator,
        operand = operand,
    })
end

function AST.CallExpression(
    callee: Node,
    arguments: {Node}
): Node
    return node("CallExpression", {
        callee = callee,
        arguments = arguments,
    })
end

function AST.IndexExpression(
    object: Node,
    index: Node
): Node
    return node("IndexExpression", {
        object = object,
        index = index,
    })
end

function AST.MemberExpression(
    object: Node,
    property: string
): Node
    return node("MemberExpression", {
        object = object,
        property = property,
    })
end

function AST.FunctionExpression(
    parameters: {Node},
    body: Node
): Node
    return node("FunctionExpression", {
        parameters = parameters,
        body = body,
    })
end

function AST.TableExpression(
    fields: {Node}
): Node
    return node("TableExpression", {
        fields = fields,
    })
end

function AST.TableField(
    key: Node?,
    value: Node
): Node
    return node("TableField", {
        key = key,
        value = value,
    })
end

-- Statements
function AST.LocalDeclaration(
    names: {Node},
    values: {Node}
): Node
    return node("LocalDeclaration", {
        names = names,
        values = values,
    })
end

function AST.Assignment(
    targets: {Node},
    values: {Node}
): Node
    return node("Assignment", {
        targets = targets,
        values = values,
    })
end

function AST.ExpressionStatement(expression: Node): Node
    return node("ExpressionStatement", {
        expression = expression,
    })
end

function AST.ReturnStatement(values: {Node}): Node
    return node("ReturnStatement", {
        values = values,
    })
end

function AST.BreakStatement(): Node
    return node("BreakStatement")
end

function AST.ContinueStatement(): Node
    return node("ContinueStatement")
end

function AST.IfStatement(
    condition: Node,
    body: Node,
    elseifBranches: {Node},
    elseBody: Node?
): Node
    return node("IfStatement", {
        condition = condition,
        body = body,
        elseifBranches = elseifBranches,
        elseBody = elseBody,
    })
end

function AST.ElseIfBranch(
    condition: Node,
    body: Node
): Node
    return node("ElseIfBranch", {
        condition = condition,
        body = body,
    })
end

function AST.WhileStatement(
    condition: Node,
    body: Node
): Node
    return node("WhileStatement", {
        condition = condition,
        body = body,
    })
end

function AST.RepeatStatement(
    body: Node,
    condition: Node
): Node
    return node("RepeatStatement", {
        body = body,
        condition = condition,
    })
end

function AST.ForNumericStatement(
    variable: Node,
    start: Node,
    finish: Node,
    step: Node?,
    body: Node
): Node
    return node("ForNumericStatement", {
        variable = variable,
        start = start,
        finish = finish,
        step = step,
        body = body,
    })
end

function AST.ForGenericStatement(
    variables: {Node},
    iterators: {Node},
    body: Node
): Node
    return node("ForGenericStatement", {
        variables = variables,
        iterators = iterators,
        body = body,
    })
end

function AST.FunctionDeclaration(
    name: Node,
    parameters: {Node},
    body: Node,
    isLocal: boolean
): Node
    return node("FunctionDeclaration", {
        name = name,
        parameters = parameters,
        body = body,
        isLocal = isLocal,
    })
end

function AST.Block(body: {Node}): Node
    return node("Block", {
        body = body,
    })
end

-- Utility helpers

function AST.isExpression(n: Node): boolean
    local kind = n.kind

    return kind == "Identifier"
        or kind == "StringLiteral"
        or kind == "NumberLiteral"
        or kind == "BooleanLiteral"
        or kind == "NilLiteral"
        or kind == "BinaryExpression"
        or kind == "UnaryExpression"
        or kind == "CallExpression"
        or kind == "IndexExpression"
        or kind == "MemberExpression"
        or kind == "FunctionExpression"
        or kind == "TableExpression"
end

function AST.clone(n: Node): Node
    local copy = {}

    for key, value in pairs(n) do
        if type(value) == "table" then
            if value.kind then
                copy[key] = AST.clone(value)
            else
                local array = {}

                for i, item in ipairs(value) do
                    if type(item) == "table" and item.kind then
                        array[i] = AST.clone(item)
                    else
                        array[i] = item
                    end
                end

                copy[key] = array
            end
        else
            copy[key] = value
        end
    end

    return copy
end

return AST
