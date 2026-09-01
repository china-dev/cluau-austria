-- Austria CLUAU
-- src/Parser.luau

local AST = require(script.Parent.AST)

local Parser = {}
Parser.__index = Parser

export type ParserInstance = {
    tokens: {any},
    position: number,

    peek: (self: ParserInstance, offset: number?) -> any,
    current: (self: ParserInstance) -> any,
    advance: (self: ParserInstance) -> any,
    match: (self: ParserInstance, value: string) -> boolean,
    expect: (self: ParserInstance, value: string) -> any,

    parse: (self: ParserInstance) -> any,
    parseBlock: (self: ParserInstance, terminators: {[string]: boolean}?) -> any,
    parseStatement: (self: ParserInstance) -> any,
    parseExpression: (self: ParserInstance, minimumPrecedence: number?) -> any,
}

local precedence = {
    ["or"] = 1,
    ["and"] = 2,

    ["=="] = 3,
    ["~="] = 3,
    ["<"] = 3,
    [">"] = 3,
    ["<="] = 3,
    [">="] = 3,

    [".."] = 4,

    ["+"] = 5,
    ["-"] = 5,

    ["*"] = 6,
    ["/"] = 6,
    ["//"] = 6,
    ["%"] = 6,

    ["^"] = 8,
}

local unaryOperators = {
    ["-"] = true,
    ["not"] = true,
    ["#"] = true,
}

local function isToken(token, value)
    return token ~= nil and token.value == value
end

function Parser.new(tokens)
    return setmetatable({
        tokens = tokens,
        position = 1,
    }, Parser)
end

function Parser:current()
    return self.tokens[self.position]
end

function Parser:peek(offset)
    offset = offset or 0
    return self.tokens[self.position + offset]
end

function Parser:advance()
    local token = self:current()

    if token.type ~= "EOF" then
        self.position += 1
    end

    return token
end

function Parser:match(value)
    if isToken(self:current(), value) then
        self:advance()
        return true
    end

    return false
end

function Parser:expect(value)
    local token = self:current()

    if not isToken(token, value) then
        error(
            string.format(
                "Austria Parser: expected '%s' at line %d, column %d; got '%s'",
                value,
                token.line,
                token.column,
                token.value
            )
        )
    end

    return self:advance()
end

function Parser:skipComments()
    while self:current().type == "Comment" do
        self:advance()
    end
end

function Parser:parse()
    local body = {}

    self:skipComments()

    while self:current().type ~= "EOF" do
        table.insert(body, self:parseStatement())
        self:skipComments()
    end

    return AST.Program(body)
end

function Parser:parseBlock(terminators)
    local body = {}

    self:skipComments()

    while self:current().type ~= "EOF" do
        local token = self:current()

        if terminators and terminators[token.value] then
            break
        end

        table.insert(body, self:parseStatement())
        self:skipComments()
    end

    return AST.Block(body)
end

function Parser:parseStatement()
    local token = self:current()

    if token.value == "local" then
        return self:parseLocal()
    end

    if token.value == "function" then
        return self:parseFunction(false)
    end

    if token.value == "return" then
        self:advance()

        local values = {}

        if self:current().value ~= "end"
            and self:current().value ~= "else"
            and self:current().value ~= "elseif"
            and self:current().type ~= "EOF"
        then
            table.insert(values, self:parseExpression())
        end

        return AST.ReturnStatement(values)
    end

    if token.value == "break" then
        self:advance()
        return AST.BreakStatement()
    end

    if token.value == "continue" then
        self:advance()
        return AST.ContinueStatement()
    end

    if token.value == "if" then
        return self:parseIf()
    end

    if token.value == "while" then
        return self:parseWhile()
    end

    if token.value == "repeat" then
        return self:parseRepeat()
    end

    return self:parseExpressionStatement()
end

function Parser:parseLocal()
    self:expect("local")

    if self:match("function") then
        local name = self:parseIdentifier()
        local parameters, body = self:parseFunctionBody()

        return AST.FunctionDeclaration(
            name,
            parameters,
            body,
            true
        )
    end

    local names = {}

    repeat
        table.insert(names, self:parseIdentifier())
    until not self:match(",")

    local values = {}

    if self:match("=") then
        repeat
            table.insert(values, self:parseExpression())
        until not self:match(",")
    end

    return AST.LocalDeclaration(names, values)
end

function Parser:parseFunction(isLocal)
    self:expect("function")

    local name = self:parseIdentifier()

    -- Support simple member chains:
    -- function foo.bar(...)
    while self:match(".") do
        local property = self:parseIdentifier()

        name = AST.MemberExpression(
            name,
            property.name
        )
    end

    local parameters, body = self:parseFunctionBody()

    return AST.FunctionDeclaration(
        name,
        parameters,
        body,
        isLocal
    )
end

function Parser:parseFunctionBody()
    self:expect("(")

    local parameters = {}

    if not self:match(")") then
        repeat
            if self:match("...") then
                table.insert(
                    parameters,
                    AST.Identifier("...")
                )
            else
                table.insert(parameters, self:parseIdentifier())
            end
        until not self:match(",")

        self:expect(")")
    end

    local body = self:parseBlock({
        ["end"] = true,
    })

    self:expect("end")

    return parameters, body
end

function Parser:parseIf()
    self:expect("if")

    local condition = self:parseExpression()

    self:expect("then")

    local body = self:parseBlock({
        ["elseif"] = true,
        ["else"] = true,
        ["end"] = true,
    })

    local elseifBranches = {}

    while self:match("elseif") do
        local elseifCondition = self:parseExpression()

        self:expect("then")

        local elseifBody = self:parseBlock({
            ["elseif"] = true,
            ["else"] = true,
            ["end"] = true,
        })

        table.insert(
            elseifBranches,
            AST.ElseIfBranch(
                elseifCondition,
                elseifBody
            )
        )
    end

    local elseBody = nil

    if self:match("else") then
        elseBody = self:parseBlock({
            ["end"] = true,
        })
    end

    self:expect("end")

    return AST.IfStatement(
        condition,
        body,
        elseifBranches,
        elseBody
    )
end

function Parser:parseWhile()
    self:expect("while")

    local condition = self:parseExpression()

    self:expect("do")

    local body = self:parseBlock({
        ["end"] = true,
    })

    self:expect("end")

    return AST.WhileStatement(
        condition,
        body
    )
end

function Parser:parseRepeat()
    self:expect("repeat")

    local body = self:parseBlock({
        ["until"] = true,
    })

    self:expect("until")

    local condition = self:parseExpression()

    return AST.RepeatStatement(
        body,
        condition
    )
end

function Parser:parseExpressionStatement()
    local expression = self:parseExpression()

    if self:match("=") then
        local targets = {expression}
        local values = {self:parseExpression()}

        while self:match(",") do
            table.insert(targets, self:parseExpression())
        end

        while self:match(",") do
            table.insert(values, self:parseExpression())
        end

        return AST.Assignment(
            targets,
            values
        )
    end

    return AST.ExpressionStatement(expression)
end

function Parser:parseExpression(minimumPrecedence)
    minimumPrecedence = minimumPrecedence or 0

    local left = self:parseUnary()

    while true do
        local token = self:current()
        local operator = token.value

        local currentPrecedence = precedence[operator]

        if not currentPrecedence
            or currentPrecedence < minimumPrecedence
        then
            break
        end

        self:advance()

        local nextPrecedence = currentPrecedence + 1

        -- Power and concatenation are right associative.
        if operator == "^" or operator == ".." then
            nextPrecedence = currentPrecedence
        end

        local right = self:parseExpression(nextPrecedence)

        left = AST.BinaryExpression(
            left,
            operator,
            right
        )
    end

    return left
end

function Parser:parseUnary()
    local token = self:current()

    if unaryOperators[token.value] then
        self:advance()

        return AST.UnaryExpression(
            token.value,
            self:parseUnary()
        )
    end

    return self:parsePostfix(
        self:parsePrimary()
    )
end

function Parser:parsePrimary()
    local token = self:current()

    if token.type == "Identifier" then
        return self:parseIdentifier()
    end

    if token.type == "Number" then
        self:advance()
        return AST.NumberLiteral(token.value)
    end

    if token.type == "String" then
        self:advance()
        return AST.StringLiteral(token.value)
    end

    if token.value == "true" then
        self:advance()
        return AST.BooleanLiteral(true)
    end

    if token.value == "false" then
        self:advance()
        return AST.BooleanLiteral(false)
    end

    if token.value == "nil" then
        self:advance()
        return AST.NilLiteral()
    end

    if token.value == "function" then
        self:advance()

        local parameters, body = self:parseFunctionBody()

        return AST.FunctionExpression(
            parameters,
            body
        )
    end

    if token.value == "{" then
        return self:parseTable()
    end

    if token.value == "(" then
        self:advance()

        local expression = self:parseExpression()

        self:expect(")")

        return expression
    end

    error(
        string.format(
            "Austria Parser: unexpected token '%s' at line %d, column %d",
            token.value,
            token.line,
            token.column
        )
    )
end

function Parser:parseIdentifier()
    local token = self:current()

    if token.type ~= "Identifier" then
        error(
            string.format(
                "Austria Parser: expected identifier at line %d, column %d",
                token.line,
                token.column
            )
        )
    end

    self:advance()

    return AST.Identifier(token.value)
end

function Parser:parsePostfix(expression)
    while true do
        if self:match(".") then
            local property = self:parseIdentifier()

            expression = AST.MemberExpression(
                expression,
                property.name
            )

        elseif self:match("[") then
            local index = self:parseExpression()

            self:expect("]")

            expression = AST.IndexExpression(
                expression,
                index
            )

        elseif self:match("(") then
            local arguments = {}

            if not self:match(")") then
                repeat
                    table.insert(
                        arguments,
                        self:parseExpression()
                    )
                until not self:match(",")

                self:expect(")")
            end

            expression = AST.CallExpression(
                expression,
                arguments
            )
        else
            break
        end
    end

    return expression
end

function Parser:parseTable()
    self:expect("{")

    local fields = {}

    while self:current().value ~= "}" do
        local key = nil
        local value

        if self:match("[") then
            key = self:parseExpression()
            self:expect("]")
            self:expect("=")

            value = self:parseExpression()

        elseif self:current().type == "Identifier"
            and self:peek(1).value == "="
        then
            key = self:parseIdentifier()
            self:expect("=")

            value = self:parseExpression()

        else
            value = self:parseExpression()
        end

        table.insert(
            fields,
            AST.TableField(key, value)
        )

        if not self:match(",") then
            self:match(";")
        end
    end

    self:expect("}")

    return AST.TableExpression(fields)
end

function Parser.parse(tokens)
    return Parser.new(tokens):parse()
end

return Parser
