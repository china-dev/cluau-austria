-- Austria CLUAU
-- src/Lexer.luau

local Lexer = {}

export type Token = {
    type: string,
    value: string,
    start: number,
    finish: number,
    line: number,
    column: number,
}

local keywords = {
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

local multiOperators = {
    ["..."] = true,
    [".."] = true,
    ["=="] = true,
    ["~="] = true,
    ["<="] = true,
    [">="] = true,
    ["::"] = true,
    ["->"] = true,
    ["+="] = true,
    ["-="] = true,
    ["*="] = true,
    ["/="] = true,
    ["%="] = true,
    ["^="] = true,
    ["//"] = true,
}

local function isAlpha(c)
    return c ~= nil and c:match("[A-Za-z_]") ~= nil
end

local function isDigit(c)
    return c ~= nil and c:match("%d") ~= nil
end

local function isAlphaNumeric(c)
    return isAlpha(c) or isDigit(c)
end

local function isWhitespace(c)
    return c ~= nil and c:match("%s") ~= nil
end

local function makeToken(
    tokenType: string,
    value: string,
    startPos: number,
    endPos: number,
    line: number,
    column: number
): Token
    return {
        type = tokenType,
        value = value,
        start = startPos,
        finish = endPos,
        line = line,
        column = column,
    }
end

function Lexer.new(source: string)
    local self = {
        source = source,
        position = 1,
        line = 1,
        column = 1,
        length = #source,
    }

    return setmetatable(self, {
        __index = Lexer,
    })
end

function Lexer:peek(offset: number?): string?
    offset = offset or 0

    local position = self.position + offset

    if position > self.length then
        return nil
    end

    return self.source:sub(position, position)
end

function Lexer:advance(): string?
    local c = self:peek()

    if not c then
        return nil
    end

    self.position += 1

    if c == "\n" then
        self.line += 1
        self.column = 1
    else
        self.column += 1
    end

    return c
end

function Lexer:consumeWhitespace()
    while isWhitespace(self:peek()) do
        self:advance()
    end
end

function Lexer:readIdentifier()
    local start = self.position
    local line = self.line
    local column = self.column

    while isAlphaNumeric(self:peek()) do
        self:advance()
    end

    local value = self.source:sub(start, self.position - 1)

    if keywords[value] then
        return makeToken(
            "Keyword",
            value,
            start,
            self.position - 1,
            line,
            column
        )
    end

    return makeToken(
        "Identifier",
        value,
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:readNumber()
    local start = self.position
    local line = self.line
    local column = self.column

    -- Hexadecimal numbers.
    if self:peek() == "0"
        and (self:peek(1) == "x" or self:peek(1) == "X")
    then
        self:advance()
        self:advance()

        while isDigit(self:peek())
            or (self:peek() ~= nil and self:peek():lower():match("[a-f]"))
        do
            self:advance()
        end

        return makeToken(
            "Number",
            self.source:sub(start, self.position - 1),
            start,
            self.position - 1,
            line,
            column
        )
    end

    while isDigit(self:peek()) do
        self:advance()
    end

    if self:peek() == "." and isDigit(self:peek(1)) then
        self:advance()

        while isDigit(self:peek()) do
            self:advance()
        end
    end

    -- Scientific notation.
    if self:peek() == "e" or self:peek() == "E" then
        self:advance()

        if self:peek() == "+" or self:peek() == "-" then
            self:advance()
        end

        while isDigit(self:peek()) do
            self:advance()
        end
    end

    return makeToken(
        "Number",
        self.source:sub(start, self.position - 1),
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:readString()
    local start = self.position
    local line = self.line
    local column = self.column

    local quote = self:advance()

    while self:peek() do
        local c = self:peek()

        if c == "\\" then
            self:advance()

            if self:peek() then
                self:advance()
            end
        elseif c == quote then
            self:advance()
            break
        else
            self:advance()
        end
    end

    return makeToken(
        "String",
        self.source:sub(start, self.position - 1),
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:readLongBracket()
    local start = self.position
    local line = self.line
    local column = self.column

    self:advance() -- [

    local equals = 0

    while self:peek() == "=" do
        equals += 1
        self:advance()
    end

    if self:peek() ~= "[" then
        return nil
    end

    self:advance()

    while self:peek() do
        if self:peek() == "]" then
            local i = 1

            while i <= equals and self:peek(i) == "=" do
                i += 1
            end

            if i == equals + 1 and self:peek(i) == "]" then
                self:advance()

                for _ = 1, equals do
                    self:advance()
                end

                self:advance()
                break
            end
        end

        self:advance()
    end

    return makeToken(
        "String",
        self.source:sub(start, self.position - 1),
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:readComment()
    local start = self.position
    local line = self.line
    local column = self.column

    self:advance()
    self:advance()

    local longStart = self.position

    if self:peek() == "[" then
        local token = self:readLongBracket()

        if token then
            return makeToken(
                "Comment",
                self.source:sub(start, self.position - 1),
                start,
                self.position - 1,
                line,
                column
            )
        end
    end

    while self:peek() and self:peek() ~= "\n" do
        self:advance()
    end

    return makeToken(
        "Comment",
        self.source:sub(start, self.position - 1),
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:readOperator()
    local start = self.position
    local line = self.line
    local column = self.column

    local three = (self:peek() or "")
        .. (self:peek(1) or "")
        .. (self:peek(2) or "")

    local two = (self:peek() or "")
        .. (self:peek(1) or "")

    local value

    if multiOperators[three] then
        value = three

        for _ = 1, 3 do
            self:advance()
        end
    elseif multiOperators[two] then
        value = two

        for _ = 1, 2 do
            self:advance()
        end
    else
        value = self:advance()
    end

    return makeToken(
        "Operator",
        value,
        start,
        self.position - 1,
        line,
        column
    )
end

function Lexer:next()
    self:consumeWhitespace()

    local start = self.position
    local line = self.line
    local column = self.column

    if self.position > self.length then
        return makeToken(
            "EOF",
            "",
            start,
            start,
            line,
            column
        )
    end

    local c = self:peek()

    -- Comments.
    if c == "-" and self:peek(1) == "-" then
        return self:readComment()
    end

    -- Identifiers / keywords.
    if isAlpha(c) then
        return self:readIdentifier()
    end

    -- Numbers.
    if isDigit(c) then
        return self:readNumber()
    end

    -- Quoted strings.
    if c == '"' or c == "'" then
        return self:readString()
    end

    -- Long bracket strings.
    if c == "[" then
        local token = self:readLongBracket()

        if token then
            return token
        end
    end

    return self:readOperator()
end

function Lexer:tokenize()
    local tokens = {}

    while true do
        local token = self:next()

        table.insert(tokens, token)

        if token.type == "EOF" then
            break
        end
    end

    return tokens
end

function Lexer.tokenize(source: string)
    return Lexer.new(source):tokenize()
end

return Lexer
