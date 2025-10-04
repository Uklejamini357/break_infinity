## BREAKING INFINITY IN GMOD! (Go up to beyond 1.79e308!)
### Notice: This is in BETA! This addon may still have bugs.

Ever thought of wondering how you could go further than the 1.79e308 limit on double-float precision numbers? Now there is! With a complex code and...


This addon uses a metatable "BreakInfinity" with 2 values: mantissa and exponent.
- mantissa is generally a number which is used as a multiplier to 10^x
- exponent is technically a "10 powered to exponent" (such as 10^x, 10^308, 10^1000, etc.)


BreakInfinity table also includes functions such as:
- (+) add: add value to the number from another number
- (-) sub: substracts (opposite of add)
- (*) mul: multiply the number by another number
- (/) div: divides the number (opposite of mul)
- (^) pow: powers the number by a specified number
- log10: logarithm of 10, equal to exponent + log10(mantissa)
- log: logarithm of x, equal to (exponent + log10(mantissa)) / log(x)

Other functions:
- (==) eq: checks if mantissa and exponent are equal to the opposing number 
- (<) lt: checks if numbers if lower than the opposing number, checks if log10 of the number is less than the log10 of the opposing number
- (<=) le: Funcions same as eq and lt above, except it returns true from ONE of those functions
- (>): Opposite of (<)
- (>=): Opposite of (<=)



No one has ever made this addon before on this game, might as well as be the first one to be made on gmod lua.
But what if there was Break Eternity in gmod? (1e1.8e308 and beyond, maybe even 10^^308 and up to 10^^1.79e308)

Maybe in the future...

# Other notes:
- THIS ADDON DOES NOTHING BY ITSELF ALONE! (If you feel like it, you can make a nice script with this addon. Options are very limited, though.)
- Tested on gmod with 64-bit binaries. I do not guarantee any functionality on 32-bit gmod!
- The functions specified in "Other functions" list only works if both values are the same (metatable) type! Otherwise ==> Error!

# Support:
- Numbers past 1.79e308: Yes
- Decimals: Partial
- Negative numbers: No


# Inspirations:
- [Antimatter Dimensions](https://ivark.github.io/AntimatterDimensions) by Hevipelle
- [Omega Layers](https://veprogames.github.io/omega-layers) by VeproGames
- [Revolution Idle](https://store.steampowered.com/app/2763740/Revolution_Idle) by Nu Games & Oni Gaming

# Credits:
- @Uklejamini357 - Making the Break Infinity code
- @Toy323 - For helping me with the code along with learning the metatables

