local t = {}
local meta = {}
meta.__index = t
meta.__tostring = function(t)
    return t:FormatText()
end

--[[
meta.__newindex = function(self, key, value)
    rawset(self, key, value)
end
]]

-- global
infmath = {}
infmath.Version = "0.9"
infmath.usenotation = "scientific"
--[[ Valid notations:
scientific
infinity
]]
infmath.useexponentnotationtype = 1
--[[valid exponent notation types:
1 - "e[exponent]"
2 - "ee[log10(exponent)]"
]]

local istable = istable
local isnumber = isnumber
function isinfnumber(t)
    return tobool(istable(t) and isnumber(t.mantissa) and isnumber(t.exponent))
end

-- Cache values in locals for faster code execution
local infmath = infmath
local math = math

local math_floor = math.floor
local math_Round = math.Round
local math_ceil = math.ceil
local math_Clamp = math.Clamp
local math_IsNearlyEqual = math.IsNearlyEqual
local math_log10 = math.log10
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_exp = math.exp
local math_huge = math.huge
local tonumber = tonumber
local isinfnumber = isinfnumber

MAX_NUMBER = 1.7976931348623e308
local MAX_NUMBER = MAX_NUMBER
local MAX_NUMBER_mantissa = 1.7976931348623
local MAX_NUMBER_exponent = 308

infmath.MAX_NUMBER = MAX_NUMBER
infmath.MAX_NUMBER_mantissa = MAX_NUMBER_mantissa
infmath.MAX_NUMBER_exponent = MAX_NUMBER_exponent

if not math.Clamp then
    function math.Clamp(_in, low, high)
    	return math_min(math_max(_in, low), high)
    end
    math_Clamp = math.Clamp
end

if not math.Round then
    function math.Round(num, idp)
	    local mult = 10 ^ (idp or 0)
	    return math_floor(num * mult + 0.5) / mult
    end
    math_Round = math.Round
end

if not istable then
    function istable(var)
        return type(var) == "table"
    end
end

if not isnumber then
    function isnumber(var)
        return type(var) == "number"
    end
end

if not tobool then
    function tobool(var)
        return var and true or false
    end
end


-- infmath
function infmath.ConvertNumberToInfNumber(number)
    if isinfnumber(number) then return InfNumber(number.mantissa, number.exponent) end
    return InfNumber(number)
end

function infmath.ConvertInfNumberToNormalNumber(tbl) -- temp fix for the pow functions
    if isnumber(tbl) then return tbl end
    return tbl.mantissa * 10^tbl.exponent
end

-- Placeholder values
t.mantissa = 0
t.exponent = 0
-- t.layers = 0 -- Break eternity when?

local ConvertNumberToInfNumber = infmath.ConvertNumberToInfNumber
local ConvertInfNumberToNormalNumber = infmath.ConvertInfNumberToNormalNumber

local function FixMantissa(self) -- Just in case.
    if not isinfnumber(self) then return end

    local negative = self.mantissa < 0
    local m = math_abs(self.mantissa)
    if m == math_huge then
        m = MAX_NUMBER_mantissa
        self.exponent = self.exponent + MAX_NUMBER_exponent
    elseif m == 0 then
        self.exponent = 0
    elseif m >= 10 or m < 1 then
        local e = math_floor(math_log10(m))
        m = m / (10^e)
        self.exponent = self.exponent + e
    end
    self.mantissa = m*(negative and -1 or 1)

    return self
end

local function FixExponent(self) -- Just in case.
    if not isinfnumber(self) then return end

    if self.exponent ~= math_floor(self.exponent) then
        self.mantissa = self.mantissa * 10^(self.exponent - math_floor(self.exponent))
        self.exponent = self.exponent - (self.exponent - math_floor(self.exponent))
    end

    return self
end

local function FixMantissaExponent(self)
    FixMantissa(self)
    FixExponent(self)

    return self
end

t.log = function(self, x)
    return (math_log10(self.mantissa) + self.exponent) / math_log10(x)
end
t.log10 = function(self)
    return math_log10(self.mantissa) + self.exponent
end
t.FormatText = function(self, roundto)
    local e = self.exponent
    local abs_e = e
    if e == -math_huge then return "0" end
    if e == math_huge then return "inf" end
    local e_negative = e < 0
    if e_negative then
        abs_e = math_abs(abs_e)
    end

    if infmath.usenotation == "scientific" then
        if e > -2 and e < 9 then return math_Round(self.mantissa * 10^e, 7) end -- Normal numbers
        local round = roundto or math_min(3, 8-math_floor(math_log10(abs_e)))

        return (round >= 0 and self.mantissa or "").."e"..(
        infmath.useexponentnotationtype == 2 and (e_negative and "-" or "")..(abs_e >= 1e9 and "e"..math_Round(math_log10(abs_e), 2) or abs_e) or
        (e_negative and "-" or "")..(abs_e >= 1e9 and math_Round(abs_e * 10^-math_floor(math_log10(abs_e)), 3).."e"..math_floor(math_log10(abs_e)) or abs_e))    
    elseif infmath.usenotation == "infinity" then
        return math_Round(self:log10() / 308.25471555992, math_min(4, 10-math_log10(math_max(1, abs_e)))).."∞"
    end

    return "NaN"
end
meta.FormatText = t.FormatText

t.DefaultFormat = function(self, roundto) -- Best use for data saving as string!
    local e = self.exponent
    local e_negative = e < 0

    if e > -5 and e < 14 then return self.mantissa * 10^e end
    -- local round = math_floor(math_log10(e))

    return self.mantissa.."e"..(
    --(e_negative and "-" or "")..
    (math_abs(e) >= 1e9 and e * 10^-math_floor(math_log10(math_abs(e))).."e"..math_floor(math_log10(math_abs(e))) or e))
end
meta.DefaultFormat = t.DefaultFormat

t.add = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)
    if tbl.mantissa == 0 then return self end


    local a = 10^math_Clamp(self.exponent-tbl.exponent, -300, 300)
    self.mantissa = self.mantissa == 0 and tbl.mantissa or (self.mantissa + tbl.mantissa/a)
    FixMantissa(self)
    if self.exponent == -math_huge then return self end
    self.exponent = math_max(self.exponent, tbl.exponent)
    FixExponent(self)
    return self
end
meta.__add = t.add

t.sub = function(self, tbl)
    self = ConvertNumberToInfNumber(self)
    tbl = ConvertNumberToInfNumber(tbl)
    if tbl.mantissa == 0 then return self end


    local a = 10^math_Clamp(self.exponent-tbl.exponent, -300, 300)
    self.mantissa = self.mantissa == 0 and -tbl.mantissa or (self.mantissa - tbl.mantissa/a)
    FixMantissa(self)
    if self.exponent == -math_huge then return self end
    
    self.exponent = math_max(self.exponent, tbl.exponent)
    if self.mantissa == tbl.mantissa and self.expontnt == tbl.exponent then self.exponent = 0 end
    FixExponent(self)
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
    -- local power = math_log10(m) * n

    self.mantissa = 1--10^(power-math_floor(power))
    -- local log_value = math_log10(m) + e
    self.exponent = (math_log10(m) + e)*n

    FixMantissaExponent(self)

    return self
end
meta.__pow = t.pow

-- Tetration
t.tet = function(self, number)
    local original_number = ConvertInfNumberToNormalNumber(self)
    for i=1,math_ceil(math_min(number-1, 100)) do
        -- local c = math_min(1, number-i)
        local c = math_min(1, (0.1+(number-i)*0.9))
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

-- Repeatedly calling this function multiple times may impact the performance. (I think.)
function InfNumber(mantissa, exponent)
    local negative = mantissa < 0

    mantissa = math_abs(mantissa or 0)
    exponent = exponent or 0

    local tbl = t:Create()
    if mantissa == math_huge then
        mantissa = MAX_NUMBER_mantissa
        exponent = exponent + MAX_NUMBER_exponent
    elseif mantissa == 0 then
        mantissa = 0
        exponent = 0
    elseif mantissa >= 10 or mantissa < 1 then
        local e = math_floor(math_log10(mantissa))
        mantissa = mantissa / (10^e)
        exponent = exponent + e
    end

    tbl.mantissa = mantissa*(negative and -1 or 1)
    tbl.exponent = exponent

    return tbl
end

function ConvertStringToInfNumber(str)
    local t = string.Explode("e", str)
    local mantissa = tonumber(t[1]) or 1
    local exponent = tonumber(t[2] == "" and 10^t[3] or 10^(t[3] or 0) * (t[2] or 0))

    return InfNumber(mantissa, exponent)
end

infmath.FormatText = t.FormatText

infmath.exp = function(x)
    local t = InfNumber(math_exp(1))
    t = t ^ x

    return t
end

infmath.abs = function(self)
    return InfNumber(math_abs(self.mantissa), self.exponent)
end

infmath.floor = function(self)
    if not isinfnumber(self) then return math_floor(self) end
    local e = 10^math.Clamp(self.exponent, -50, 50)
    local m = math_floor(self.mantissa*e)/e

    return InfNumber(m, self.exponent)
end

infmath.ceil = function(self)
    if not isinfnumber(self) then return math_ceil(self) end
    local e = 10^math.Clamp(self.exponent, -50, 50)
    local m = math_ceil(self.mantissa*e)/e

    return InfNumber(m, self.exponent)
end

print("Break Infinity v"..infmath.Version.." loaded and initialized!")

infmath.Round = function(self, round)
    if not isinfnumber(self) then return math_Round(self, round) end
    return InfNumber(math_Round(self.mantissa, math_Clamp(self.exponent+(round or 0),-50,50)), self.exponent)
end

infmath.min = function(...)
    local m = {}
    for k,v in pairs({...}) do
        table.insert(m, isinfnumber(v) and v:log10() or math.log10(v))
    end
    return InfNumber(1, math_min(unpack(m)))
end

infmath.max = function(...)
    local m = {}
    for k,v in pairs({...}) do
        table.insert(m, isinfnumber(v) and v:log10() or math.log10(v))
    end
    return InfNumber(1, math_max(unpack(m)))
end

infmath.Clamp = function(...)
    local m = {}
    for k,v in pairs({...}) do
        table.insert(m, isinfnumber(v) and v:log10() or math.log10(v))
    end
    return InfNumber(1, math_max(math_min(unpack(m))))
end



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
    local t = {}
    t.mantissa = net.ReadDouble()
    t.exponent = net.ReadDouble()

    return InfNumber(t.mantissa, t.exponent)
  end
end

if FindMetaTable then
  local m = FindMetaTable("CTakeDamageInfo")
  if m then
    m.old_SetDamage = m.old_SetDamage or m.SetDamage
    m.SetDamage = function(self, tbl)
      self:old_SetDamage(ConvertInfNumberToNormalNumber(tbl))
    end
  end
end

if SERVER or not concommand then return end
local handler = "BREAKINF.TestIncrement"
local n
concommand.Add("breakinfinity_testincrement_tet", function(_, _, args)
end)

concommand.Add("breakinfinity_testincrement_stop", function()
    timer.Remove(handler)
end)

concommand.Add("breakinfinity_testincrement_increase", function(_, _, args)
end)


concommand.Add("breakinfinity_test", function(_,_,args)
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
    local test = InfNumber(1, 1)
    print(test:tet(2):FormatText())

    t = t + 1
    print("Test "..t..": 10^^3")
    local test = InfNumber(1, 1)
    print(test:tet(3):FormatText())

    t = t + 1
    print("Test "..t..": 10^^4")
    local test = InfNumber(1, 1)
    print(test:tet(4):FormatText())

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
    print("Test "..t..": 4.20e-69^10")
    local test = InfNumber(4.20, -69) ^ 10
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

concommand.Add("breakinfinity_increment_test", function(_,_,args)
    local str = args[1]
    if str == "add" then
        n = InfNumber(1, 0)
        print(n:FormatText())
        timer.Create(handler, 0, 0, function()
            n = n + (n/3)
            print(n:FormatText())
            if n.exponent == math_huge then timer.Remove(handler) end
        end)
    elseif str == "mul" then
        n = InfNumber(2, 0)
        print(n:FormatText())
        timer.Create(handler, 0, 0, function()
            n = n * n
            print(n:FormatText())
            if n.exponent == math_huge then timer.Remove(handler) end
        end)
    elseif str == "pow" then
        n = InfNumber(2, 0)
        print(n:FormatText())
        timer.Create(handler, 0, 0, function()
            n = n ^ (tonumber(args[1]) or 2)
            print(n:FormatText())
            if n.exponent == math_huge then timer.Remove(handler) end
        end)
    elseif str == "tetration" then
        n = InfNumber(2, 0)
        print(n:FormatText())
        timer.Create(handler, 0, 0, function()
            n:tet(tonumber(args[1]) or 2)
            print(n:FormatText())
            if n.exponent == math_huge then timer.Remove(handler) end
        end)
    elseif str == "increase" then
        n = InfNumber(1, 0)

        print(n:FormatText())
        timer.Create(handler, 0, 0, function()
            n = ((n*n)^2)+1
            print(n:FormatText())
            if n.exponent == math_huge then timer.Remove(handler) end
        end)
    end
end)
