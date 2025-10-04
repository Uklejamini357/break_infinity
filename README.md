# BREAKING INFINITY IN GMOD! (Go up to beyond 1.79e308!)

Ever thought of wondering how you could go further than the 1.79e308 limit on double-float precision numbers?
Now there is! With a highly complex code...


This addon uses a metatable "BreakInfinity" with 2 values: mantissa, exponent
mantissa is generally a number which is used as a multiplier to 10^x
exponent is technically a "10 powered to exponent" (such as 10^x, 10^308, 10^1000, etc.)


BreakInfinity table also includes functions such as:
- add: add value to the number from another number
- sub: substracts (opposite of add)
- mul: multiply the number by another number
- div: divides the number (opposite of mul)
- pow: powers the number by a specified number (mantissa^mantissa, exponent * exponent)
- log10: logarithm of 10, equal to exponent + log10(mantissa)
- log: logarithm of x, equal to (exponent + log10(mantissa)) / log(x)


No one has ever made this addon before on this game, might as well as be the first one to be made on gmod lua
But what if there was Break Eternity in gmod? (1e1.8e308 and beyond, maybe even 10^^308 and up to 10^^1.79e308)

# Other notes:
- NOTE THAT THIS ADDON DOES NOTHING BY ITSELF ALONE! (If you feel like it, you can make a nice script with this addon.)
- Plus, I don't care if you reupload the addon or if you include it in a gamemode. My code from this addon can be reuploaded, modified etc.
- Tested on gmod with 64-bit binaries. I do not guarantee any functionality on 32-bit gmod!


# Support:
- Numbers past 1.79e308: Yes
- Decimals: Partial
- Negative numbers: No


# Inspirations:
- Antimatter Dimensions (https://ivark.github.io/AntimatterDimensions)
- Omega Layers (https://veprogames.github.io/omega-layers)
- Revolution Idle (https://store.steampowered.com/app/2763740/Revolution_Idle)
