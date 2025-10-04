local t = {}
infmath = {}
infmath.Version = "0.1"

local math = math
local math_floor = math.floor
local math_Round = math.Round
local math_log10 = math.log10
local math_max = math.max

local MAX_NUMBER = 1.7976931348623e308
local MAX_NUMBER_mantissa = 1.7976931348623
local MAX_NUMBER_exponent = 308

-- Placeholder values
t.mantissa = 0
t.exponent = 0

local function ConvertNumberToInfNumber(number) -- Just in case.
    if istable(number) then return number end

    return InfNumber(number)
end

local function FixMantissa(self) -- Just in case.
    if !istable(self) then return end

    -- local m = self.mantissa
    if self.mantissa == math.huge then
        self.mantissa = MAX_NUMBER_mantissa
        self.exponent = self.exponent + MAX_NUMBER_exponent
    elseif self.mantissa >= 10 or self.mantissa < 1 then
        local e = math_floor(math_log10(self.mantissa))
        self.mantissa = self.mantissa / (10^e)
        self.exponent = self.exponent + e
    end
    -- self.mantissa = m

    return self
end

t.log = function(self, x)
    return (math_log10(self.mantissa) + self.exponent) / math_log10(x)
end
t.log10 = function(self)
    return math_log10(self.mantissa) + self.exponent
end
t.FormatText = function(self) -- Use Scientific notation
    local e = self.exponent
    local e_negative = e < 0
    return e > -2 and e < 9 and self.mantissa * 10^e or
    math_Round(self.mantissa, 2).."e"..(math.abs(e) >= 1e9 and "e"..math_Round(math_log10(math.abs(e))*(e_negative and -1 or 1), 2) or e)
end

t.add = function(self, tbl)
    tbl = ConvertNumberToInfNumber(tbl)


    self.mantissa = self.mantissa + tbl.mantissa/(10^(self.exponent-tbl.exponent))
    
    FixMantissa(self)
    return self
end

t.sub = function(self, tbl)
    tbl = ConvertNumberToInfNumber(tbl)


    self.mantissa = self.mantissa - tbl.mantissa/(10^(self.exponent-tbl.exponent))
    
    FixMantissa(self)
    return self
end

t.mul = function(self, tbl) -- Multiply
    tbl = ConvertNumberToInfNumber(tbl)

    local exponent = self.exponent
    self.mantissa = self.mantissa * tbl.mantissa
    self.exponent = self.exponent + tbl.exponent

    FixMantissa(self)
    return self
end

t.div = function(self, tbl) -- Multiply
    tbl = ConvertNumberToInfNumber(tbl)

    local exponent = self.exponent
    self.mantissa = self.mantissa / tbl.mantissa
    self.exponent = self.exponent - tbl.exponent

    FixMantissa(self)
    return self
end

t.pow = function(self, number) -- Power (normal numbers only, plus its very complicated)
    -- tbl = ConvertNumberToInfNumber(tbl)


    local man = self.mantissa
    local exp = self.exponent
    for i=1,math.ceil(math.min(number-1, 1e3)) do
        self.mantissa = self.mantissa * man--^math.min(number-i, number)
        if exp > 1 then
            self.exponent = self.exponent * exp
        end
        FixMantissa(self)
        if self.exponent == math.huge then break end
    end

/*
    self.mantissa = self.mantissa ^ tbl.mantissa
    -- self.exponent = math.floor(math_log10(self.mantissa))
    self.exponent = self.exponent ^ math_max(1, tbl.exponent)
    FixMantissa(self)
*/
    return self
end

t.tet = function(self, number) -- Tetration (normal numbers! far more complicated than pow function)
    local exponent = self.exponent
    -- Assume it's just a tetration as at very high numbers it would barely affect the exponent.. Dunno how to write a function for tetration without making the code lag.
    -- self.mantissa = self.mantissa ^ number
    -- self.exponent = self.exponent ^ number
    -- Alt function, but is more expensive:
    for i=1,math.ceil(math.min(number, 1e3)) do
        self.mantissa = self.mantissa ^ number^math.min(number-i, number) -- Assume it's just a tetration as at very high numbers it would barely affect the exponent.. Dunno how to write a function for tetration without making the code lag.
        self.exponent = self.exponent * number
        FixMantissa(self)
        if self.exponent == math.huge then break end
    end

end

t.lessthan = function(self, tbl)
    tbl = ConvertNumberToInfNumber(tbl)

    -- return (self.exponent + math_log10(self.mantissa)) < (tbl.exponent + math_log10(tbl.mantissa))
    return self:log10() < tbl:log10() -- can use log10 directly though
end

t.morethan = function(self, tbl)
    tbl = ConvertNumberToInfNumber(tbl)
    -- return (self.exponent + math_log10(self.mantissa)) > (tbl.exponent + math_log10(tbl.mantissa))
    return self:log10() > tbl:log10()
end

RegisterMetaTable("BreakInfinity", t) -- i don't know how to use this
local meta = FindMetaTable("BreakInfinity")

TYPE_BREAKINFINITY = meta.MetaID

-- Repeatedly calling this function multiple times may impact the performance.
function InfNumber(mantissa, exponent)
    if !mantissa then mantissa = 0 end
    if !exponent then exponent = 0 end
    local tbl = table.Copy(t)
    -- print(setmetatable(tbl, meta))
    -- print(type(tbl))

    if mantissa == math.huge then
        mantissa = MAX_NUMBER_mantissa
        exponent = exponent + MAX_NUMBER_exponent
    elseif mantissa >= 10 or mantissa < 1 then
        local e = math_floor(math_log10(mantissa))
        mantissa = mantissa / (10^e)
        exponent = exponent + e

    end

    tbl.mantissa = mantissa
    tbl.exponent = exponent

    return tbl
end

function ConvertStringToInfNumber(str)

    local t = string.Explode("e", str)
    local mantissa = tonumber(t[1])
    local exponent = tonumber(t[2] == "" and 10^t[3] or t[2])


    return InfNumber(mantissa, exponent)
end

infmath.FormatText = t.FormatText

infmath.exp = function(x)
    local t = InfNumber(math.exp(1))
    t:pow(x)

    return t
end



print("Break Infinity v"..infmath.Version.." loaded and initialized!")
print("Break Infinity MetaTable Type: "..TYPE_BREAKINFINITY)

-- Same as net.WriteTable and net.ReadTable, but with small differences to make it a bit optimized
function net.WriteInfNumber(tbl)
    tbl = ConvertNumberToInfNumber(tbl)
    net.WriteTable({
        mantissa = tbl.mantissa,
        exponent = tbl.exponent,
    })
end

function net.ReadInfNumber()
    local t = net.ReadTable()
    return InfNumber(t.mantissa, t.exponent)
end

if SERVER then return end
local handler = "BREAKINF.TestIncrement"
concommand.Add("breakinfinity_testincrement_add", function()
    local n = InfNumber(1, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n:add(n)
        print(n:FormatText())
    end)
end)
concommand.Add("breakinfinity_testincrement_mul", function()
    local n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n:mul(n)
        print(n:FormatText())
    end)
end)
concommand.Add("breakinfinity_testincrement_pow", function()
    local n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n:pow(3)
        print(n:FormatText())
    end)
end)

concommand.Add("breakinfinity_testincrement_stop", function()
    timer.Remove(handler)
end)

concommand.Add("breakinfinity_testincrement_test", function()
    local t = 0


    t = t + 1
    print("Test "..t..": 1.62e800+6.66e799")
    local test = InfNumber(1.62, 800)
    test:add(InfNumber(6.66, 799))
    print(test:FormatText())
    
    t = t + 1
    print("Test "..t..": "..MAX_NUMBER_mantissa.."e"..MAX_NUMBER_exponent.."*"..MAX_NUMBER_mantissa.."e"..MAX_NUMBER_exponent)
    local test = InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent)
    test:mul(InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent))
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.79e308^30")
    local test = InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent)
    test:pow(30)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 400^^10")
    local test = InfNumber(4, 2)
    test:tet(10)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 400^^1000")
    local test = InfNumber(4, 2)
    test:tet(1000)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e800-6.66e799")
    local test = InfNumber(1.62, 800)
    test:sub(InfNumber(6.66, 799))
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e800/6.66e799")
    local test = InfNumber(1.62, 800)
    test:div(InfNumber(6.66, 799))
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e80/6.66e799")
    local test = InfNumber(1.62, 80)
    test:div(InfNumber(6.66, 799))
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 4.20e-69^1000")
    local test = InfNumber(4.20, -69)
    test:pow(5)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 4.20e609<1e100")
    local test = InfNumber(4.20, 609)
    print(test:lessthan(InfNumber(1, 100)))

    t = t + 1
    print("Test "..t..": 4.20e609<1e1000")
    local test = InfNumber(4.20, 609)
    print(test:lessthan(InfNumber(1, 1000)))
end)
