local t = {}
local meta = {}
meta.__index = t

infmath = {}
infmath.Version = "0.3"

-- Cache values in locals for faster code execution
local math = math
local math_floor = math.floor
local math_Round = math.Round
local math_ceil = math.ceil
local math_log10 = math.log10
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_exp = math.exp
local math_huge = math.huge
local tonumber = tonumber

local MAX_NUMBER = 1.7976931348623e308
local MAX_NUMBER_mantissa = 1.7976931348623
local MAX_NUMBER_exponent = 308

-- infmath
function infmath.ConvertNumberToInfNumber(number)
    if istable(number) then return number end
    return InfNumber(number)
end

function infmath.ConvertInfNumberToNormalNumber(tbl) -- temp fix for the pow functions
    if isnumber(tbl) then return tbl end
    return tbl.mantissa * 10^tbl.exponent
end

-- Placeholder values
t.mantissa = 0
t.exponent = 0

local ConvertNumberToInfNumber = infmath.ConvertNumberToInfNumber
local ConvertInfNumberToNormalNumber = infmath.ConvertInfNumberToNormalNumber

local function FixMantissa(self) -- Just in case.
    if !istable(self) then return end

    local m = self.mantissa
    if m == math_huge then
        m = MAX_NUMBER_mantissa
        self.exponent = self.exponent + MAX_NUMBER_exponent
    elseif m >= 10 or m < 1 then
        local e = math_floor(math_log10(self.mantissa))
        m = m / (10^e)
        self.exponent = self.exponent + e
    end
    self.mantissa = m

    return self
end

local function FixExponent(self) -- Just in case.
    if !istable(self) then return end

    if self.exponent ~= math_floor(self.exponent) then
        self.mantissa = self.mantissa * 10^(self.exponent - math_floor(self.exponent))
        self.exponent = self.exponent - (self.exponent - math_floor(self.exponent))
    end

    return self
end

local function FixMantissaExponent(self)
    FixMantissa(self)
    FixExponent(self)
end

t.log = function(self, x)
    return (math_log10(self.mantissa) + self.exponent) / math_log10(x)
end
t.log10 = function(self)
    return math_log10(self.mantissa) + self.exponent
end
t.FormatText = function(self, roundto) -- Use Scientific notation
    local e = self.exponent
    local e_negative = e < 0
    return e > -2 and e < 9 and self.mantissa * 10^e or
    math_Round(self.mantissa, roundto or 14).."e"..(e_negative and "-" or "+")..(math_abs(e) >= 1e9 and "e"..math_Round(math_log10(math_abs(e)), 2) or math.abs(e))
end

t.add = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)


    self.mantissa = self.mantissa + tbl.mantissa/(10^(self.exponent-tbl.exponent))
    
    FixMantissaExponent(self)
    return self
end
meta.__add = t.add

t.sub = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)


    self.mantissa = self.mantissa - tbl.mantissa/(10^(self.exponent-tbl.exponent))
    
    FixMantissaExponent(self)
    return self
end
meta.__sub = t.sub

t.mul = function(self, tbl) -- Multiply
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

    local exponent = self.exponent
    self.mantissa = self.mantissa * tbl.mantissa
    self.exponent = self.exponent + tbl.exponent

    FixMantissaExponent(self)
    return self
end
meta.__mul = t.mul

t.div = function(self, tbl) -- Multiply
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

    local exponent = self.exponent
    self.mantissa = self.mantissa / tbl.mantissa
    self.exponent = self.exponent - tbl.exponent

    FixMantissaExponent(self)
    return self
end
meta.__div = t.div

t.pow = function(self, tbl) -- Power (normal numbers only, very complicated to code)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

/*
    local man = self.mantissa
    local exp = self.exponent
    for i=1,math_ceil(math_min(number-1, 1e3)) do
        self.mantissa = self.mantissa * man--^math_min(number-i, number)
        self.exponent = self.exponent + exp
        FixMantissaExponent(self)
        if self.exponent == math_huge then break end
    end
*/
/*
    local m = InfNumber(self.mantissa)
    m = m * tbl
    self.exponent = self.exponent + m.exponent
    m.exponent = 0
*/
    self.mantissa = self.mantissa ^ ConvertInfNumberToNormalNumber(tbl)
    self.exponent = (self.exponent)*ConvertInfNumberToNormalNumber(tbl)
    FixMantissaExponent(self)

    return self
end
meta.__pow = t.pow

t.tet = function(self, number) -- Tetration (normal numbers! far more complicated than pow function)
    local exponent = self.exponent
    -- Assume it's just a tetration as at very high numbers it would barely affect the exponent.. Dunno how to write a function for tetration without making the code lag.
    self.mantissa = self.mantissa ^ number
    self.exponent = self.exponent ^ number
    FixMantissaExponent(self)
    -- Alt function, but is more expensive:
--[[
    for i=1,math_ceil(math_min(number, 1e3)) do
        self.mantissa = self.mantissa ^ number^math_min(number-i, number) -- Assume it's just a tetration as at very high numbers it would barely affect the exponent.. Dunno how to write a function for tetration without making the code lag.
        self.exponent = self.exponent * number
        FixMantissaExponent(self)
        if self.exponent == math_huge then break end
    end
]]
end

t.eq = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

    return self.mantissa == tbl.mantissa and self.exponent == tbl.exponent
end
meta.__eq = t.eq

t.lt = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

    -- return (self.exponent + math_log10(self.mantissa)) < (tbl.exponent + math_log10(tbl.mantissa))
    return self:log10() < tbl:log10() -- can use log10 directly though
end
meta.__lt = t.lt

t.le = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)

    return self.exponent < tbl.exponent or self:log10() <= tbl:log10()
end
meta.__le = t.le

t.morethan = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)
    -- return (self.exponent + math_log10(self.mantissa)) > (tbl.exponent + math_log10(tbl.mantissa))
    return self:log10() > tbl:log10()
end

-- RegisterMetaTable("BreakInfinity", t) -- i don't know how to use this
-- local meta = FindMetaTable("BreakInfinity")
-- TYPE_BREAKINFINITY = meta.MetaID

function t:Create(n)
  local base = {}
  base = setmetatable(base, meta)
  return base
end

-- Repeatedly calling this function multiple times may impact the performance.
function InfNumber(mantissa, exponent)
    mantissa = mantissa or 0
    exponent = exponent or 0
    -- local tbl = table.Copy(t)
    local tbl = t:Create()
    -- print(setmetatable(tbl, meta))
    -- print(type(tbl))

    if mantissa == math_huge then
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
    local t = InfNumber(math_exp(1))
    t:pow(x)

    return t
end



print("Break Infinity v"..infmath.Version.." loaded and initialized!")
-- print("Break Infinity MetaTable Type: "..TYPE_BREAKINFINITY)

-- Same as net.WriteTable and net.ReadTable, but with small differences to make it a bit optimized
function net.WriteInfNumber(tbl)
    tbl = ConvertNumberToInfNumber(tbl)

    net.WriteDouble(tbl.mantissa)
    net.WriteDouble(tbl.exponent)
--[[
    net.WriteTable({
        mantissa = tbl.mantissa,
        exponent = tbl.exponent,
    })
]]
end

function net.ReadInfNumber()
    local t = {
        mantissa = net.ReadDouble(),
        exponent = net.ReadDouble(),
    }
    return InfNumber(t.mantissa, t.exponent)
end

local m = FindMetaTable("CTakeDamageInfo")

m.old_SetDamage = m.old_SetDamage or m.SetDamage
m.SetDamage = function(self, tbl)
    self:old_SetDamage(ConvertInfNumberToNormalNumber(tbl))
end

if SERVER then return end
local handler = "BREAKINF.TestIncrement"
concommand.Add("breakinfinity_testincrement_add", function()
    local n = InfNumber(1, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n + n
        print(n:FormatText())
    end)
end)
concommand.Add("breakinfinity_testincrement_mul", function()
    local n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n * n
        print(n:FormatText())
    end)
end)
concommand.Add("breakinfinity_testincrement_pow", function()
    local n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n ^ 3
        print(n:FormatText())
    end)
end)

concommand.Add("breakinfinity_testincrement_stop", function()
    timer.Remove(handler)
end)

concommand.Add("breakinfinity_testincrement_test", function()
    local t = 0
    local test = 0


    t = t + 1
    print("Test "..t..": 1.62e800+6.66e799")
    local test = InfNumber(1.62, 800) + InfNumber(6.66, 799)
    print(test:FormatText())
    
    t = t + 1
    print("Test "..t..": "..MAX_NUMBER_mantissa.."e"..MAX_NUMBER_exponent.."*"..MAX_NUMBER_mantissa.."e"..MAX_NUMBER_exponent)
    local test = InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent)*InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.79e308^30")
    local test = InfNumber(MAX_NUMBER_mantissa, MAX_NUMBER_exponent)^30
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 10^^2")
    local test = InfNumber(4, 2) test:tet(2) -- how do i use this lol
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e800-6.66e799")
    local test = InfNumber(1.62, 800) - InfNumber(6.66, 799)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e800/6.66e799")
    local test = InfNumber(1.62, 800) / InfNumber(6.66, 799)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 1.62e80/6.66e799")
    local test = InfNumber(1.62, 80) / InfNumber(6.66, 799)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 4.20e-69^5")
    local test = InfNumber(4.20, -69) ^ 5
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 4.20e609<1e100")
    local test = InfNumber(4.20, 609) < InfNumber(1, 100)
    print(test)

    t = t + 1
    print("Test "..t..": 4.20e609<1e1000")
    local test = InfNumber(4.20, 609) < InfNumber(1, 1000)
    print(test)
end)
