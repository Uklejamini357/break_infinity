local t = {}
local meta = {}
meta.__index = t

infmath = {}
infmath.Version = "0.5"
infmath.pow_useloop = CreateConVar("infmath_pow_useloop", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use the loops for power function to determine a more precise? Warning: Has a significant impact on performance."):GetBool()
cvars.AddChangeCallback("infmath_pow_useloop", function(cvar, old, new)
    infmath.pow_useloop = tobool(new)
end, "infmath_pow_useloop")

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

    local n = ConvertInfNumberToNormalNumber(tbl)
    local m, e = self.mantissa, self.exponent
    local infmath_pow_useloop = infmath.pow_useloop

    if infmath_pow_useloop then
        -- Expensive loop. But couldn't help it *shrug*
        for i=1,math_min(n, 1e6),308 do
            if math.IsNearlyEqual(self.mantissa, 1) then break end
            self.mantissa = self.mantissa * (m ^ math.min(308, n-i))
            FixMantissaExponent(self)
        end

        self.exponent = (self.exponent-e) + e*n
    else
        self.mantissa = self.mantissa ^ n
        self.exponent = (self.exponent)*n
    end

    FixMantissaExponent(self)

    return self
end
meta.__pow = t.pow

t.tet = function(self, number) -- Tetration (normal numbers! far more complicated than pow function)
    local original_number = ConvertInfNumberToNormalNumber(self)
    for i=1,math_ceil(math_min(number-1, 100)) do
        local c = math.min(1, 0.1+(number-i)*0.9)
        local calc_ognumber = ConvertNumberToInfNumber(original_number)

        local a = (self^c)
        self = calc_ognumber^a
        -- self = a^calc_ognumber

        FixMantissaExponent(self)
        if self.exponent == math_huge then break end
    end

    return self
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

-- RegisterMetaTable("InfNumber", t) -- i don't know how to use this
-- local meta = FindMetaTable("InfNumber")
-- TYPE_INFNUMBER = meta.MetaID

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
-- print("Break Infinity MetaTable Type: "..TYPE_INFNUMBER)

if net then
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
end

local m = FindMetaTable("CTakeDamageInfo")
if m then
    m.old_SetDamage = m.old_SetDamage or m.SetDamage
    m.SetDamage = function(self, tbl)
        self:old_SetDamage(ConvertInfNumberToNormalNumber(tbl))
    end
end

if SERVER then return end
local handler = "BREAKINF.TestIncrement"
local n
concommand.Add("breakinfinity_testincrement_add", function()
    n = InfNumber(1, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n + n
        print(n:FormatText())
        if n.exponent == math_huge then timer.Remove(handler) end
    end)
end)
concommand.Add("breakinfinity_testincrement_mul", function()
    n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n * n
        print(n:FormatText())
        if n.exponent == math_huge then timer.Remove(handler) end
    end)
end)
concommand.Add("breakinfinity_testincrement_pow", function(_, _, args)
    n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = n ^ (tonumber(args[1]) or 2)
        print(n:FormatText())
        if n.exponent == math_huge then timer.Remove(handler) end
    end)
end)
concommand.Add("breakinfinity_testincrement_tet", function(_, _, args)
    n = InfNumber(2, 0)
    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n:tet(tonumber(args[1]) or 2)
        print(n:FormatText())
        if n.exponent == math_huge then timer.Remove(handler) end
    end)
end)

concommand.Add("breakinfinity_testincrement_stop", function()
    timer.Remove(handler)
end)

concommand.Add("breakinfinity_testincrement_increase", function(_, _, args)
    n = InfNumber(1, 0)

    print(n:FormatText())
    timer.Create(handler, 0, 0, function()
        n = ((n*n)^2)+1
        print(n:FormatText())
        if n.exponent == math_huge then timer.Remove(handler) end
    end)
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
    local test = InfNumber(1, 1) test:tet(2) -- how do i use this lol
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 10^^3")
    local test = InfNumber(1, 1) test:tet(3)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 10^^4")
    local test = InfNumber(1, 1) test:tet(4)
    print(test:FormatText())

    t = t + 1
    print("Test "..t..": 256^256")
    local test = InfNumber(2.56, 2)
    print((test^test):FormatText())

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
