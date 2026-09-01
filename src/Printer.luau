-- Austria CLUAU
-- src/Printer.luau

local Printer = {}
Printer.__index = Printer

export type PrinterInstance = {
    parts: {string},
    write: (self: PrinterInstance, value: string) -> (),
    emit: (self: PrinterInstance, node: any) -> (),
    result: (self: PrinterInstance) -> string,
}

function Printer.new()
    return setmetatable({
        parts = {},
    }, Printer)
end

function Printer:write(value: string)
    table.insert(self.parts, value)
end

function Printer:result(): string
    return table.concat(self.parts)
end

function Printer:emit(node)
    local kind = node.kind

    if kind == "Program" then
        self:write("-- Austria CLUAU\n")

        for _, statement in ipairs(node.body) do
            self:emit(statement)
        end

    elseif kind == "Block" then
        for _, statement in ipairs(node.body) do
            self:emit(statement)
        end

    elseif kind == "Identifier" then
        self:write(node.name)

    elseif kind == "StringLiteral" then
        self:write(node.value)

    elseif kind == "NumberLiteral" then
        self:write(node.value)

    elseif kind == "BooleanLiteral" then
        self:write(node.value and "true" or "false")

    elseif kind == "NilLiteral" then
        self:write("nil")

    elseif kind == "LocalDeclaration" then
        self:write("local ")

        for i, name in ipairs(node.names) do
            if i > 1 then
                self:write(",")
            end

            self:emit(name)
        end

        if #node.values > 0 then
            self:write("=")

            for i, value in ipairs(node.values) do
                if i > 1 then
                    self:write(",")
                end

                self:emit(value)
            end
        end

        self:write("\n")

    elseif kind == "Assignment" then
        for i, target in ipairs(node.targets) do
            if i > 1 then
                self:write(",")
            end

            self:emit(target)
        end

        self:write("=")

        for i, value in ipairs(node.values) do
            if i > 1 then
                self:write(",")
            end

            self:emit(value)
        end

        self:write("\n")

    elseif kind == "ExpressionStatement" then
        self:emit(node.expression)
        self:write("\n")

    elseif kind == "ReturnStatement" then
        self:write("return")

        if #node.values > 0 then
            self:write(" ")

            for i, value in ipairs(node.values) do
                if i > 1 then
                    self:write(",")
                end

                self:emit(value)
            end
        end

        self:write("\n")

    elseif kind == "BreakStatement" then
        self:write("break\n")

    elseif kind == "ContinueStatement" then
        self:write("continue\n")

    elseif kind == "BinaryExpression" then
        self:emit(node.left)
        self:write(node.operator)
        self:emit(node.right)

    elseif kind == "UnaryExpression" then
        self:write(node.operator)

        if node.operator == "not" then
            self:write(" ")
        end

        self:emit(node.operand)

    elseif kind == "CallExpression" then
        self:emit(node.callee)
        self:write("(")

        for i, argument in ipairs(node.arguments) do
            if i > 1 then
                self:write(",")
            end

            self:emit(argument)
        end

        self:write(")")

    elseif kind == "MemberExpression" then
        self:emit(node.object)
        self:write(".")
        self:write(node.property)

    elseif kind == "IndexExpression" then
        self:emit(node.object)
        self:write("[")
        self:emit(node.index)
        self:write("]")

    elseif kind == "FunctionExpression" then
        self:write("function(")

        for i, parameter in ipairs(node.parameters) do
            if i > 1 then
                self:write(",")
            end

            self:emit(parameter)
        end

        self:write(")")
        self:emit(node.body)
        self:write("end")

    elseif kind == "FunctionDeclaration" then
        if node.isLocal then
            self:write("local ")
        end

        self:write("function ")
        self:emit(node.name)
        self:write("(")

        for i, parameter in ipairs(node.parameters) do
            if i > 1 then
                self:write(",")
            end

            self:emit(parameter)
        end

        self:write(")")
        self:emit(node.body)
        self:write("end\n")

    elseif kind == "IfStatement" then
        self:write("if ")
        self:emit(node.condition)
        self:write(" then\n")

        self:emit(node.body)

        for _, branch in ipairs(node.elseifBranches) do
            self:write("elseif ")
            self:emit(branch.condition)
            self:write(" then\n")
            self:emit(branch.body)
        end

        if node.elseBody then
            self:write("else\n")
            self:emit(node.elseBody)
        end

        self:write("end\n")

    elseif kind == "WhileStatement" then
        self:write("while ")
        self:emit(node.condition)
        self:write(" do\n")
        self:emit(node.body)
        self:write("end\n")

    elseif kind == "RepeatStatement" then
        self:write("repeat\n")
        self:emit(node.body)
        self:write("until ")
        self:emit(node.condition)
        self:write("\n")

    elseif kind == "TableExpression" then
        self:write("{")

        for i, field in ipairs(node.fields) do
            if i > 1 then
                self:write(",")
            end

            self:emit(field)
        end

        self:write("}")

    elseif kind == "TableField" then
        if node.key then
            if node.key.kind == "Identifier" then
                self:emit(node.key)
            else
                self:write("[")
                self:emit(node.key)
                self:write("]")
            end

            self:write("=")
        end

        self:emit(node.value)

    else
        error("Austria Printer: unsupported AST node: " .. tostring(kind))
    end
end

function Printer.print(ast)
    local printer = Printer.new()
    printer:emit(ast)

    return printer:result()
end

return Printer
