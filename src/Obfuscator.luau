-- Austria CLUAU
-- src/Obfuscator.luau

local Lexer = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/china-dev/cluau-austria/main/src/Lexer.luau"
))()

local Parser = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/china-dev/cluau-austria/main/src/Parser.luau"
))()

local Printer = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/china-dev/cluau-austria/main/src/Printer.luau"
))()

local Rename = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/china-dev/cluau-austria/main/src/transforms/Rename.luau"
))()

local Obfuscator = {}
Obfuscator.__index = Obfuscator

export type Options = {
    Rename: boolean?,
    Minify: boolean?,
    Strings: boolean?,
    Constants: boolean?,
    Seed: number?,
}

export type ObfuscatorInstance = {
    options: Options,
    seed: number,

    tokenize: (self: ObfuscatorInstance, source: string) -> {any},
    parse: (self: ObfuscatorInstance, tokens: {any}) -> any,
    obfuscate: (self: ObfuscatorInstance, source: string) -> string,
    getSeed: (self: ObfuscatorInstance) -> number,
}

local function generateSeed(): number
    return Random.new():NextInteger(1, 2147483647)
end

function Obfuscator.new(options: Options?)
    local config = options or {}

    return setmetatable({
        options = {
            Rename = config.Rename ~= false,
            Minify = config.Minify ~= false,
            Strings = config.Strings == true,
            Constants = config.Constants == true,
            Seed = config.Seed,
        },

        seed = config.Seed or generateSeed(),
    }, Obfuscator)
end

function Obfuscator:tokenize(source: string)
    return Lexer.tokenize(source)
end

function Obfuscator:parse(tokens)
    return Parser.parse(tokens)
end

function Obfuscator:obfuscate(source: string): string
    assert(
        type(source) == "string",
        "Austria CLUAU: source must be a string"
    )

    -- Stage 1: Lexer
    local tokens = self:tokenize(source)

    -- Stage 2: Parser
    local ast = self:parse(tokens)

    -- Stage 3: Transformations

    if self.options.Rename then
        ast = Rename.transform(ast, self.seed)
    end

    -- Stage 4: Printer
    return Printer.print(ast)
end

function Obfuscator:getSeed(): number
    return self.seed
end

return Obfuscator
