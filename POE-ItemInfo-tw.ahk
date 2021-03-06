﻿; Path of Exile Item Info Tooltip
;
; Version: 1.7.5 (hazydoc / IGN:Sadou)
;
; This script was originally based on the POE_iLVL_DPS-Revealer script (v1.2d) found here:
; https://www.pathofexile.com/forum/view-thread/594346
;
; Changes to the POE_iLVL_DPS-Revealer script as recent as it's version 1.4.1 have been 
; brought over. Thank you Nipper4369 and Kislorod!
;
; The script has been added to substantially to enable the following features in addition to 
; itemlevel and weapon DPS reveal:
;
;   - show total affix statistic for rare items
;   - show possible min-max ranges for all affixes on rare items
;   - reveal the combination of difficult compound affixes (you might be surprised what you find)
;   - show affix ranges for uniques
;   - show map info (thank you, Kislorod and Necrolis)
;   - show max socket info (thank you, Necrolis)
;   - has the ability to convert currency items to chaos orbs (you can adjust the rates by editing
;     <datadir>\CurrencyRates.txt)
;   - can show which gems are valuable and/or drop-only (all user adjustable)
;   - can show a reminder for uniques that are generally considered valuable (user adjustable as well)
;   - adds a system tray icon and proper system tray description tooltip
;
; All of these features are user-adjustable by using a "database" of text files which come 
; with the script and are easy to edit by non developers. See header comments in those files
; for format infos and data sources.
;
; Known issues:
;     
;     Even though there have been tons of tests made on composite affix combinations, I expect
;     there to be edge cases still that may return an invalid or not found affix bracket.
;     You can see these entries in the affix detail lines if they have the text "n/a" (not available)
;     somewhere in them or if you see an empty range " - *". The star by the way marks ranges
;     that have been added together for a guessed attempt as to the composition of a possible 
;     compound affix. If you see this star, take a closer look for a moment to check if the 
;     projection is correct. I expect these edge cases to be properly dealt with over time as the
;     script matures. For now I'd estimate that at least 80% of the truly hard cases are correctly 
;     identified.
;
;     Some background info: because the game concatenates values from multiple affix sources into
;     one final entry on the ingame tooltip there is no reliable way to work backwards from the 
;     composite value to each individual part. For example, Stun Recovery can be added as suffix if 
;     it contributes alone, but can also be a prefix if it is a composite of Stun Recovery and
;     Evasion Rating (or others). Because there is one final entry, while prefix and suffix can
;     appear at the same time and will be added together, you can't reliably reverse engineer which 
;     affix contributed what part of the composite value. This is akin to taking a random source of
;     numbers, adding them up to one value and then asking someone to work out backwards what the 
;     original source values were.
;     Similarily, in cases like boosted Stun Recovery (1) and Evasion Rating (2) on an item in difficult
;     cases there is no 100% reliable way to tell if the prefix "+ Evasion Rating / Block and Stun Recovery" 
;     contributed to both stats at once or if the suffix "+ Block and Stun Recovery" contributed to (1) 
;     and the prefix "+ Evasion Rating" cotributed to (2) or possibly a combination of both. 
;     Often it is possible to make guesses by working your way backwards from both partial affixes, by
;     looking at the affix bracket ranges and the item level to see what is even possible to be there and
;     what isn't. In the worst case for a double compound affix, all four ranges will be possible to be
;     combined.
;
;     I have tested the tooltip on many, many items in game from my own stash and from trade chat
;     and I can say that in the overwhelming majority of cases the tooltip does indeed work correctly.
;
;     IMPORTANT: as you may know, the total amount of affixes (w/o implicit mods) can be 6, of which
;     3 at most are prefixes and likewise 3 at most are suffixes. Be especially weary, then of cases
;     where this prefix/suffix limit is overcapped. It may happen that the tooltip shows 4 suffixes,
;     and 3 prefixes total. In this case the most likely explanation is that the script failed to properly
;     determine composite affixes. Composite affixes ("Comp. Prefix" or "Comp. Suffix" in the tooltip)
;     are two affix lines on the ingame tooltip that together form one single composite affix. 
;     Edit v1.4: This hasn't happened for a longer time now, but I am leaving this important note in
;     so end users stay vigilant (assuming anyone even reads this wall of text :)).
;
;   - I do not know which affixes are affected by +% Item Quality. Currently I have functions in place 
;     that can boost a range or a single value to adjust for Item Quality but currently these aren't used
;     much. Partially this is also because it is not easy to tell if out-of-bounds cases are the result
;     of faulty input data (I initially pulled data from the PoE mods compendium but later made the PoE
;     homepage the authoritative source overruling data from other sources) or of other unreckognized and
;     unhandled entities or systems.
;
; Todo:
;
;   - handle ranges for implicit mods
;
; Notes:
;
;   - Global values marked with an inline comment "d" are globals for debugging so they can be easily 
;     (re-)enabled using global search and replace. Marking variables as global means they will show 
;     up in AHK's Variables and contents view of the script.
;   
; Needs AutoHotKey v1.0.45 or later
;
; Original credits:
;
;   mcpower - for the base iLVL display of the script 5months ago before Immo.
;   Immo - for the base iLVL display of the script.(Which was taken from mcpower.)
;   olop4444 - for helping me figure out the calculations for Q20 items.
;   Aeons - for a rewrite and fancy tooltips.
;   kongyuyu - for base item level display.
;   Fayted - for testing the script.
;
; Original author's comment:
;
; If you have any questions or comments please post them there as well. If you think you can help
; improve this project. I am looking for contributors. So Pm me if you think you can help.
;
; If you have a issue please post what version you are using.
; Reason being is that something that might be a issue might already be fixed.
;

; Run test suites (see end of script)
; Note: don't set this to true for normal every day use...
; This is just for fellow developers.
;
; Chinese Language Author: Dken
; https://github.com/dkentw/POEiteminfo-TW
;
RunTests := False

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
StringCaseSense, On ; Match strings with case.

; OPTIONS

OnlyActiveIfPOEIsFront = 0      ; Set to 1 to make it so the script does nothing if Path of Exile window isn't the frontmost.
                                ; If 0, the script also works if PoE isn't frontmost. This is handy for have the script parse
                                ; textual item representations appearing somewhere else, like in the forums or text files. 

ShowItemLevel = 1               ; Show item level and the item type's base level (enabled by default change to 0 to disable)
ShowMaxSockets = 1              ; Show the max sockets based on ilvl and type
ShowDamageCalculations = 1      ; Show damage projections (for weapons only)

ShowAffixTotals  = 1            ; Show total affix statistics
ShowAffixDetails = 1            ; Show detailed info about affixes
ShowAffixLevel = 0              ; Show item level of the affix 
ShowAffixBracket = 1            ; Show range for the affix' bracket as is on the item
ShowAffixMaxPossible = 1        ; Show max possible bracket for an affix based on the item's item level
ShowAffixBracketTier = 1        ; Show a T# indicator of the tier the affix bracket is in. 
                                ; T1 being the highest possible, T2 second-to-highest and so on

TierRelativeToItemLevel = 0     ; When determining the affix bracket tier, take item level into consideration.
                                ; However, this also means that the lower the item level the less the diversity
                                ; of possible affix tiers since there aren't as many possibilities. This will 
                                ; give the illusion that a low level item might be really, really good when it 
                                ; has all T1 but in reality it can only have T1 since it's item level is so low
                                ; it can only ever take the first bracket. 
                                ; 
                                ; If this option is set to 0, the tiers will always display relative to the full
                                ; range of tiers available, ignoring the item level.

ShowCurrencyValueInChaos = 1    ; Convert the value of currency items into chaos orbs. 
                                ; This is based on the rates defined in <datadir>\CurrencyRates.txt
                                ; You should edit this file with the current currency rates.

ShowUniqueEvaluation = 1        ; Display reminder when a unique is valuable. 
                                ; This is based on <datadir>\ValuableUniques.txt
                                ; You can edit this file to suit your own needs.

ShowGemEvaluation = 1           ; Display reminder when a gem is valuable and/or drop only. 
                                ; This is based on <datadir>\ValuableGems.txt and <datadir>\DropOnlyGems.txt
                                ; You can edit these files to suit your own needs.

GemQualityValueThreshold = 10   ; If the gem's added quality exceeds this value, consider it valuable regardless of which gem it is.

MaxSpanStartingFromFirst = 1    ; When showing max possible, don't just show the highest possible affix bracket 
                                ; but construct a pseudo range which spans the lower bound of the lowest possible 
                                ; bracket to the upper bound of the highest possible one. 
                                ;
                                ; This is usually what you want to see when evaluating an item's worth. The exception 
                                ; being when you want to reroll an affix to the highest possible value within it's
                                ; current bracket - then you need to see the affix range that is actually on the item 
                                ; right now.

CompactDoubleRanges = 1         ; Show double ranges as "1-172" instead of "1-8 to 160-172"
CompactAffixTypes = 1           ; Use compact affix type designations: Suffix = S, Prefix = P, Comp. Suffix = CS, Comp. Prefix = CP

MarkHighLinksAsValuable = 1    ; Mark rares or uniques with 5L or 6L as valuable.

MirrorAffixLines = 1            ; Show a copy of the affix line in question when showing affix details. 
                                ;
                                ; For example, would display "Prefix, 5-250" instead of "+246 to Accuracy Rating, Prefix, 5-250". 
                                ; Since the affixes are processed in order one can attribute which is which to the ordering of 
                                ; the lines in the tooltip to the item data in game.

MirrorLineFieldWidth = 18       ; Mirrored affix line width. Set to a number above 0 to truncate (or pad) to this many characters. 
                                ; Appends AffixDetailEllipsis when truncating.
ValueRangeFieldWidth = 7        ; Width of field that displays the affix' value range(s). Set to a number larger than 0 to truncate (or pad) to this many characters. 
                                ;
                                ; Keep in mind that there are sometimes double ranges to be displayed. Like for example on an axe, implicit physical damage might
                                ; have a lower bound range and a upper bound range. In this case the lower bound range can have at most a 3 digit minimum value,
                                ; and at most a 3 digit maximum value. To then display just the lower bound (which constitutes one value range field), you would need
                                ; at least 7 characters (ex: 132-179). To complete the example here is how it would look like with 2 fields (lower and upper bound)
                                ; 132-179 168-189. Note that you don't need to set 15 as option value to display both fields correctly. As the name implies the option
                                ; is per field, so a value of 8 can display two 8 character wide fields correctly.

AffixDetailDelimiter := " "     ; Field delimiter for affix detail lines. This is put between value range fields. If this value were set to a comma, the above
                                ; double range example would become 132-179,168-189.

AffixDetailEllipsis := "…"      ; If the MirrorLineFieldWidth is set to a value that is smaller than the actual length of the affix line text
                                ; the affix line will be cut off and this text will be appended at the end to indicate tha the line was truncated.
                                ;
                                ; Usually this is set to the ASCII or Unicode value of the three dot ellipsis (alt code: 0133).
                                ; Note that the correct display of text characters outside the ASCII standard depend on the file encoding and the 
                                ; AHK version used. For best results, save this file as ANSI encoding which can be read and displayed correctly by
                                ; either ANSI based AutoHotkey or Unicode based AutoHotkey.
                                ;
                                ; Example: assume the affix line to be mirrored is '+#% increased Spell Damage'.
                                ; If the MirrorLineFieldWidth is set to 18, this field would be shown as '+#% increased Spel…'

PutResultsOnClipboard = 0       ; Put result text on clipboard (overwriting the textual representation the game put there to begin with)

; Pixels mouse must move to auto-dismiss tooltip
MouseMoveThreshold := 40

; Set this to 1 if you want to have the tooltip disappear after the time frame set below.
; Otherwise you will have to move the mouse by 5 pixels for the tip to disappear.
UseTooltipTimeout = 0

;How many ticks to wait before removing tooltip. 1 tick = 100ms. Example, 50 ticks = 5secends, 75 Ticks = 7.5Secends
ToolTipTimeoutTicks := 150

; Font size for the tooltip, leave empty for default
FontSize := 11

; OPTIONS END

; Menu tooltip
Menu, tray, Tip, Path of Exile Item Info 1.7.5

; Windows system tray icon
; possible values: poe.ico, poe-bw.ico, poe-web.ico, info.ico
Menu, tray, Icon, data\poe-bw.ico
 
If (A_AhkVersion <= "1.0.45")
{
    msgbox, You need AutoHotkey v1.0.45 or later to run this script. `n`nPlease go to http://ahkscript.org/download and download a recent version.
    exit
}

IfNotExist, %A_ScriptDir%\data
{
    msgbox, Error 37`n`n"data" directory not found at "%A_ScriptDir%".`n`nPlease make sure the data directory is present at the same location where you are executing the script from.
    exit
}

#Include %A_ScriptDir%\data\MapList.txt

MsgUnhandled := "Unhandled case. Please report the item that you are inspecting by pasting the textual item representation that is on your clipboard right now into a reply to the script's forum thread at http://www.pathofexile.com/forum/view-thread/790438.`n`nThanks so much for helping out!"

; Create font for later use
FixedFont := CreateFont()
 
; Creates a font for later use
CreateFont()
{
    Global FontSize
    Options :=
    If (!(FontSize = "")) 
    {
        Options = s%FontSize%
    }
    Gui Font, %Options%, Courier New
    Gui Font, %Options%, Consolas
    Gui Add, Text, HwndHidden, 
    SendMessage, 0x31,,,, ahk_id %Hidden%
    return ErrorLevel
}
 
; Sets the font for a created ahk tooltip
SetFont(Font)
{
    SendMessage, 0x30, Font, 1,, ahk_class tooltips_class32 ahk_exe autohotkey.exe
}
 
ParseElementalDamage(String, DmgType, ByRef DmgLo, ByRef DmgHi)
{
    IfInString, String, %DmgType%傷害 
    {
        IfInString, String, 轉換 or IfInString, String, 承受
            return
        IfNotInString, String, 增加
        {
            StringSplit, Arr, String, %A_Space%
            StringSplit, Arr, Arr2, -
            DmgLo := Arr1
            DmgHi := Arr2
        }
    }
}

; Function that checks item type name against entries 
; from ItemList.txt to get the item's base level
; Added by kongyuyu, changed by hazydoc
CheckBaseLevel(ItemTypeName)
{
    ItemListArray = 0
    Loop, Read, %A_WorkingDir%\data\ItemList.txt 
    {  
        ; This loop retrieves each line from the file, one at a time.
        ItemListArray += 1  ; Keep track of how many items are in the array.
        StringSplit, NameLevel, A_LoopReadLine, |,
        Array%ItemListArray%1 := NameLevel1  ; Store this line in the next array element.
        Array%ItemListArray%2 := NameLevel2
    }

    Loop %ItemListArray% {
        element := Array%A_Index%1
        If(ItemTypeName == element) 
        {
            BaseLevel := Array%A_Index%2
            Break
        }
    }
    return BaseLevel
}

CheckRarityLevel(RarityString)
{
    IfInString, RarityString, Normal
        return 1
    IfInString, RarityString, Magic
        return 2
    IfInString, RarityString, Rare
        return 3
    IfInString, RarityString, Unique
        return 4
    return 0 ; unknown rarity. shouldn't happen!
}

ParseItemType(ItemDataStats, ItemDataNamePlate, ByRef BaseType, ByRef SubType, ByRef GripType)
{
    ; Grip type only matters for weapons at this point. For all others it will be 'None'.
    GripType = None

    ; Check stats section first as weapons usually have their sub type as first line
    Loop, Parse, ItemDataStats, `n, `r
    {
        IfInString, A_LoopField, 單手斧
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 雙手斧
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 2H
            return
        }
        IfInString, A_LoopField, 單手錘
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 雙手錘
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 2H
            return
        }
        IfInString, A_LoopField, 權杖
        {
            BaseType = Weapon
            SubType = Sceptre
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 長杖
        {
            BaseType = Weapon
            SubType = Staff
            GripType = 2H
            return
        }
        IfInString, A_LoopField, 單手劍
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 雙手劍
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 2H
            return
        }
        IfInString, A_LoopField, 匕首
        {
            BaseType = Weapon
            SubType = Dagger
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 爪
        {
            BaseType = Weapon
            SubType = Claw
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 弓
        {
            ; Not really sure if I should classify bow as 2H (because that would make sense)
            ; but you can equip a quiver in 2nd hand slot, so it could be 1H?
            BaseType = Weapon
            SubType = Bow
            GripType = 1H
            return
        }
        IfInString, A_LoopField, 法杖
        {
            BaseType = Weapon
            SubType = Wand
            GripType = 1H
            return
        }
    }

	; Check name plate section 
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        ; a few cases that cause incorrect id later
        ; and thus should come first
        ; Note: still need to work on proper id for 
        ; all armour types.
        IfInString, A_LoopField, 環甲
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
        IfInString, A_LoopField, 外套
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
        IfInString, A_LoopField, 鎧
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
		IfInString, A_LoopField, 甲
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
		IfInString, A_LoopField, 衣
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
		IfInString, A_LoopField, 裝
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
		IfInString, A_LoopField, 外套
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }

        ; Belts, Amulets, Rings, Quivers, Flasks
        IfInString, A_LoopField, Rustic Sash
        {
            BaseType = Item
            SubType = Belt
            return
        }
        IfInString, A_LoopField, 腰帶
        {
            BaseType = Item
            SubType = Belt
            return
        }
        IfInString, A_LoopField, 護身符
        {
            BaseType = Item
            SubType = Amulet
            return
        }
        IfInString, A_LoopField, 戒指
        {
            BaseType = Item
            SubType = Ring
            return
        }
        IfInString, A_LoopField, 箭袋
        {
            BaseType = Item
            SubType = Quiver
            return
        }
        IfInString, A_LoopField, 藥劑
        {
            BaseType = Item
            SubType = Flask
            return
        }
        IfInString, A_LoopField, %A_Space%Map
        {
            BaseType = Map		
			global matchList
			Loop % matchList.MaxIndex()
			{
				Match := matchList[A_Index]
				IfInString, A_LoopField, %Match%
				{
					SubType = %Match%
					return
				}
			}
			
			SubType = Unknown%A_Space%Map
            return
        }
        ; Dry Peninsula fix
        IfInString, A_LoopField, Dry%A_Space%Peninsula
        {
            BaseType = Map
            SubType = Dry%A_Space%Peninsula
            return
        }		

        ; Shields 
        IfInString, A_LoopField, 盾
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Buckler
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Bundle
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Gloves
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        IfInString, A_LoopField, Mitts
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        IfInString, A_LoopField, Gauntlets
        {
            BaseType = Armour
            SubType = Gloves
            return
        }

        ; Helmets
        IfInString, A_LoopField, 盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        If (InStr(A_LoopField, "帽") AND (Not InStr(A_LoopField, "Hate")))
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 面
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 兜
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 熊首皮盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 獅首皮盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 冠
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 護盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 堅盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 戰盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 巨盔
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 籠
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, 三角帽
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
		
		; Boots
        IfInString, A_LoopField, 靴
        {
            BaseType = Armour
            SubType = Boots
            return
        }
        IfInString, A_LoopField, 脛甲
        {
            BaseType = Armour
            SubType = Boots
            return
        }	
        IfInString, A_LoopField, 鞋 
        {
            BaseType = Armour
            SubType = Boots
            return
        }					
    }

    ; TODO: need a reliable way to determine sub type for armour
    ; right now it's just determine anything else first if it's
    ; not that, it's armour.
    BaseType = Armour
    SubType = Armour
}

GetClipboardContents(DropNewlines = False)
{
    Result =
    If Not DropNewlines
    {
        Loop, Parse, Clipboard, `n, `r
        {
            Result := Result . A_LoopField . "`r`n"
			Result2 := A_LoopField
        }
		
    }
    Else
    {   
        Loop, Parse, Clipboard, `n, `r
        {
            Result := Result . A_LoopField
        }
    }
    return Result
}

SetClipboardContents(String)
{
    Clipboard := String
}

; attempted to create a nice re-usable function for all the string splitting
; doesn't work correctly yet!
SplitString(StrInput, StrDelimiter)
{
    TempDelim := "``"
    StringReplace, TempResult, StrInput, %StrDelimiter%, %TempDelim%, All
    StringSplit, Parts, TempResult, %TempDelim%
    return Parts
}

; Look up just the most applicable bracket for an affix.
; Most applicable means Value is between bounds of bracket range 
; OR highest entry possible given the item level
; returns: "#-#" format range
; If Value is unspecified ("") return the max possible bracket 
; based on item level
LookupAffixBracket(Filename, ItemLevel, Value="", ByRef BracketLevel="")
{
    AffixLevel := 0
    AffixDataIndex := 0
    If (Not Value == "")
    {
        ValueLo := Value             ; value from ingame tooltip
        ValueHi := Value             ; for single values (which most of them are) ValueLo == ValueHi
        ParseRange(Value, ValueHi, ValueLo)
    }
;    msgbox, Filename: %Filename%`, Value: %Value%`, ValueLo: %ValueLo%`, ValueHi: %ValueHi%
    LookupIsDoubleRange := False ; for affixes like "Adds +# ... Damage" which have a lower AND an upper bound range
    BracketRange := "n/a"
    Loop, Read, %A_WorkingDir%\%Filename%
    {  
		
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        RangeValues := AffixDataParts2
        If (RangeLevel > ItemLevel)
        {
            Break
        }
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ; example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; lower bound is a range: #-#
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            LBPart = %LBMin%
            UBPart = %UBMax%
            ; record bracket range if it is within bounds of the text file entry
            If (Value == "" or (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax))))
            {
                BracketRange = %LBPart%-%UBPart%
                AffixLevel = %RangeLevel%
            }
        }
        Else
        {
            ParseRange(RangeValues, HiVal, LoVal)
            ; record bracket range if it is within bounds of the text file entry
            If (Value == "" or ((ValueLo >= LoVal) and (ValueHi <= HiVal)))
            {
                BracketRange = %LoVal%-%HiVal%
                AffixLevel = %RangeLevel%
            }
        }
    }
    BracketLevel := AffixLevel
    return BracketRange
}

; Look up complete data for an affix. Depending on settings flags 
; this may include many things, and will return a string used for
; end user display rather than further calculations. 
; Use LookupAffixBracket if you need a range format to do calculations with.
LookupAffixData(Filename, ItemLevel, Value, ByRef BracketLevel="", ByRef Tier=0)
{
    Global MaxLevel
    Global MaxSpanStartingFromFirst
    Global CompactDoubleRanges
    Global TierRelativeToItemLevel
    MaxLevel := 0
    AffixLevel := 0
    AffixDataIndex := 0
    ValueLo := Value             ; value from ingame tooltip
    ValueHi := Value             ; for single values (which most of them are) ValueLo == ValueHi
    ValueIsMinMax := False       ; treat Value as min/max units (#-#) or as single unit (#)
    LookupIsDoubleRange := False ; for affixes like "Adds +# ... Damage" which have a lower AND an upper bound range
    FirstRangeValues =
    BracketRange := "n/a"
    MaxRange =
    FinalRange = 
    MaxLevel := 1
    RangeLevel := 1
    Tier := 0
    MaxTier := 0
    IfInString, Value, -
    {
        ParseRange(Value, ValueHi, ValueLo)
        ValueIsMinMax := True
		
    }
    ; Pre-pass to determine max tier
    Loop, Read, %A_WorkingDir%\%Filename%
    {  
        MaxTier += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        If (TierRelativeToItemLevel AND (RangeLevel > ItemLevel))
        {
            Break
        }
    }
    ;msgbox, MaxTier: %MaxTier%
    Loop, Read, %A_WorkingDir%\%Filename%
    {  
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeValues := AffixDataParts2
        RangeLevel := AffixDataParts1
        If (AffixDataIndex == 1)
        {
            FirstRangeValues := RangeValues
        }
        If (RangeLevel > ItemLevel)
        {
            Break
        }
        MaxLevel := RangeLevel
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ;            ; variables for min/max double ranges, like in the "Adds +# ... Damage" case
            ;            Global LBMin     ; (L)ower (B)ound minium value
            ;            Global LBMax     ; (L)ower (B)ound maximum value
            ;            GLobal UBMin     ; (U)pper (B)ound minimum value
            ;            GLobal UBMax     ; (U)pper (B)ound maximum value
            ;            ; same, just for the first range's values
            ;            Global FRLBMin   
            ;            Global FRLBMax   
            ;            Global FRUBMin   
            ;            Global FRUBMax   
            ; example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; lower bound is a range: #-#
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            If (AffixDataIndex == 1)
            {
                StringSplit, FirstDoubleRangeParts, FirstRangeValues, `,
                FRLB := FirstDoubleRangeParts%FirstDoubleRangeParts%1
                FRUB := FirstDoubleRangeParts%FirstDoubleRangeParts%2
                ParseRange(FRUB, FRUBMax, FRUBMin)
                ParseRange(FRLB, FRLBMax, FRLBMin)
            }
            If ((LBMin == LBMax) or CompactDoubleRanges) 
            {
                LBPart = %LBMin%
            }
            Else
            {
                LBPart = %LBMin%-%LBMax%
            }
            If ((UBMin == UBMax) or CompactDoubleRanges) 
            {
                UBPart = %UBMax%
            }
            Else
            {
                UBPart = %UBMin%-%UBMax%
            }
            If ((FRLBMin == FRLBMax) or CompactDoubleRanges)
            {
                FRLBPart = %FRLBMin%
            }
            Else
            {
                FRLBPart = %FRLBMin%-%FRLBMax%
            }
            If (CompactDoubleRanges)
            {
                MiddlePart := "-"
            }
            Else
            {
                MiddlePart := " to "
            }
            ; record bracket range  it is withing bounds of the text file entry
            If (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax)))
            {
                ;msgbox, Value: %Value%`, LBPart: %LBPart%`, UBPart: %UBPart%
                BracketRange = %LBPart%%MiddlePart%%UBPart%
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)
                ;msgbox, BracketRange: %BracketRange%
            }
            ; record max possible range regardless of within bounds
            If (MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLBPart%%MiddlePart%%UBPart%
            }
            Else
            {
                MaxRange = %LBPart%%MiddlePart%%UBPart%
            }
        }
        Else
        {
            If (AffixDataIndex = 1)
            {
                ParseRange(FirstRangeValues, FRHiVal, FRLoVal)
            }
            ParseRange(RangeValues, HiVal, LoVal)
            ; record bracket range if it is within bounds of the text file entry
            If ((ValueLo >= LoVal) and (ValueHi <= HiVal))
            {
                If (LoVal = HiVal)
                {
                    BracketRange = %LoVal%
                }
                Else
                {
                    BracketRange = %LoVal%-%HiVal%
                }
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)
                ;msgbox, AffixDataIndex: %AffixDataIndex%, FirstRangeValues: %FirstRangeValues%, 
            }
            ; record max possible range regardless of within bounds
            If (MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLoVal%-%HiVal%
            }
            Else
            {
                MaxRange = %LoVal%-%HiVal%
            }
        }
;        msgbox, Filename: %Filename%`n ValueLo: %ValueLo%`, ValueHi: %ValueHi%`n LoVal: %LoVal%`, HiVal: %HiVal%
    }
    BracketLevel := AffixLevel
    FinalRange := AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange, MaxLevel)
;    msgbox, FinalRange: %FinalRange%
    return FinalRange
}

AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange="", MaxLevel=0)
{
    Global ShowAffixLevel
    Global ShowAffixBracket
    Global ShowAffixMaxPossible
    Global ValueRangeFieldWidth
    Global AffixDetailDelimiter
    If (ShowAffixBracket)
    {
        FinalRange := BracketRange
        If (ValueRangeFieldWidth > 0)
        {
            FinalRange := StrPad(FinalRange, ValueRangeFieldWidth, "left")
        }
        If (ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . "(" . BracketLevel . ")" . ", "
        }
        Else
        {
            FinalRange := FinalRange . AffixDetailDelimiter
        }
    }
    If (MaxRange and ShowAffixMaxPossible)
    {
        If (ValueRangeFieldWidth > 0)
        {
            MaxRange := StrPad(MaxRange, ValueRangeFieldWidth, "left")
        }
        FinalRange := FinalRange . MaxRange
        If (ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . "(" . MaxLevel . ")"
        }
    }
    return FinalRange
}

ParseRarity(ItemData_NamePlate)
{
    Loop, Parse, ItemData_NamePlate, `n, `r
    {
        IfInString, A_LoopField, Rarity:
        {
            StringSplit, RarityParts, A_LoopField, %A_Space%
            Break
        }
    }
    ; return RarityParts%RarityParts%2
	return RarityParts%RarityParts0%
}

ParseQuality(ItemDataNamePlate)
{
    ItemQuality := 0
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        If (StrLen(A_LoopField) = 0)
        {
            Break
        }
        IfInString, A_LoopField, Unidentified
        {
            Break
        }
        IfInString, A_LoopField, 品質:
        {
            ItemQuality := RegExReplace(A_LoopField, "品質: \+(\d+)% .*", "$1")
            Break
        }
    }
    return ItemQuality
}

ParseAugmentations(ItemDataChunk, ByRef AffixCSVList)
{
    Global CurAugment
    CurAugment := ItemDataChunk
    Loop, Parse, ItemDataChunk, `n, `r
    {
        CurAugment := A_LoopField
        IfInString, A_LoopField, 需求: ;Requirements:
        {
            Break
        }
        IfInString, A_LoopField, (augmented)
        {
            StringSplit, LineParts, A_LoopField, :
            AffixCSVList := AffixCSVList . "'"  . LineParts%LineParts%1 . "'"
            AffixCSVList := AffixCSVList . ", "
        }
    }
    AffixCSVList := SubStr(AffixCSVList, 1, -2)
}

ParseRequirements(ItemDataChunk, ByRef Level, ByRef Attributes, ByRef Values="")
{
    IfNotInString, ItemDataChunk, 需求 ;Requirements
    {
        return
    }
    Attr =
    AttrValues =
    Delim := ","
    DelimLen := StrLen(Delim)
    Loop, Parse, ItemDataChunk, `n, `r
    {    
        If StrLen(A_LoopField) = 0
        {
            Break ; not interested in blank lines
        }
        IfInString, A_LoopField, 力量
        {
            Attr := Attr . "Str" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, 敏捷
        {
            Attr := Attr . "Dex" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, 智慧
        {
            Attr := Attr . "Int" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, 等級
        {
            Level := GetColonValue(A_LoopField)
        }
    }
    ; chop off last Delim
    If (SubStr(Attr, -(DelimLen-1)) == Delim)
    {
        Attr := SubStr(Attr, 1, -(DelimLen))
    }
    If (SubStr(AttrValues, -(DelimLen-1)) == Delim)
    {
        AttrValues := SubStr(AttrValues, 1, -(DelimLen))
    }
    Attributes := Attr
    Values := AttrValues
}

; parses #low-#high and sets Hi to #high and Lo to #low
; if RangeChunk is just a single value (#) it will set both
; Hi and Lo to this single value (effectively making the range 1-1 if # was 1)
ParseRange(RangeChunk, ByRef Hi, ByRef Lo)
{
    IfInString, RangeChunk, -
    {
        StringSplit, RangeParts, RangeChunk, -
        Lo := RegExReplace(RangeParts1, "(\d+?)", "$1")
        Hi := RegExReplace(RangeParts2, "(\d+?)", "$1")
    }
    Else
    {
        Hi := RangeChunk
        Lo := RangeChunk
    }
}

ParseItemLevel(ItemData, PartialString="Itemlevel:")
{
    Result =
    Loop, Parse, ItemData, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break
        }
        IfInString, A_LoopField, %PartialString%
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := ItemLevelParts2
            Break
        }
    }
    return Result
}

StrMult(Char, Times)
{
    Result =
    Loop, %Times%
    {
        Result := Result . Char
    }
    return Result
}

StrTrimSpaceLeft(String)
{
    return RegExReplace(String, " *(.+?)", "$1")
}

StrTrimSpaceRight(String)
{
    return RegExReplace(String, "(.+?) *$", "$1")
}

StrTrimSpace(String)
{
    return RegExReplace(String, " *(.+?) *", "$1")
}

; StrLen support chinese word
StrLenCP0(String)
{
    return StrPut(String, "cp0") - 1
}

; Pads a string with a multiple of PadChar to become a wanted total length.
; Note that Side is the side that is padded not the anchored side.
; Meaning, if you pad right side, the text will move left. If Side was an 
; anchor instead, the text would move right if anchored right.
StrPad(String, Length, Side="right", PadChar=" ")
{
;    Result := String
    AddLen := Length - StrLenCP0(String)
    If (AddLen <= 0)
    {
;        msgbox, String: %String%`, Length: %Length%`, Len: %Len%`, AddLen: %AddLen%
        return String
    }
    Pad := StrMult(PadChar, AddLen)
    If (Side == "right")
    {
        Result := String . Pad
    }
    Else
    {
        Result := Pad . String
    }
    return Result
}

; estimate indicator, marks end user display values so they can take a look at it
MarkAsGuesstimate(ValueRange, Side="left", Indicator=" * ")
{
    Global ValueRangeFieldWidth
    Global MarkedAsGuess
    MarkedAsGuess := True
    return StrPad(ValueRange . Indicator, ValueRangeFieldWidth + StrLen(Indicator), Side)
}

MakeAffixDetailLine(AffixLine, AffixType, ValueRange, Tier)
{
    Global ItemDataRarity
    Delim := "|"
    Ellipsis := AffixDetailEllipsis
    Line := AffixLine . Delim . ValueRange . Delim . AffixType
    If (ItemDataRarity == "Rare")
    {
        Line := Line . Delim . Tier
    }
    return Line
}

AppendAffixInfo(Line, AffixPos)
{
    Global
    AffixLines%AffixPos% := Line
}

AssembleAffixDetails()
{
    Global
    Local Result
    Local Delim
    Local Ellipsis
    Local CurLine
    Local IsImplicitMod
    Local TierString
    Local ValueRangeString
    AffixLine =
    AffixType =
    ValueRange =
    AffixTier =
    Loop, %NumAffixLines%
    {
        CurLine := AffixLines%A_Index%
        ; blank out affix line parts so that when affix line splits 
        ; into less parts than before, there won't be left overs
        Loop, 3
        {
            AffixLineParts%A_Index% =
        }
        StringSplit, AffixLineParts, CurLine, |
        AffixLine := AffixLineParts1
        ValueRange := AffixLineParts2
        AffixType := AffixLineParts3
        AffixTier := AffixLineParts4

        ;msgbox, AffixTier: %AffixTier%

        Delim := AffixDetailDelimiter
        Ellipsis := AffixDetailEllipsis

        If (ValueRangeFieldWidth > 0)
        {
            ValueRange := StrPad(ValueRange, ValueRangeFieldWidth, "left")
        }
        If (MirrorAffixLines = 1)
        {
            If (MirrorLineFieldWidth > 0)
            {
                If(StrLenCP0(AffixLine) > MirrorLineFieldWidth)
                {   
                    AffixLine := StrTrimSpaceRight(SubStr(AffixLine, 1, MirrorLineFieldWidth)) . Ellipsis
                }
                AffixLine := StrPad(AffixLine, MirrorLineFieldWidth + StrLenCP0(Ellipsis))
            }
            ProcessedLine := AffixLine . Delim
        }
        IfInString, ValueRange, *
        {
            ValueRangeString := StrPad(ValueRange, (ValueRangeFieldWidth * 2) + (StrLenCP0(AffixDetailDelimiter)))
        }
        Else
        {
            ValueRangeString := ValueRange
        }
        ProcessedLine := ProcessedLine . ValueRangeString . Delim
        If (ShowAffixBracketTier == 1 AND Not (ItemDataRarity == "Unique"))
        {
            If (InStr(ValueRange, "*") AND ShowAffixBracketTier)
            {
                TierString := "   "
            }
            Else
            {
                TierString := StrPad("T" . AffixTier, 3, "left")
            }
            ProcessedLine := ProcessedLine . TierString . Delim
        }
        ProcessedLine := ProcessedLine . AffixType . Delim
        Result := Result . "`n" . ProcessedLine
    }
;    msgbox, Result: %Result%
    return Result
}

; Same as AdjustRangeForQuality, except that Value is just
; a single value and not a range.
AdjustValueForQuality(Value, ItemQuality, Direction="up")
{
    If (ItemQuality < 1)
        return Value
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        Result := Round(Value + (Value * Divisor))
    }
    Else
    {
        Result := Round(Value - (Value * Divisor))
    }
    return Result
}

; Adjust an affix' range for +% Quality on an item.
; For example: given the range 10-20 and item quality +15%
; the result would be 11.5-23 which is currently rounded up
; to 12-23. Note that Direction does not play a part in rounding
; rather it controls if adjusting up towards quality increase or
; down from quality increase (to get the original value back)
AdjustRangeForQuality(ValueRange, ItemQuality, Direction="up")
{
    If (ItemQuality = 0)
    {
        return ValueRange
    }
    VRHi := 0
    VRLo := 0
    ParseRange(ValueRange, VRHi, VRLo)
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        VRHi := Round(VRHi + (VRHi * Divisor))
        VRLo := Round(VRLo + (VRLo * Divisor))
    }
    Else
    {
        VRHi := Round(VRHi - (VRHi * Divisor))
        VRLo := Round(VRLo - (VRLo * Divisor))
    }
    If (VRLo == VRHi)
    {
        ValueRange = %VRLo%
    }
    Else
    {
        ValueRange = %VRLo%-%VRHi%
    }
    return ValueRange
}

; checks ActualValue against ValueRange, returning 1 
; if ActualValue is within bounds of ValueRange, 0 otherwise
WithinBounds(ValueRange, ActualValue)
{
;    msgbox, ValueRange: %ValueRange%`, ActualValue: %ActualValue%
    VHi := 0
    VLo := 0
    ParseRange(ValueRange, VHi, VLo)
    Result := 1
    IfInString, ActualValue, -
    {
        AVHi := 0
        AVLo := 0
        ParseRange(ActualValue, AVHi, AVLo)
        If ((AVLo < VLo) or (AVHi > VHi))
        {
            Result := 0
        }
    }
    Else
    {
        If ((ActualValue < VLo) or (ActualValue > VHi))
        {
            Result := 0
        }
    }
;    msgbox, Result: %Result%
    return Result
}

GetAffixTypeFromProcessedLine(PartialAffixString)
{
    Global
    Loop, %NumAffixLines%
    {
        Local AffixLine
        AffixLine := AffixLines%A_Index%
        IfInString, AffixLine, %PartialAffixString%
        {
            Local AffixLineParts
            StringSplit, AffixLineParts, AffixLine, |
            return AffixLineParts3
        }
    }
}

; Get actual value from a line of the ingame tooltip as a number
; that can be used in calculations.
GetActualValue(ActualValueLine)
{
    Result := RegExReplace(ActualValueLine, ".*?\+?(\d+(?:-\d+|\.\d+)?).*", "$1")
    return Result
}

; Get value from a color line, e.g. given the line "Level: 57", returns the number 57
GetColonValue(Line)
{
    IfInString, Line, :
    {
        StringSplit, LineParts, Line, :
        Result := StrTrimSpace(LineParts%LineParts%2)
        return Result
    }
}

RangeMid(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    RSum := RHi+RLo
    If (RSum == 0)
    {
        return 0
    }
    return Floor((RHi+RLo)/2)
}

RangeMin(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RLo
}

RangeMax(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RHi
}

AddRange(Range1, Range2)
{
    R1Hi := 0
    R1Lo := 0
    R2Hi := 0
    R2Lo := 0
    ParseRange(Range1, R1Hi, R1Lo)
    ParseRange(Range2, R2Hi, R2Lo)
    FinalHi := R1Hi + R2Hi
    FinalLo := R1Lo + R2Lo
    FinalRange = %FinalLo%-%FinalHi%
    return FinalRange
}

; used to check return values from LookupAffixBracket()
IsValidBracket(Bracket)
{
    If (Bracket == "n/a")
    {
        return False
    }
    return True
}

; used to check return values from LookupAffixData()
IsValidRange(Bracket)
{
    IfInString, Bracket, n/a
    {
        return False
    }
    return True
}

; Note that while ExtractCompAffixBalance() can be run on processed data
; that has compact affix type declarations (or not) for this function to
; work properly, make sure to run it on data that has compact affix types
; turned off. The reason being that it is hard to count prefixes by there
; being a "P" in a line that also has mirrored affix descriptions.
ExtractTotalAffixBalance(ProcessedData, ByRef Prefixes, ByRef Suffixes, ByRef CompPrefixes, ByRef CompSuffixes)
{
;    msgbox, ProcessedData: %ProcessedData%
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, 複 前
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, 複 後
        {
            CompSuffixes += 1
        }
    }
    ProcessedData := RegExReplace(ProcessedData, "複 前", "")
    ProcessedData := RegExReplace(ProcessedData, "複 後", "")
;    msgbox, ProcessedData: %ProcessedData%
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, 前 ;Prefix
        {
            Prefixes += 1
;            ProcessedData := RegExReplace(ProcessedData, "前", "")
        }
        IfInString, AffixLine, 後 ;Suffix
        {
            Suffixes += 1
;            ProcessedData := RegExReplace(ProcessedData, "後", "")
        }
    }
}
ExtractCompositeAffixBalance(ProcessedData, ByRef CompPrefixes, ByRef CompSuffixes)
{
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, 複 前
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, 複 後
        {
            CompSuffixes += 1
        }
    }
}

ParseAffixes(ItemDataChunk, ItemLevel, ItemQuality, ByRef NumPrefixes, ByRef NumSuffixes)
{
    Global ItemBaseType
    Global ItemSubType
    Global ItemGripType
    Global NumAffixLines
    Global ValueRangeFieldWidth  ; for StrPad on guesstimated values
    Global MsgUnhandled
    Global MarkedAsGuess

    ; keeps track of how many affix lines we have so they can be assembled later
    ; acts as a loop index variable when iterating each affix data part
    NumAffixLines := 0
    NumPrefixes := 0
    NumSuffixes := 0
    
    ; Composition flags
    ; these are required for later descision making when guesstimating
    ; sources for parts of a value from composite and/or same name affixes
    ; They will be set to the line number where they occur in the pre-pass
    ; loop so that details for that line can be changed later after we
    ; have more clues for possible compositions.
    HasIIQ := 0
    HasIncrArmour := 0
    HasIncrEvasion := 0
    HasIncrEnergyShield := 0
    HasHybridDefences := 0
    HasIncrArmourAndES := 0
    HasIncrArmourAndEvasion := 0
    HasIncrEvasionAndES := 0
    HasIncrLightRadius := 0
    HasIncrAccuracyRating := 0
    HasIncrPhysDmg := 0
    HasToAccuracyRating := 0
    HasStunRecovery := 0
    HasSpellDamage := 0
    HasMaxMana := 0

    ; max mana already accounted for in case of composite prefix+prefix "Spell Damage / Max Mana" + "Max Mana"
    MaxManaPartial =

    ; Accuracy Rating already accounted for in case of 
    ;   composite prefix + composite suffix: "increased Physical Damage / to Accuracy Rating" + "to Accuracy Rating / Light Radius"
    ;   composite prefix + suffix: "increased Physical Damage / to Accuracy Rating" + "to Accuracy Rating"
    ARPartial =
    ARAffixTypePartial =

    ; Partial for Block and Stun Recovery
    BSRecPartial =

    ; --- PRE-PASS ---
    
    ; to determine composition flags
    Loop, Parse, ItemDataChunk, `n, `r
    {    
        If StrLen(A_LoopField) = 0
        {
            Break ; not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; not interested in unidentified items
        }
        
        NumAffixLines += 1
        
        IfInString, A_LoopField, 照亮範圍
        {
            HasIncrLightRadius := A_Index
            Continue
        }
        IfInString, A_LoopField, 物品數量 ;increased Quantity
        {
            HasIIQ := A_Index
            Continue
        }
        IfInString, A_LoopField, 物理傷害
        {
            HasIncrPhysDmg := A_Index
            Continue
        }
		; not sure
        IfInString, A_LoopField, 點命中(全域)
        {
            HasIncrAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, 點命中(區域)
        {
            HasToAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, 謢甲 閃避
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, 謢甲 能量謢盾
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, 閃避 能量護盾
        {
            HasHybridDefences := A_Index
            HasIncrEvasionAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, 謢甲
        {
            HasIncrArmour := A_Index
            Continue
        }
        IfInString, A_LoopField, 閃避率
        {
            HasIncrEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, 能量護盾
        {
            HasIncrEnergyShield := A_Index
            Continue
        }
        IfInString, A_LoopField, 格擋與暈眩回復
        {
            HasStunRecovery := A_Index
            Continue
        }
        IfInString, A_LoopField, 法術傷害
        {
            HasSpellDamage := A_Index
            Continue
        }
        IfInString, A_LoopField, 最大魔力
        {
            HasMaxMana := A_Index
            Continue
        }
    }

    ; Reset the AffixLines "array" and other vars
    ResetAffixDetailVars()

    ; --- SIMPLE AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; not interested in unidentified items
        }

        MarkedAsGuess := False

;        msgbox, % ItemDataChunk
        
        ; Note: yes, this superlong IfInString structure sucks
        ; but hey, AHK sucks as a scripting language, so bite me.
        ; But in all seriousness, the incrementing parts could be
        ; covered with one label+goto per affix type but I decided
        ; not to because the if bodies are actually placeholders 
        ; for a system that looks up max and min values possible
        ; per affix from a collection of text files. The latter is 
        ; a TODO for a future version of the script though.
        
;        Global CurrValue ; d
        CurrValue := GetActualValue(A_LoopField)
        CurrTier := 0
        BracketLevel := 0

        ;msgbox, CurrTier: %CurrTier%

        ; Suffixes
        IfInString, A_LoopField, 攻擊速度
        {
            NumSuffixes += 1
            If (ItemBaseType == "Weapon") ; ItemBaseType is Global!
            {
                ValueRange := LookupAffixData("data\AttackSpeed_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\AttackSpeed_ArmourAndItems.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 點命中
        {
            AffixType := "Comp. Suffix"
            ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, 全能力
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToAllAttributes.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 力量
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToStrength.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 智慧
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToIntelligence.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 敏捷
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToDexterity.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 施法速度
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CastSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Chance" !
        IfInString, A_LoopField, 法術暴擊率
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\SpellCritChance.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 暴擊率
        {
            If (ItemSubType == "Quiver" or ItemSubType == "Amulet")
            {
                ValueRange := LookupAffixData("data\CritChance_AmuletsAndQuivers.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\CritChance_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 全域暴擊加成
        {
            If (ItemSubType == "Quiver" or ItemSubType == "Amulet")
            {
                ValueRange := LookupAffixData("data\CritMultiplier_AmuletsAndQuivers.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\CritMultiplier_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            NumSuffixes += 1
            Continue
        }
        IfInString, A_LoopField, `% 火焰傷害
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrFireDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 冰冷傷害
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrColdDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 閃電傷害
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrLightningDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 照亮範圍
        {
            ValueRange := LookupAffixData("data\LightRadius_AccuracyRating.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 格擋率
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\BlockChance.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; Flask effects (on belts)
        IfInString, A_LoopField, 藥劑充能使用
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesUsed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 藥劑充能獲
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesGained.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 藥劑效果持續時間
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; Flasks Suffixes
        ; only applicable to *drumroll* ... flasks
        IfInString, A_LoopField, 驅散
        {
            ; covers Shock, Burning and Frozen and Chilled
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 移除流血
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 免疫所有詛咒
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 藥劑使用期間
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 附加擊退
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 召喚物生命回復
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        ; END Flask Suffixes
        
        IfInString, A_LoopField, 物品數量
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IIQ.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 擊殺回復生命
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 擊中回復生命
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 每秒生命回復
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 擊殺回復魔力
        {
            ; Not a typo: 'G' in Gained is capital here as opposed to 'Life gained'
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 魔力回復速度
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 投射物速度
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ProjectileSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 能力值需求
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ReducedAttrReqs.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 全部元素抗性
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\AllResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 火焰抗性
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FireResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 閃電抗性
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 冰冷抗性
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 混沌抗性
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ChaosResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If RegExMatch(A_LoopField, ".* (冰冷|火焰|閃電) and (冰冷|火焰|閃電) 抗性")
        {
            ; Catches two-stone rings and the like which have "+#% to 冰冷 and 閃電 抗性"
            IfInString, A_LoopField, 火焰
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\FireResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, 閃電
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\LightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, 冰冷
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\ColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
        }
        IfInString, A_LoopField, 敵人暈眩時間
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\StunDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 敵人暈眩門檻
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\StunThreshold.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; Prefixes
        
        IfInString, A_LoopField, 點護甲
        {
            NumPrefixes += 1
            If (ItemBaseType == "Item")
            {
                ; Global
                ValueRange := LookupAffixData("data\ToArmour_Items.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            }
            Else
            {
                ; Local
                ValueRange := LookupAffixData("data\ToArmour_WeaponsAndArmour.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            }
            Continue
        }
        IfInString, A_LoopField, 護甲與閃避
        {
            AffixType := "Prefix"
            AEBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                AEBracketLevel2 := AEBracketLevel

                AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(AEBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AEBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidRange(ValueRange))
                {
                    ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, AEBracketLevel, CurrTier)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    ; This means that we are actually dealing with a Prefix + Comp. Prefix.
                    ; To get the part for the hybrid defence that is contributed by the straight prefix, 
                    ; lookup the bracket level for the B&S Recovery line and then work out the partials
                    ; for the hybrid stat from the bracket level of B&S. 
                    ; Example: 
                    ;   87% increased Armour and Evasion
                    ;   7% increased Block and Stun Recovery
                    ;
                    ; 1) 7% B&S indicates bracket level 2 (6-7)
                    ; 2) lookup bracket level 2 from the hybrid stat + block and stun recovery table
                    ; This works out to be 6-14.
                    ; 3) subtract 6-14 from 87 to get the rest contributed by the hybrid stat as pure prefix.
                    ; Currently when subtracting a range from a single value we just use the range's 
                    ; max as single value. This may need changing depending on circumstance but it
                    ; works for now. EDIT: no longer the case, now uses RangeMid(...). #'s below changed to 
                    ; reflect that...
                    ; 87-10 = 77
                    ; 4) lookup affix data for increased Armour and Evasion with value of 77
                    ; We now know, this is a Comp. Prefix+Prefix
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        ; This means that the hybrid stat is a Comp. Prefix+Prefix and BS rec is a Comp. Prefix+Suffix
                        ; This is ambiguous and tough to resolve, but we'll try anyway...
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }
;                    msgbox, BSRecValue: %BSRecValue%`, BSRecBracketLevel: %BSRecBracketLevel%`, BSRecPartial: %BSRecPartial%
                   
                    AEBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

;                    msgbox, AEBSBracket: %AEBSBracket%
                    If (Not WithinBounds(AEBSBracket, CurrValue))
                    {
                        AERest := CurrValue - RangeMid(AEBSBracket)
                        AEBracket := LookupAffixBracket("data\ArmourAndEvasion.txt", ItemLevel, AERest)
;                        msgbox, AEBracket: %AEBracket%`, AEBSBracket: %AEBSBracket%`,AERest: %AERest%

                        If (Not IsValidBracket(AEBracket))
                        {
                            AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(AEBracket, CurrValue))
                        {
                            ValueRange := AddRange(AEBSBracket, AEBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 護甲與能量護盾
        {
            AffixType := "Prefix"
            AESBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                AESBracketLevel2 := AESBracketLevel

                AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(AESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", AESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    AESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(AESBSBracket, CurrValue))
                    {
                        AESRest := CurrValue - RangeMid(AESBSBracket)
                        AESBracket := LookupAffixBracket("data\ArmourAndEnergyShield.txt", ItemLevel, AESRest)

                        If (Not IsValidBracket(AESBracket))
                        {
                            AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(AESBracket, CurrValue))
                        {
                            ValueRange := AddRange(AESBSBracket, AESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }
                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 閃避與能量護盾
        {
            AffixType := "Prefix"
            EESBracketLevel := 0
            ValueRange := LookupAffixData("data\EvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                EESBracketLevel2 := EESBracketLevel

                EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(EESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    EESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(EESBSBracket, CurrValue))
                    {
                        EESRest := CurrValue - RangeMid(EESBSBracket)
                        EESBracket := LookupAffixBracket("data\EvasionAndEnergyShield.txt", ItemLevel, EESRest)

                        If (Not IsValidBracket(EESBracket))
                        {
                            EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(EESBracket, CurrValue))
                        {
                            ValueRange := AddRange(EESBSBracket, EESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 護甲
        {
            AffixType := "Prefix"
            IABracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrArmour_Items.txt"
                PrefixPathOther := "data\IncrArmour_WeaponsAndArmour.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrArmour_WeaponsAndArmour.txt"
                PrefixPathOther := "data\IncrArmour_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            }
            If (HasStunRecovery) 
            {
                IABracketLevel2 := IABracketLevel

                ASRBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(ASRBracket))
                {
                    ValueRange := LookupAffixData("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel2, "", BSRecBracketLevel)
                ;msgbox, IABracketLevel: %IABracketLevel%`, BSRecValue: %BSRecValue%`, BSRecBracketLevel: %BSRecBracketLevel%`, BSRecPartial: %BSRecPartial%
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, BSRecValue, BSRecBracketLevel)             
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                    ;msgbox, BSRecValue: %BSRecValue%`, BSRecBracketLevel: %BSRecBracketLevel%`, BSRecPartial: %BSRecPartial%

                    IABSBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IABSBracket, CurrValue))
                    {
                        IARest := CurrValue - RangeMid(IABSBracket)
                        IABracket := LookupAffixBracket(PrefixPath, ItemLevel, IARest)
                        ;msgbox, IABracket: %IABracket%`, IABSBracket: %IABSBracket%`, IARest: %IARest%
                        If (Not IsValidBracket(IABracket))
                        {
                            IABracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(IABracket, CurrValue))
                        {
                            ValueRange := AddRange(IABSBracket, IABracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 點閃避率
        {
            NumPrefixes += 1
            If (ItemBaseType == "Item")
            {
                ValueRange := LookupAffixData("data\ToEvasion_Items.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            }
            Else
            {
                ValueRange := LookupAffixData("data\ToEvasion_Armour.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            }
            Continue
        }
        IfInString, A_LoopField, `% 閃避率
        {
            AffixType := "Prefix"
            IEBracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrEvasion_Items.txt"
                PrefixPathOther := "data\IncrEvasion_Armour.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrEvasion_Armour.txt"
                PrefixPathOther := "data\IncrEvasion_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            }
            If (HasStunRecovery) 
            {
                IEBracketLevel2 := IEBracketLevel

                ; determine composite bracket level and store in IEBracketLevel2, for example:
                ; 8% increased Evasion, 26% increased Block and Stun Recover =>
                ; 8% is bracket level 2 (6-14), so 'B+S Rec from Evasion' level 2 makes BSRec partial 6-7
                ERSRBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(ERSRBracket))
                {
                    ValueRange := LookupAffixData("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel2, "", BSRecBracketLevel)
                ;msgbox, IEBracketLevel: %IEBracketLevel%`, ValueRange: %ValueRange%, BSRecPartial: %BSRecPartial%, BSRecValue: %BSRecValue%, IEBracketLevel: %IEBracketLevel%
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidRange(ValueRange) and (Not IsValidBracket(BSRecPartial) or Not WithinBounds(BSRecPartial, BSRecValue)))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                   
                    IEBSBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {
                        IERest := CurrValue - RangeMid(IEBSBracket)
                        IEBracket := LookupAffixBracket(PrefixPath, ItemLevel, IERest)
                        If (Not IsValidBracket(IEBracket))
                        {
                            IEBracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue, "")
                        }
                        If (Not WithinBounds(IEBracket, CurrValue))
                        {
;                            msgbox, IEBracket: %IEBracket%, IEBSBracket: %IEBSBracket%
                            ValueRange := AddRange(IEBSBracket, IEBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
;                        msgbox, BSRecPartial: %BSRecPartial%, BSRecValue: %BSRecValue%
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        ; IfInString, A_LoopField, 最大能量護盾
		if RegExMatch(A_LoopField, "\+\d+?\s最大能量護盾")
        {
			PrefixType := "Prefix"
			If (ItemSubType == "Ring" or ItemSubType == "Amulet" or ItemSubType == "Belt")
			{
				ValueRange := LookupAffixData("data\ToMaxEnergyShield.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				ValueRange := LookupAffixData("data\ToEnergyShield.txt", ItemLevel, CurrValue, "", CurrTier)

			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			NumPrefixes += 1
			Continue		
        }
        IfInString, A_LoopField, `% 能量護盾
        {
            AffixType := "Prefix"
            IESBracketLevel := 0
            PrefixPath := "data\IncrEnergyShield.txt"
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IESBracketLevel, CurrTier)

            If (HasStunRecovery) 
            {
                IESBracketLevel2 := IESBracketLevel

                ESSRBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2)
                If (Not IsValidRange(ValueRange) AND IsValidBracket(ESSRBracket))
                {
                    ValueRange := LookupAffixData("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel2, "", BSRecBracketLevel)
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Block and Stun Recovery")
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                    IESBSBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {                    
                        IESRest := CurrValue - RangeMid(IESBSBracket)
                        IESBracket := LookupAffixBracket(PrefixPath, ItemLevel, IESRest)

                        If (Not WithinBounds(IESBracket, CurrValue))
                        {
                            ValueRange := AddRange(IESBSBracket, IESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, `% 最大能量護盾
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrMaxEnergyShield_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If RegExMatch(A_LoopField, "附加\s\d+?\-\d+?\s物理傷害")
        {
            If (ItemBaseType == "Weapon")
            {
                If (ItemSubType == "Bow")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemGripType == "1H") ; one handed weapons
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                }
            }
            Else
            {
                If (ItemSubType == "Amulet")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemSubType == "Quiver")
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (ItemSubType == "Ring")
                        {
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Rings.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ; there is no Else for rare items, but some uniques have added phys damage
                            ; just lookup in 1H for now
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "附加\s\d+?\-\d+?\s冰冷傷害")
        {
			If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				If (ItemSubType == "Gloves")
				{
					ValueRange := LookupAffixData("data\AddedColdDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					If (ItemSubType == "Quiver")
					{
						ValueRange := LookupAffixData("data\AddedColdDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
					}
					Else
					{
						If (ItemGripType == "1H")
						{
							ValueRange := LookupAffixData("data\AddedColdDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
						}
						Else
						{
							ValueRange := LookupAffixData("data\AddedColdDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
						}
					}
				}
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			NumPrefixes += 1
			Continue
		}

		If RegExMatch(A_LoopField, "附加\s\d+?\-\d+?\s火焰傷害*")
		{
			If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				If (ItemSubType == "Gloves")
				{
					ValueRange := LookupAffixData("data\AddedFireDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					If (ItemSubType == "Quiver")
					{
						ValueRange := LookupAffixData("data\AddedFireDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
					}
					Else
					{
						If (ItemGripType == "1H") ; one handed weapons
						{
							ValueRange := LookupAffixData("data\AddedFireDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
						}
						Else
						{
							ValueRange := LookupAffixData("data\AddedFireDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
						}
					}
				}
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			NumPrefixes += 1
			Continue
		}
        If RegExMatch(A_LoopField, "附加\s\d+?\-\d+?\s閃電傷害")
        {
            If (ItemSubType == "Amulet" or ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\AddedLightningDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                If (ItemSubType == "Gloves")
                {
                    ValueRange := LookupAffixData("data\AddedLightningDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemSubType == "Quiver")
                    {
                        ValueRange := LookupAffixData("data\AddedLightningDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (ItemGripType == "1H") ; one handed weapons
                        {
                            ValueRange := LookupAffixData("data\AddedLightningDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ValueRange := LookupAffixData("data\AddedLightningDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
            ActualRange := GetActualValue(A_LoopField)
            AffixType := "Prefix"
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, Physical Damage to Melee Attackers
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\PhysDamagereturn.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 寶石等級 ;Gems in this item
        {
            If (ItemBaseType == "Weapon")
            {
                If (ItemSubType == "Bow")
                {
                    ValueRange := LookupAffixData("data\GemLevel_Bow.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (InStr(A_LoopField, "火焰") OR InStr(A_LoopField, "冰冷") OR InStr(A_LoopField, "閃電"))
                    {
                        ValueRange := LookupAffixData("data\GemLevel_Elemental.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (InStr(A_LoopField, "近戰"))
                        {
                            ValueRange := LookupAffixData("data\GemLevel_Melee.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ; Paragorn's
                            ValueRange := LookupAffixData("data\GemLevel.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
            Else
            {
                If (InStr(A_LoopField, "Minion"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Minion.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else If (InStr(A_LoopField, "Fire") OR InStr(A_LoopField, "Cold") OR InStr(A_LoopField, "Lightning"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Elemental.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else If (InStr(A_LoopField, "Melee"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Melee.txt", ItemLevel, CurrValue, "", CurrTier)
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 最大生命
        {
            ValueRange := LookupAffixData("data\MaxLife.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, 物理攻擊傷害偷取生命
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\LifeLeech.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 移動速度
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MovementSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 武器元素傷害
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrWeaponElementalDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Flask effects (on belts)
        IfInString, A_LoopField, 藥劑魔力回復速度 ;increased Flask Mana Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskManaRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, 藥劑生命回復速度 ;increased Flask Life Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskLifeRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Flask prefixes
        IfInString, A_LoopField, 回復速度 ;Recovery Speed
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 回復量 ;Amount Recovered
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 充能 ;Charges
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 立即 ;Instant
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        ; IfInString, A_LoopField, Charge when
		If RegExMatch(A_LoopField, "當.*充能.*")
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        ; IfInString, A_LoopField, Recovery when
		If RegExMatch(A_LoopField, "時.*回復.*")
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 魔力回復
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, 生命回復
        {
            If (NumPrefixes < 1) 
            {
                NumPrefixes += 1
            }
            Continue
        }
    }

    ; --- COMPLEX AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        ; "Spell Damage +%" (simple prefix)
        ; "Spell Damage +% (1H)" / "Base Maximum Mana" - Limited to sceptres, wands, and daggers. 
        ; "Spell Damage +% (Staff)" / "Base Maximum Mana"
		; "increased Spell Damage"
        IfInString, A_LoopField, `% 法術傷害
        {
            AffixType := "Prefix"
            If (HasMaxMana)
            {
                SDBracketLevel := 0
                MMBracketLevel := 0
                MaxManaValue := ExtractValueFromAffixLine(ItemDataChunk, "最大魔力")
                If (ItemSubType == "Staff")
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1
                        
                        ; need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            ; this actually means that both the "increased Spell Damage" line and 
                            ; the "to maximum Mana" line are made up of composite prefix + prefix 
                            ; I haven't seen such an item yet but you never know. In any case this
                            ; is completely ambiguous and can't be resolved. Mark line with EstInd
                            ; so user knows she needs to take a look at it.
                            AffixType := "Comp. Prefix+Comp. Prefix"
                            ValueRange := StrPad(EstInd, ValueRangeFieldWidth + StrLen(EstInd), "left")
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", MMBracketLevel)
                            SDValueRest := CurrValue - RangeMid(SpellDamageBracketFromComp)
                            SpellDamageBracket := LookupAffixBracket("data\SpellDamage_Staff.txt", ItemLevel, SDValueRest, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                Else
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1
                        
                        ; need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            MaxManaBracket := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                            If (IsValidBracket(MaxManaBracket))
                            {
                                AffixType := "Prefix"
                                If (ItemSubType == "Staff")
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                Else
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                ValueRange := StrPad(ValueRange, ValueRangeFieldWidth, "left")
                            }
                            Else
                            {
                                msgbox, %MsgUnhandled%
                                ValueRange := StrPad("n/a", ValueRangeFieldWidth, "left")
                            }
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", MMBracketLevel)
                            SDValueRest := CurrValue - RangeMid(SpellDamageBracketFromComp)
                            SpellDamageBracket := LookupAffixBracket("data\SpellDamage_1H.txt", ItemLevel, SDValueRest, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                ; if MaxManaValue falls within bounds of MaxManaBracket this means the max mana value is already fully accounted for
                If (WithinBounds(MaxManaBracket, MaxManaValue))
                {
                    MaxManaPartial =
                }
                Else
                {
                    MaxManaPartial := MaxManaBracket
                }
            }
            Else
            {
                If (ItemSubType == "Amulet")
                {
                    ValueRange := LookupAffixData("data\SpellDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemSubType == "Staff")
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                }
                NumPrefixes += 1
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        ; "Base Maximum Mana" (simple prefix)
        ; "1H Spell Damage" / "Base Maximum Mana" (complex prefix)
        ; "Staff Spell Damage" / "Base Maximum Mana" (complex prefix)
        IfInString, A_LoopField, 最大魔力
        {
            AffixType := "Prefix"
            If (ItemBaseType == "Weapon")
            {
                If (HasSpellDamage)
                {
                    If (MaxManaPartial and Not WithinBounds(MaxManaPartial, CurrValue))
                    {
;                        msgbox, MaxManaPartial: %MaxManaPartial%
                        NumPrefixes += 1
                        AffixType := "Comp. Prefix+Prefix"

                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        MaxManaRest := CurrValue-RangeMid(MaxManaPartial)

;                        msgbox, MaxManaPartial: %MaxManaPartial%
;                        msgbox, MaxManaRest: %MaxManaRest%
                        If (MaxManaRest >= 15) ; 15 because the lowest possible value at this time for Max Mana is 15 at bracket level 1
                        {
                            ; Lookup remaining Max Mana bracket that comes from Max Mana being concatenated as simple prefix
                            ValueRange1 := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaRest)
                            ValueRange2 := MaxManaPartial
;                            msgbox, MaxManaPartial: %MaxManaPartial%`, ValueRange1: %ValueRange1%`, ValueRange2: %ValueRange2%

                            ; Add these ranges together to get an estimated range
                            ValueRange := AddRange(ValueRange1, ValueRange2)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                        Else
                        {
                            ; Could be that the spell damage affix is actually a pure spell damage affix
                            ; (w/o the added max mana) so this would mean max mana is a pure prefix - if 
                            ; NumPrefixes allows it, ofc...
                            If (NumPrefixes < 3)
                            {
                                AffixType := "Prefix"
                                ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                                ChangeAffixDetailLine("法術傷害", "Comp. Prefix", "Prefix")
                            }
                        }
                    }
                    Else
                    {
                        ; it's on a weapon, there is Spell Damage but no MaxManaPartial or NumPrefixes already is 3
                        AffixType := "Comp. Prefix"
                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        If (Not IsValidBracket(ValueRange))
                        {
                            ; incr. spell damage is actually a prefix and not a comp. prefix
                            ; so max mana must be a normal prefix as well then
                            AffixType := "Prefix"
                            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    ; check if we still need to increment for the Spell Damage part
                    If (NumPrefixes < 3)
                    {
                        NumPrefixes += 1
                    }
                }
                Else
                {
                    ; it's on a weapon but there is no Spell Damage, which makes it a simple prefix
                    Goto, SimpleMaxManaPrefix
                }
            }
            Else
            {
                ; Armour... 
                ; Max Mana cannot appear on belts but I won't exclude them for now 
                ; to future-proof against when max mana on belts might be added.
                Goto, SimpleMaxManaPrefix
            }

            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

        SimpleMaxManaPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        ; "Local Physical Damage +%" (simple prefix) 
        ; "Local Physical Damage +%" / "Local Accuracy Rating" (complex prefix)
        ; only on Weapons
        ; needs to come before Accuracy Rating stuff 
        IfInString, A_LoopField, `% 物理傷害
        {
            AffixType := "Prefix"
            IPDPath := "data\IncrPhysDamage.txt"
            If (HasToAccuracyRating)
            {
                ARIPDPath := "data\AccuracyRating_IncrPhysDamage.txt"
                IPDARPath := "data\IncrPhysDamage_AccuracyRating.txt"
                ARValue := ExtractValueFromAffixLine(ItemDataChunk, "命中率")
                ARPath := "data\AccuracyRating_Global.txt"
                If (ItemBaseType == "Weapon")
                {
                    ARPath := "data\AccuracyRating_Local.txt"
                }

                ; look up IPD bracket, and use its bracket level to cross reference the corresponding
                ; AR bracket. If both check out (are within bounds of their bracket level) case is
                ; simple: Comp. Prefix (IPD / AR)
                IPDBracketLevel := 0
                IPDBracket := LookupAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracketLevel)
                ARBracket := LookupAffixBracket(ARIPDPath, IPDBracketLevel)
                
                If (HasIncrLightRadius)
                {
                    LRValue := ExtractValueFromAffixLine(ItemDataChunk, "照亮範圍" /* "increased Light Radius" */)
                    ; first check if the AR value that comes with the Comp. Prefix AR / Light Radius 
                    ; already covers the complete AR value. If so, from that follows that the Incr. 
                    ; Phys Damage value can only be a Damage Scaling prefix.
                    LRBracketLevel := 0
                    LRBracket := LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LRValue, LRBracketLevel)
                    ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", LRBracketLevel)
                    If (IsValidBracket(ARLRBracket))
                    {
                        If (WithinBounds(ARLRBracket, ARValue) AND WithinBounds(IPDBracket, CurrValue))
                        {
                            ;msgbox, LRBracketLevel: %LRBracketLevel%, ARLRBracket: %ARLRBracket%
                            Goto, SimpleIPDPrefix
                        }
                    }
                }

;                msgbox, IPDBracket: %IPDBracket%`, ARBracket: %ARBracket%

                If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
                {
                    Goto, CompIPDARPrefix
                }

                If (Not IsValidBracket(IPDBracket))
                {
                    IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, CurrValue)
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)  ; also lookup AR as if it were a simple suffix
;                    msgbox, NumPrefixes: %NumPrefixes%, NumSuffixes: %NumSuffixes%, IPDBracket: %IPDBracket%, ARBracket: %ARBracket%
                    If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket) and NumPrefixes < 3)
                    {
                        HasIncrPhysDmg := 0
                        Goto, SimpleIPDPrefix
                    }
                    ARBracketLevel := 0
                    ARBracket := LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketLevel)
                    If (IsValidBracket(ARBracket))
                    {
                        IPDARBracket := LookupAffixBracket(IPDARPath, ARBracketLevel)
                        IPDRest := CurrValue - RangeMid(IPDARBracket)
                        IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, IPDRest)
                        ValueRange := AddRange(IPDARBracket, IPDBracket)
                        ValueRange := MarkAsGuesstimate(ValueRange)
                        ARAffixTypePartial := "Comp. Prefix"
                        Goto, CompIPDARPrefixPrefix
                    }
                }

                If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
                {
                    HasIncrPhysDmg := 0
                    Goto, CompIPDARPrefix
                }

                If (IsValidBracket(ARBracket))
                {
                    ; AR bracket not found in the composite IPD/AR table
                    ARValue := ExtractValueFromAffixLine(ItemDataChunk, "閃避率" /* "to Accuracy Rating" */)
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)

                    Goto, CompIPDARPrefix
                }
                If (IsValidBracket(IPDBracket))
                {
                    ; AR bracket was found in the comp. IPD/AR table, but not the IPD bracket
                    Goto, SimpleIPDPrefix
                }
                Else
                {
                    ValueRange := LookupAffixData(IPDPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                Goto, SimpleIPDPrefix
            }
            
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

       SimpleIPDPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        CompIPDARPrefix:
            AffixType := "Comp. Prefix"
            ValueRange := LookupAffixData(IPDARPath, ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        CompIPDARPrefixPrefix:
            NumPrefixes += 1
            AffixType := "Comp. Prefix+Prefix"
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        }

        IfInString, A_LoopField, 格擋與暈眩回復
        {
            AffixType := "Prefix"
            If (HasHybridDefences)
            {
                AffixType := "Comp. Prefix"
                BSRecAffixPath := "data\StunRecovery_Hybrid.txt"
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType =
                    If (HasIncrArmourAndEvasion)
                    {
                        PartialAffixString := "護甲與閃避" ;"increased Armour and Evasion"
                    }
                    If (HasIncrEvasionAndES) 
                    {
                        PartialAffixString := "閃避與能量護盾" ;"increased Evasion and Energy Shield"
                    }
                    If (HasIncrArmourAndES)
                    {
                        PartialAffixString := "護甲與能量護盾" ;"increased Armour and Energy Shield"
                    }
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
;                        msgbox, NumPrefixes: %NumPrefixes%`, NumSuffixes: %NumSuffixes%`, BSRest: %BSRest%`, BSRecPartial: %BSRecPartial%
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRest := CurrValue - RangeMid(BSRecPartial)
                                BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        If (CompStatAffixType == "Comp. Prefix+Prefix" and NumSuffixes < 3)
                                        {
                                            AffixType := "Comp. Prefix+Suffix"
                                            BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
                                            NumSuffixes += 1
                                            If (Not IsValidBracket(BSRecSuffixBracket))
                                            {
                                                ; TODO: properly deal with this quick fix!
                                                ;
                                                ; if this point is reached this means that the parts that give to 
                                                ; increased armor/evasion/es/hybrid + stun recovery need to fully be
                                                ; re-evaluated.
                                                ;
                                                ; take an ilvl 62 item with these 2 lines:
                                                ;
                                                ;   118% increased Armour and Evasion
                                                ;   24% increased Block and Stun Recovery
                                                ;
                                                ; Since it's ilvl 62, we assume the hybrid + stun recovery bracket to be the
                                                ; highest possible (lvl 60 bracket), which is 42-50. So that's max 50 of the 
                                                ; 118 dealth with.
                                                ; Consequently, that puts the stun recovery partial at 14-15 for the lvl 60 bracket.
                                                ; This now leaves, 68 of hybrid defence to account for, which we can do by assuming
                                                ; the remainder to come from a hybrid defence prefix. So that's incr. Armour and Evasion
                                                ; identified as CP+P
                                                ; However, here come's the problem, our lvl 60 bracket had 14-15 stun recovery which
                                                ; assuming max, leaves 9 remainder (24-15) to account for. Should be easy, right?
                                                ; Just assume the rest comes from a stun recovery suffix and look it up. Except the
                                                ; lowest possible entry for a stun recovery suffix is 11! Leaving us with the issues that
                                                ; we know that CP+P is right for the hybrid + stun recovery line and CP+S is right for the
                                                ; stun recovery line. 
                                                ; Most likely, what is wrong is the assumption earlier to take the highest possible
                                                ; hybrid + stun recovery bracket. Problem is that wasn't apparent when hybrid defences
                                                ; was processed.
                                                ; At this point, a quick fix what I am doing is I just look up the complete stun recovery
                                                ; value as if it were a suffix completely but still mark it as CP+S.
                                                ; To deal with this correctly I would need to reprocess the hybrid + stun recovery line here
                                                ; with a different ratio of the CP part to the P part to get a lower BSRecPartial.
                                                ;
                                                BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                            Else
                                            {
                                                ValueRange := AddRange(BSRecSuffixBracket, BSRecPartial)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                        } 
                                        Else
                                        {
                                            AffixType := "Suffix"
                                            ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                            If (NumSuffixes < 3)
                                            {
                                                NumSuffixes += 1
                                            }
                                            ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                        }
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }
                                }
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                }
                Else
                {
;                    msgbox, % CurrValue
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                AffixType := "Comp. Prefix"
                If (HasIncrArmour)
                {
                    PartialAffixString := "護甲" ;"increased Armour"
                    BSRecAffixPath := "data\StunRecovery_Armour.txt"
                }
                If (HasIncrEvasion) 
                {
                    PartialAffixString := "閃避" ;"increased Evasion Rating"
                    BSRecAffixPath := "data\StunRecovery_Evasion.txt"
                }
                If (HasIncrEnergyShield)
                {
                    PartialAffixString := "能量護盾" ;"increased Energy Shield"
                    BSRecAffixPath := "data\StunRecovery_EnergyShield.txt"
                }
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRest := CurrValue - RangeMid(BSRecPartial)
                                BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        AffixType := "Suffix"
                                        ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                        If (NumSuffixes < 3)
                                        {
                                            NumSuffixes += 1
                                        }
                                        ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }

                                } 
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                    Else
                    {
                        BSRecSuffixPath := "data\StunRecovery_Suffix.txt"
                        BSRecSuffixBracket := LookupAffixBracket(BSRecSuffixPath, ItemLevel, CurrValue)
                        If (IsValidBracket(BSRecSuffixBracket))
                        {
                            AffixType := "Suffix"
                            ValueRange := LookupAffixData(BSRecSuffixPath, ItemLevel, CurrValue, "", CurrTier)
                            If (NumSuffixes < 3)
                            {
                                NumSuffixes += 1
                            }
                        }
                        Else
                        {
                            BSRecPrefixPath := "data\StunRecovery_Prefix.txt"
                            BSRecPrefixBracket := LookupAffixBracket(BSRecPrefixPath, ItemLevel, CurrValue)
                            ValueRange := LookupAffixData(BSRecPrefixPath, ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
                Else
                {
;                    msgbox, BSRecAffixBracket: %BSRecAffixBracket%
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; AR is one tough beast... currently there are the following affixes affecting AR:
        ; 1) "Accuracy Rating" (Suffix)
        ; 2) "Local Accuracy Rating" (Suffix)
        ; 3) "Light Radius / + Accuracy Rating" (Suffix) - only the first 2 entries, bc last entry combines LR with #% increased Accuracy Rating instead!
        ; 4) "Local Physical Dmg +% / Local Accuracy Rating" (Prefix)

        ; the difficulty lies in those cases that combine multiple of these affixes into one final display value
        ; currently I try and tackle this by using a trickle-through partial balance approach. That is, go from
        ; most special case to most normal, while subtracting the value that each case most likely contributes
        ; until you have a value left that can be found in the most nominal case
        ;
        ; Important to note here: 
        ;   ARPartial will be set during the "increased Physical Damage" case above
        
        IfInString, A_LoopField, 點命中
        {
            ; trickle-through order:
            ; 1) increased AR, Light Radius, all except Belts, Comp. Suffix
            ; 2) to AR, Light Radius, all except Belts, Comp. Suffix
            ; 3) increased Phys Damage, to AR, Weapons, Prefix
            ; 4) to AR, all except Belts, Suffix

            ValueRangeAR := "0-0"
            AffixType := ""
            IPDAffixType := GetAffixTypeFromProcessedLine("`% 物理傷害" /* "increased Physical Damage" */)
            If (HasIncrLightRadius and Not HasIncrAccuracyRating) 
            {
                ; "of Shining" and "of Light"
                LightRadiusValue := ExtractValueFromAffixLine(ItemDataChunk, "`% 照亮範圍" /* "increased Light Radius" */)
                
                ; get bracket level of the light radius so we can look up the corresponding AR bracket
                BracketLevel := 0
                LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LightRadiusValue, BracketLevel)
                ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", BracketLevel)

                AffixType := AffixType . "Comp. Suffix"
                ValueRange := LookupAffixData("data\AccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
                NumSuffixes += 1

                If (ARPartial)
                {
                    ; append this affix' contribution to our partial AR range
                    ARPartial := AddRange(ARPartial, ARLRBracket)
                }
;                msgbox, ARLRBracket: %ARLRBracket%, ARPartial: %ARPartial%
                ; test if candidate range already covers current  AR value
                If (WithinBounds(ARLRBracket, CurrValue))
                {
                    Goto, FinalizeAR
                }
                Else
                {
                    AffixType := "Comp. Suffix+Suffix"
                    If (HasIncrPhysDmg)
                    {
                        If (ARPartial)
                        {
                            CombinedRange := AddRange(ARLRBracket, ARPartial)
;                            msgbox, CombinedRange: %CombinedRange%
                            AffixType := "Comp. Prefix+Comp. Suffix"
                            If (WithinBounds(CombinedRange, CurrValue))
                            {
                                If (NumPrefixes < 3)
                                {
                                    NumPrefixes += 1
                                }
                                ValueRange := CombinedRange
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                Goto, FinalizeAR
                            }
                            Else
                            {
                                NumSuffixes -= 1
                            }
                        }

;                        msgbox, IPDAffixType: %IPDAffixType%
                        If (InStr(IPDAffixType, "Comp. Prefix"))
                        {
;                            AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 1
                            }
                        }
                    }
                    ARRest := CurrValue - RangeMid(ARLRBracket)
                    ARBracket := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ARRest)
                    ValueRange := AddRange(ARBracket, ARLRBracket)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                    NumSuffixes += 1
                    Goto, FinalizeAR
                }
            }
            If (ItemBaseType == "Weapon" and HasIncrPhysDmg)
            {
                ; this is one of the trickiest cases currently: if this If-construct is reached that means the item has 
                ; multiple composites - "To Accuracy Rating / Increased Light Radius" and "Increased Physical Damage 
                ; / To Accuracy Rating". On top of that it might also contain part "To Accuracy Rating" suffix, all of
                ; which are concatenated into one single "to Accuracy Rating" entry. Currently it handles most cases, 
                ; if not all, but I still have a feeling I am missing something...
                If (ARPartial)
                {
                    If (WithinBounds(ARPartial, CurrValue))
                    {
                        AffixType := "Comp. Prefix"
                        If (NumPrefixes < 3)
                        {
                            NumPrefixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, RangeMid(ARPartial), "", CurrTier)
                        Goto, FinalizeAR
                    }

                    ARPartialMid := RangeMid(ARPartial)
                    ARRest := CurrValue - ARPartialMid
                    If (ItemSubType == "Mace" and ItemGripType == "2H")
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ARRest)
                    }
                    Else
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Local.txt", ItemLevel, ARRest)
                    }

                    ; msgbox, ItemLevel: %ItemLevel%`, ARRest: %ARRest%`, ARBracket: %ARBracket%`, ARPartial: %ARPartial%
                    
                    If (IsValidBracket(ARBracket))
                    {
                        AffixType := "Comp. Prefix+Suffix"
                        If (NumSuffixes < 3) 
                        {
                            NumSuffixes += 1
                        }
                        Else
                        {
                            AffixType := "Comp. Prefix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 2
                            }
                        }
                        NumPrefixes += 1
;                        msgbox, ARBracket: %ARBracket%`, ARPartial: %ARPartial%
                        ValueRange := AddRange(ARBracket, ARPartial)
                        ValueRange := MarkAsGuesstimate(ValueRange)

                        Goto, FinalizeAR
                    }
                }
                Else
                {
                    ActualValue := CurrValue
                }

                ValueRangeAR := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ActualValue)
                If (IsValidBracket(ValueRangeAR))
                {
                    If (NumPrefixes >= 3)
                    {
                        AffixType := "Suffix"
                        If (NumSuffixes < 3)
                        {
                            NumSuffixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_Local.txt", ItemLevel, ActualValue, "", CurrTier)
                    }
                    Else
                    {
                        IfInString, IPDAffixType, Comp. Prefix
                        {
                            AffixType := "Comp. Prefix"
                        }
                        Else
                        {
                            AffixType := "Prefix"
                        }
                        NumPrefixes += 1
                    }
                    Goto, FinalizeAR
                }
                Else
                {
                    ARValueRest := CurrValue - (RangeMid(ValueRangeAR))
                    If (HasIncrLightRadius and Not HasIncrAccuracyRating)
                    {
                        AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                    }
                    Else
                    {
                        AffixType := "Comp. Prefix+Suffix"
                    }
                    NumPrefixes += 1
                    NumSuffixes += 1
;                    ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                    ValueRange := AddRange(ARPartial, ValueRangeAR)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                }
                ; NumPrefixes should be incremented already by "increased Physical Damage" case
                Goto, FinalizeAR
            }
            AffixType := "Suffix"
            ValueRange := LookupAffixData("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, "", CurrTier)
            NumSuffixes += 1
            Goto, FinalizeAR

        FinalizeAR:
            If (StrLen(ARAffixTypePartial) > 0 AND (Not InStr(AffixType, ARAffixTypePartial)))
            {
                AffixType := ARAffixTypePartial . "+" . AffixType
                If (InStr(ARAffixTypePartial, "Prefix") AND NumPrefixes < 3)
                {
                    NumPrefixes += 1
                }
                Else If (InStr(ARAffixTypePartial, "Suffix") AND NumSuffixes < 3)
                {
                    NumSuffixes += 1
                }
                ARAffixTypePartial =
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, 物品稀有度
        {
            ActualValue := CurrValue
            If (NumSuffixes <= 3)
            {
                ValueRange := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
            }
            Else
            {
                ValueRange := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
            }
            If (Not IsValidBracket(ValueRange))
            {
                If (Not IsValidBracket(ValueRangeAlt))
                {
                    NumPrefixes += 1
                    NumSuffixes += 1
                    ; try to reverse engineer composition of both ranges
                    PrefixDivisor := 1
                    SuffixDivisor := 1
                    Loop
                    {
                        ValueRangeSuffix := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, Floor(ActualValue/SuffixDivisor))
                        ValueRangePrefix := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, Floor(ActualValue/PrefixDivisor))
                        If (Not IsValidBracket(ValueRangeSuffix))
                        {
                            SuffixDivisor += 0.25
                        }
                        If (Not IsValidBracket(ValueRangePrefix))
                        {
                            PrefixDivisor += 0.25
                        }
                        If ((IsValidBracket(ValueRangeSuffix)) and (IsValidBracket(ValueRangePrefix)))
                        {
                            Break
                        }
                    }
                    ValueRange := AddRange(ValueRangePrefix, ValueRangeSuffix)
                    Goto, FinalizeIIRAsPrefixAndSuffix
                }
                Else
                {
                    ValueRange := ValueRangePrefix
                    Goto, FinalizeIIRAsPrefix
                }
            }
            Else
            {
                If (NumSuffixes >= 3) {
                    Goto, FinalizeIIRAsPrefix
                }
                Goto, FinalizeIIRAsSuffix
            }

            FinalizeIIRAsPrefix:
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IIR_Prefix.txt", ItemLevel, ActualValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsSuffix:
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IIR_Suffix.txt", ItemLevel, ActualValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsPrefixAndSuffix:
                ValueRange := MarkAsGuesstimate(ValueRange)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix+Suffix", ValueRange, CurrTier), A_Index)
                Continue
        }
    }
}

; change a detail line that was already processed and added to the 
; AffixLines "stack". This can be used for example to change the
; affix type when more is known about a possible affix combo. 
; For example with a IPD / AR combo, if IPD was thought to be a
; prefix but later (when processing AR) found to be a composite
; prefix.
ChangeAffixDetailLine(PartialAffixString, SearchRegex, ReplaceRegex)
{
    Global
    Loop, %NumAffixLines%
    {
        CurAffixLine := AffixLines%A_Index%
        IfInString, CurAffixLine, %PartialAffixString%
        {
            local NewLine
            NewLine := RegExReplace(CurAffixLine, SearchRegex, ReplaceRegex)
            AffixLines%A_Index% := NewLine
            return True
        }
    }
    return False
}

ExtractValueFromAffixLine(ItemDataChunk, PartialAffixString)
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        IfInString, A_LoopField, %PartialAffixString%
        {
            return CurrValue
        }
    }
}

ResetAffixDetailVars()
{
    Global
    NumPrefixes := 0
    NumSuffixes := 0
    TotalAffixes := 0
    Loop, %NumAffixLines%
    {
        AffixLines%A_Index% = 
    }
    Loop, 3
    {
        AffixLineParts%A_Index% =
    }
}

IsEmptyString(String)
{
    If (StrLen(String) == 0)
    {
        return True
    }
    Else
    {
        String := RegExReplace(String, "[\r\n ]", "")
        If (StrLen(String) < 1)
        {
            return True
        }
    }
    return False
}

PreProcessContents(CBContents)
{
    ; place fixes for data inconsistencies here

    ; I have not determined the reason for this, but a Heartbreaker - a unique - linked in chat 
    ; showed the following line below the Rarity: ... bit:
    ; You cannot use this item. Its stats will be ignored. Please remove it.`n--------
    ; This of course throws off subsequent parsing attempts so it is best to fix it beforehand.
    Needle := "You cannot use this item. Its stats will be ignored. Please remove it.`r`n--------`r`n"
    StringReplace, CBContents, CBContents, %Needle%, 

    return CBContents
}

PostProcessData(ParsedData)
{
    Global CompactAffixTypes
    If (CompactAffixTypes > 0)
    {
        StringReplace, TempResult, ParsedData, --------, ``, All  
        StringSplit, ParsedDataParts, TempResult, ``
		
        NameAndDPSPart := ParsedDataParts1
        SecondPart := ParsedDataParts2 ; total affix statistics for rare items or implicit mods for unique items
        ThirdPart := ParsedDataParts3 ; affix composition for rare and unique items
        FourthPart := ParsedDataParts4 ; Valuable line for unique items

        ThirdPart := RegExReplace(ThirdPart, "Comp\. ", "複")
        ThirdPart := RegExReplace(ThirdPart, "Suffix",  "後")
        ThirdPart := RegExReplace(ThirdPart, "Prefix",  "前")
		
		
        ParsedData := NameAndDPSPart 
        If (Not IsEmptyString(SecondPart)) ; two because of possible newline control chars
        {
            ParsedData := ParsedData . "--------" . SecondPart 
        }
        If (Not IsEmptyString(ThirdPart))
        {
            ParsedData := ParsedData . "--------" . ThirdPart
        }
        If (Not IsEmptyString(FourthPart))
        {
            ParsedData := ParsedData . "--------" . FourthPart
        }
    }

    return ParsedData
}

; start here
ParseClipBoardChanges()
{
    Global PutResultsOnClipboard

    CBContents := GetClipboardContents()
    CBContents := PreProcessContents(CBContents)

    ParsedData := ParseItemData(CBContents)
    ParsedData := PostProcessData(ParsedData)

    If (PutResultsOnClipboard > 0)
    {
        SetClipboardContents(ParsedData)
    }
    ShowToolTip(ParsedData)
}

AssembleDamageDetails(FullItemData)
{
    PhysLo := 0
    PhysHi := 0
    Quality := 0
    AttackSpeed := 0
    PhysMult := 0
    ChaoLo := 0
    ChaoHi := 0
    ColdLo := 0
    ColdHi := 0
    FireLo := 0
    FireHi := 0
    LighLo := 0
    LighHi := 0

    Loop, Parse, FullItemData, `n, `r
    {        
        ; Get quality
        IfInString, A_LoopField, 品質:
        {
            StringSplit, Arr, A_LoopField, %A_Space%, +`%
            Quality := Arr2
            Continue
        }
        
        ; Get total physical damage
        IfInString, A_LoopField, 物理傷害:
        {
;            IsWeapon := True
            StringSplit, Arr, A_LoopField, %A_Space%
            StringSplit, Arr, Arr2, -
            PhysLo := Arr1
            PhysHi := Arr2
            Continue
        }
        
        ; Fix for Elemental damage only weapons. Like the Oro's Sacrifice
        IfInString, A_LoopField, 元素傷害:
        {
            Continue
        }

        ; Get attack speed
        IfInString, A_LoopField, 每秒攻擊次數:
        {
            StringSplit, Arr, A_LoopField, %A_Space%
            AttackSpeed := Arr2
            Continue
        }
        
        ; Get percentage physical damage increase
        IfInString, A_LoopField, `% 物理傷害 and IfInString, A_LoopField, 增加
        {
            StringSplit, Arr, A_LoopField, %A_Space%, `%
            PhysMult := Arr2
            Continue
        }
        
        ;Lines to skip fix for converted type damage. Like the Voltaxic Rift
        IfInString, A_LoopField, 轉換為
            Goto, SkipDamageParse
        IfInString, A_LoopField, 可以感電
            Goto, SkipDamageParse

        ; Lines to skip for weapons that alter damage based on if equipped as
        ; main or off hand. In that case skipp the off hand calc and just use
        ; main hand as determining factor. Examples: Dyadus, Wings of Entropy
        IfInString, A_LoopField, 在副手
            Goto, SkipDamageParse

        ; Parse elemental damage
		
        ParseElementalDamage(A_LoopField, "混沌", ChaoLo, ChaoHi)
        ParseElementalDamage(A_LoopField, "冰冷", ColdLo, ColdHi)
        ParseElementalDamage(A_LoopField, "火焰", FireLo, FireHi)
        ParseElementalDamage(A_LoopField, "閃電", LighLo, LighHi)
        
        SkipDamageParse:
            DoNothing := True
    }
    
    Result =

    SetFormat, FloatFast, 5.1
    PhysDps := ((PhysLo + PhysHi) / 2) * AttackSpeed
    EleDps := ((ChaoLo + ChaoHi + ColdLo + ColdHi + FireLo + FireHi + LighLo + LighHi) / 2) * AttackSpeed
    TotalDps := PhysDps + EleDps
    
    Result := Result . "`n物理 DPS:" . StrPad(PhysDps, 8, Side="left") 
    Result := Result . "`n元素 DPS:" . StrPad(EleDps, 8, Side="left") 
    Result := Result . "`n總合 DPS:" . StrPad(TotalDps, 8, Side="left")
    
    ; Only show Q20 values if item is not Q20
    If (Quality < 20) {
        TotalPhysMult := (PhysMult + Quality + 100) / 100
        BasePhysDps := PhysDps / TotalPhysMult
        Q20Dps := BasePhysDps * ((PhysMult + 120) / 100) + EleDps
        
        Result := Result . "`nQ20  DPS:" . StrPad(Q20Dps, 8, Side="left")
    }

    return Result
}

ParseItemName(ItemDataChunk, ByRef ItemName, ByRef ItemTypeName)
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If (A_Index == 1)
        {
            IfNotInString, A_LoopField, Rarity:
            {
                return
            }
            Else
            {
                Continue
            }
        }
        If (StrLen(A_LoopField) == 0 or A_LoopField == "--------" or A_Index > 3)
        {
            return
        }
        If (A_Index = 2)
        {
            ItemName := A_LoopField
        }
        If (A_Index = 3)
        {
            ItemTypeName := A_LoopField
        }
    }
}

GemIsValuable(ItemName)
{
    Loop, Read, %A_WorkingDir%\data\ValuableGems.txt
    {
        IfInString, ItemName, %A_LoopReadLine%
        {
            return True
        }
    }
    return False
}

UniqueIsValuable(ItemName)
{
    Loop, Read, %A_WorkingDir%\data\ValuableUniques.txt
    {
        IfInString, ItemName, %A_LoopReadLine%
        {
            return True
        }
    }
    return False
}

GemIsDropOnly(ItemName)
{
    Loop, Read, %A_WorkingDir%\data\DropOnlyGems.txt
    {
        IfInString, ItemName, %A_LoopReadLine%
        {
            return True
        }
    }
    return False
}

ParseLinks(ItemData)
{
    HighestLink := 0
    Loop, Parse, ItemData, `n, `r
    {
        IfInString, A_LoopField, Sockets
        {
            LinksString := GetColonValue(A_LoopField)
            If (RegExMatch(LinksString, ".-.-.-.-.-."))
            {
                HighestLink := 6
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-.-."))
            {
                HighestLink := 5
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-."))
            {
                HighestLink := 4
                Break
            }
            If (RegExMatch(LinksString, ".-.-."))
            {
                HighestLink := 3
                Break
            }
            If (RegExMatch(LinksString, ".-."))
            {
                HighestLink := 2
                Break
            }
        }
    }
    return HighestLink
}

; converts a currency stack to chaos
; by looking up the conversion ratio 
; from CurrencyRates.txt
ConvertCurrency(ItemName, ItemStats)
{
    If (InStr(ItemName, "Shard"))
    {
        IsShard := True
        ItemName := "Orb of " . SubStr(ItemName, 1, -StrLen(" Shard"))
    }
    If (InStr(ItemName, "Fragment"))
    {
        IsFragment := True
        ItemName := "Scroll of Wisdom"
    }
    StackSize := SubStr(ItemStats, StrLen("Stack Size:  "))
    StringSplit, StackSizeParts, StackSize, /
    If (IsShard or IsFragment)
    {
        SetFormat, FloatFast, 5.3
        StackSize := StackSizeParts1 / StackSizeParts2
    }
    Else
    {
        SetFormat, FloatFast, 5.2
        StackSize := StackSizeParts1
    }
    ValueInChaos := 0
    Loop, Read, %A_WorkingDir%\data\CurrencyRates.txt
    {
        IfInString, A_LoopReadLine, `;
        {
            ; comment
            Continue
        }
        If (StrLen(A_LoopReadLine) <= 2)
        {
            ; blank line (at most \r\n)
            Continue
        }
        IfInString, A_LoopReadLine, %ItemName%
        {
            StringSplit, LineParts, A_LoopReadLine, |
            ChaosRatio := LineParts2
            StringSplit, ChaosRatioParts,ChaosRatio, :
            ChaosMult := ChaosRatioParts2 / ChaosRatioParts1
            ValueInChaos := (ChaosMult * StackSize)
            ; msgbox, Name: %ItemName%`, StackSize: %StackSize%`, ChaosMult: %ChaosMult%`, ValueInChaos: %ValueInChaos%
        }
    }
    return ValueInChaos
}

; Parse unique affixes from text file database.
; Has wanted side effect of populating AffixLines "array" vars.
; return True if the unique was found the database
ParseUnique(ItemName)
{
    Global
    Local Delim
    Delim := "|"
    ResetAffixDetailVars()
    UniqueFound := False
    Loop, Read, %A_WorkingDir%\data\Uniques.txt
    {
        IfInString, A_LoopReadLine, `;
        {
            ; comment
            Continue
        }
        If (StrLen(A_LoopReadLine) <= 2)
        {
            ; blank line
            ; 2 characters at most: \r\n. Don't bother 
            ; checking if they are actually control chars 
            ; or normal letters.
            Continue
        }
        IfInString, A_LoopReadLine, %ItemName%
        {
            StringSplit, LineParts, A_LoopReadLine, |
            NumLineParts := LineParts0
            NumAffixLines := NumLineParts-1 ; exclude item name at first pos
            Local UniqueFound
            UniqueFound := True
            Local AppendImplicitSep
            AppendImplicitSep := False
            Idx := 1
            Loop, % (NumLineParts)
            {
                If (A_Index > 1)
                {
                    Local CurLinePart
                    Local AffixLine
                    Local ValueRange
                    CurLinePart := LineParts%A_Index%
                    IfInString, CurLinePart, :
                    {
                        StringSplit, CurLineParts, CurLinePart, :
                        AffixLine := CurLineParts2
                        ValueRange := CurLineParts1
                        IfInString, ValueRange, @
                        {
                            AppendImplicitSep := True
                            StringReplace, ValueRange, ValueRange, @
                        }
                        ; Make "Attacks per Second" float ranges to be like a double range.
                        ; Since a 2 decimal precision float value is 4 chars wide (#.##)
                        ; when including the radix point this means a float value range 
                        ; is then 9 chars wide. Replacing the "-" with a "," effectively
                        ; makes it so that float ranges are treated as double ranges and
                        ; distributes the bounds over both value range fields. This may 
                        ; or may not be desirable. On the plus side things will align
                        ; nicely, but on the negative side, it will be a bit unclearer that
                        ; both float values constitute a range and not two isolated values.
                        ValueRange := RegExReplace(ValueRange, "(\d+\.\d+)-(\d+\.\d+)", "$1,$2") 
                        IfInString, ValueRange, `,
                        {
                            ; double range
                            StringSplit, ValueRangeParts, ValueRange, `,
                            Local ValueRangeParts
                            Local LowerBound
                            Local UpperBound
                            LowerBound := ValueRangeParts1
                            UpperBound := ValueRangeParts2
                            ValueRange := StrPad(LowerBound, ValueRangeFieldWidth, "left") . AffixDetailDelimiter . StrPad(UpperBound, ValueRangeFieldWidth, "left")
                        }
                        ProcessedLine := AffixLine . Delim . StrPad(ValueRange, ValueRangeFieldWidth, "left")
                        If (AppendImplicitSep)
                        {
                            ProcessedLine := ProcessedLine . "`n" . "--------"
                            AppendImplicitSep := False
                        }
                        AffixLines%Idx% := ProcessedLine
                    }
                    Else
                    {
                        AffixLines%Idx% := CurLinePart
                    }
                    Idx += 1
                }
            }
        }
    }

    return UniqueFound
}

; Main parse function
ParseItemData(ItemData, ByRef RarityLevel="", ByRef NumPrefixes="", ByRef NumSuffixes="")
{
    ; global var access to support user options
    Global ShowItemLevel
	Global ShowMaxSockets
    Global ShowDamageCalculations
    Global ShowAffixTotals
    Global ShowAffixDetails
    Global ShowCurrencyValueInChaos
    Global ShowGemEvaluation
    Global ShowUniqueEvaluation
    Global GemQualityValueThreshold
    Global MarkHighLinksAsValuable

     ; these 4 actually need to be global because
     ; they are used in other functions
    Global ItemBaseType
    Global ItemSubType
    Global ItemGripType
    Global ItemDataRarity

    ; marked " ; d" for debugging (to easily search & replace)
    ; Global ItemData  ; d
    ; Global IsWeapon ; d
    ; Global IsUnidentified ; d
    ; Global IsCurrency ; d
    ; Global ItemLevel ; d
    ; Global ItemDataNamePlate ; d
    ; Global ItemDataStats ; d
    ; Global ItemDataRequirements ; d
    ; Global RequiredAttributes ; d
    ; Global ItemName ; d
    ; Global ItemTypeName ; d
    ; Global RequiredLevel ; d
    ; Global RequiredAttributeValues ; d
    ; Global ItemQuality ; d
    ; Global ItemDataPartsIndexLast ; d
    ; Global ItemDataPartsLast ; d
    ; Global RarityLevel ; d
    ; Global IsFlask ; d
    ; Global IsUnique ; d
    ; Global ItemDataImplicitMods ; d
    ; Global NumPrefixes ; d
    ; Global NumSuffixes ; d
    ; Global NumAffixLines ; d
    ; Global TotalAffixes ; d
    ; Global ItemDataAffixes ; d
    ; Global ItemDataStats ; d
    ; Global AugmentedStats ; d

    ; ItemDataParts0 =
    ; Loop, 10 
    ; {
    ;     ItemDataParts%A_Index% =
    ; }

    ItemDataPartsIndexLast = 
    ItemDataPartsIndexAffixes = 
    ItemDataPartsLast = 
    ItemDataNamePlate =
    ItemDataStats =
    ItemDataAffixes = 
    ItemDataRequirements =
    ItemDataRarity =
    ItemDataLinks =
    ItemName =
    ItemTypeName =
    ItemQuality =
    ItemLevel =
    ItemMaxSockets =
    BaseLevel =
    RarityLevel =  
    TempResult =

    IsWeapon := False
    IsQuiver := False
    IsFlask := False
    IsGem := False
    IsCurrency := False
    IsUnidentified := False
    IsBelt := False
    IsRing := False
    IsUnsetRing := False
    IsBow := False
    IsAmulet := False
    IsSingleSocket := False
    IsFourSocket := False	
    IsThreeSocket := False
    IsMap := False
    IsUnique := False
    IsRare := False

    ItemBaseType =
    ItemSubType =
    ItemGripType =

    ; AHK only allows splitting on single chars, so first 
    ; replace the split string (\r\n--------\r\n) with AHK's escape char (`)
    ; then do the actual string splitting...
    StringReplace, TempResult, ItemData, `r`n--------`r`n, ``, All
    StringSplit, ItemDataParts, TempResult, ``,

    ItemDataNamePlate := ItemDataParts1
    ItemDataStats := ItemDataParts2
    ItemDataRequirements := ItemDataParts3

    ; ParseRequirements(ItemDataRequirements, RequiredLevel, RequiredAttributes, RequiredAttributeValues)
    ; msgbox, RequiredLevel: %RequiredLevel%`, RequiredAttributes: %RequiredAttributes%`, RequiredAttributeValues: %RequiredAttributeValues%

    ParseItemName(ItemDataNamePlate, ItemName, ItemTypeName)

    ; assign length of the "array" so we can either grab the 
    ; last item (if non unique) or the item before last
    ItemDataPartsIndexLast := ItemDataParts0
    ItemDataPartsLast := ItemDataParts%ItemDataPartsIndexLast%
    IfInString, ItemDataPartsLast, Unidentified
    {
        IsUnidentified := True
    }

    ItemQuality := ParseQuality(ItemDataStats)

    ; this function should return the second part of the "Rarity: ..." line
    ; in the case of "Rarity: Unique" it should return "Unique"
    ItemDataRarity := ParseRarity(ItemDataNamePlate)

    ItemDataLinks := ParseLinks(ItemData)

    IsUnique := False
    IfInString, ItemDataRarity, Unique
    {
        IsUnique := True
    }

    IfInString, ItemDataRarity, Rare
    {
        IsRare := True
    }

    IsGem := (InStr(ItemDataRarity, "Gem")) 
    IsCurrency := (InStr(ItemDataRarity, "Currency"))

    If (IsGem)
    {
        RarityLevel := 0
        ItemLevel := ParseItemLevel(ItemData, "Level:")
        ItemLevelWord := "寶石等級:"
    }
    Else
    {
        If (IsCurrency and ShowCurrencyValueInChaos == 1)
        {
            ValueInChaos := ConvertCurrency(ItemName, ItemDataStats)
            If (ValueInChaos)
            {
                CurrencyDetails := ValueInChaos . " Chaos"
            }
        }
        Else
        {
            RarityLevel := CheckRarityLevel(ItemDataRarity)
            ItemLevel := ParseItemLevel(ItemData)
            ItemLevelWord := "物品等級:"
            ParseItemType(ItemDataStats, ItemDataNamePlate, ItemBaseType, ItemSubType, ItemGripType)
        }
    }

    IsBow := (ItemSubType == "Bow")
    IsFlask := (ItemSubType == "Flask")
    IsBelt := (ItemSubType == "Belt")
    IsRing := (ItemSubType == "Ring")
    IsUnsetRing := (IsRing and InStr(ItemDataNamePlate, "Unset Ring"))
    IsAmulet := (ItemSubType == "Amulet")
    IsSingleSocket := (IsUnsetRing)
    IsFourSocket := (ItemSubType == "Gloves" or ItemSubType == "Boots" or ItemSubType == "Helmet")
    IsThreeSocket := ((ItemGripType == "1H" or ItemSubType == "Shield") and Not IsBow)
    IsQuiver := (ItemSubType == "Quiver")
    IsWeapon := (ItemBaseType == "Weapon")
    IsMap := (ItemBaseType == "Map")

    If (Not ItemName) 
    {
        return
    }

    If (IsFlask or IsUnique)
    {
        ; uniques as well as flasks have descriptive text as last item,
        ; so decrement item index to get to the item before last one
        ItemDataPartsIndexAffixes := ItemDataPartsIndexLast - 1
    }
    Else
    {
        ItemDataPartsIndexAffixes := ItemDataPartsIndexLast
    }

    If (ItemDataPartsIndexAffixes = 0)
    {
        ; ItemDataParts doesn't have the parts/text we need. Bail. 
        ; This might be because the clipboard is completely empty.
        return 
    }

    ; hopefully this should now hold the part of the text that
    ; deals with affixes
    ItemDataAffixes := ItemDataParts%ItemDataPartsIndexAffixes%

    ItemDataStats := ItemDataParts%ItemDataParts%2

    If (RarityLevel > 1)
    {
		; Mostly translation here
        ParseAffixes(ItemDataAffixes, ItemLevel, ItemQuality, NumPrefixes, NumSuffixes)
        TotalAffixes := NumPrefixes + NumSuffixes
    }

    ; Start assembling the text for the tooltip
    TT := ItemName 
    If (ItemTypeName)
    {
        TT := TT . "`n" . ItemTypeName 
    }

    If (ShowItemLevel == 1 and Not IsMap)
    {
        TT := TT . "`n"
        TT := TT . ItemLevelWord . StrPad(ItemLevel, 8, Side="left")
        If (Not IsFlask)
        {
            BaseLevel := CheckBaseLevel(ItemTypeName)
            If (BaseLevel)
            {
                TT := TT . "`n" . "基底等級:" . StrPad(BaseLevel, 8, Side="left")
            }
        }
    }
    
    If (ShowMaxSockets == 1 and Not (IsFlask or IsGem or IsCurrency or IsBelt or IsQuiver or IsMap or IsAmulet))
    {
        If (ItemLevel >= 50)
        {
            ItemMaxSockets = 6
        }
        Else If (ItemLevel >= 35)
        {
            ItemMaxSockets = 5
        }
        Else If (ItemLevel >= 28)
        {
            ItemMaxSockets = 4
        }
        Else If (ItemLevel >= 15)
        {
            ItemMaxSockets = 3
        }
        Else
        {
            ItemMaxSockets = 2
        }
        
        If(IsFourSocket and ItemMaxSockets > 4)
        {
            ItemMaxSockets = 4
        }
        Else If(IsThreeSocket and ItemMaxSockets > 3)
        {
            ItemMaxSockets = 3
        }
        Else If(IsSingleSocket)
        {
            ItemMaxSockets = 1
        }

        If (Not IsRing or IsUnsetRing)
        {
            TT := TT . "`n"
            TT := TT . "最大洞數:"
            TT := TT . StrPad(ItemMaxSockets, 8, Side="left")
        }
    }

    If (IsGem and ShowGemEvaluation == 1)
    {
        SepAdded := False
        If (ItemQuality > 0)
        {
            TT = %TT%`n--------
            SepAdded := True
            TT = %TT%`n+%ItemQuality%`%
        }
        If (ItemQuality >= GemQualityValueThreshold or GemIsValuable(ItemName))
        {
            If (Not SepAdded)
            {
                TT = %TT%`n--------
                SepAdded := True
            }
            TT = %TT%`nValuable
        }
        If (GemIsDropOnly(ItemName))
        {
            If (Not SepAdded)
            {
                TT = %TT%`n--------
                SepAdded := True
            }
            TT = %TT%`nDrop Only
        }
    }

    If (IsCurrency)
    {
        TT = %TT%%CurrencyDetails%
    }

    If (IsWeapon and ShowDamageCalculations == 1)
    {
        TT := TT . AssembleDamageDetails(ItemData)
    }
 
    If (IsMap)
    {
        Global mapList
        Global uniqueMapList
        if (IsUnique)
        {
            MapDescription := uniqueMapList[ItemSubType]
        }
        else
        {
            MapDescription := mapList[ItemSubType]
        }

        TT = %TT%`n%MapDescription%
    }
 
    ; Append affix info if rarity is greater than normal (white)
    ; Affix total statistic
    If (ShowAffixTotals = 1)
    {
        If (RarityLevel > 1 and RarityLevel < 4)
        {
            WordPrefixes = 前綴
            WordSuffixes = 後綴

            PrefixLine = 
            If (NumPrefixes > 0) 
            {
                PrefixLine = `n   %NumPrefixes% %WordPrefixes%
            }

            SuffixLine =
            If (NumSuffixes > 0)
            {
                SuffixLine = `n   %NumSuffixes% %WordSuffixes%
            }

            AffixStats =
            If (TotalAffixes > 0 and Not IsUnidentified)
            {
                AffixStats = 詞綴 (%TotalAffixes%):%PrefixLine%%SuffixLine%
                TT = %TT%`n--------`n%AffixStats%
            }
        }
        Else
        {
            If (ItemDataRarity == "Unique")
            {
                If (ParseUnique(ItemName))
                {
                    AffixDetails := AssembleAffixDetails()
                    TT = %TT%`n--------%AffixDetails%
                }
                Else If(Not IsMap)
                {
                    If (IsUnidentified)
                    {
                        TT = %TT%`n--------`n未鑑定
                    }
                    Else
                    {
                        TT = %TT%`n--------`n目前不支援獨特物品
                    }
                }
            }
        }
    }

    ; Detailed affix range infos
    If (ShowAffixDetails = 1)
    {
        If (Not IsFlask AND Not IsUnidentified)
        {
            If (RarityLevel > 1 AND RarityLevel < 4)
            {
                AffixDetails := AssembleAffixDetails()
                TT = %TT%`n--------%AffixDetails%
            }
            Else If ((ItemDataRarity == "Unique"))
            {
                If (Not ShowAffixTotals)
                {
                    ParseUnique(ItemName)
                    TT = %TT%`n--------%AffixDetails%
                }
            }
       }
    }

    If ((IsUnique AND (ShowUniqueEvaluation == 1) AND UniqueIsValuable(ItemName)) OR (MarkHighLinksAsValuable = 1 AND (IsUnique OR IsRare) AND ItemDataLinks >= 5))
    {
        TT = %TT%`n--------`nValuable
    }

    ;msgbox, %TT%
    return TT
}

; Show tooltip, with fixed width font
ShowToolTip(String)
{
    ; Get position of mouse cursor
    Global X
    Global Y
    MouseGetPos, X, Y

    ToolTip, %String%, X - 135, Y + 35
    Global FixedFont
    SetFont(FixedFont)

    ; Set up count variable and start timer for tooltip timeout
    Global ToolTipTimeout := 0
    SetTimer, ToolTipTimer, 100
}

; ############## TESTS #################

TestCaseSeparator := "####################"

RunRareTestSuite(Path, SuiteNumber)
{
    Global TestCaseSeparator

    NumTestCases := 0
    Loop, Read, %Path%
    {  
;        msgbox, % TestCaseText
        IfInString, A_LoopReadLine, %TestCaseSeparator%
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

;    msgbox, NumTestCases: %NumTestCases%
    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%

        NumPrefixes := 0
        NumSuffixes := 0 
        RarityLevel := 0
        TestCaseResult := ParseItemData(TestCase, RarityLevel, NumPrefixes, NumSuffixes)

        StringReplace, TempResult, TestCaseResult, --------, ``, All  
        StringSplit, TestCaseResultParts, TempResult, ``

        NameAndDPSPart := TestCaseResultParts1
        TotalAffixStatsPart := TestCaseResultParts2
        AffixCompositionPart := TestCaseResultParts3

        ; failure conditions
        TotalAffixes := 0
        TotalAffixes := NumPrefixes + NumSuffixes
        InvalidTotalAffixNumber := (TotalAffixes > 6)
        BracketLookupFailed := InStr(TestCaseResult, "n/a")
        CompositeRangeCalcFailed := InStr(TestCaseResult, " - ")

        Prefixes := 0
        Suffixes := 0
        CompPrefixes := 0
        CompSuffixes := 0
        ExtractTotalAffixBalance(AffixCompositionPart, Prefixes, Suffixes, CompPrefixes, CompSuffixes)

        HasDanglingComposites := False
        If (Mod(CompPrefixes, 2)) ; True, if not evenly divisible by 2
        {
            HasDanglingComposites := True
        }
        If (Mod(CompSuffixes, 2))
        {
            HasDanglingComposites := True
        }

        TotalCountByAffixTypes := (Floor(CompPrefixes / 2) + Floor(CompSuffixes / 2) + Prefixes + Suffixes)

;        msgbox, TotalAffixes: %TotalAffixes%`, TotalCountByAffixTypes: %TotalCountByAffixTypes%
        AffixTypesCountedIncorrectly := (Not (TotalCountByAffixTypes == TotalAffixes))
        If (InvalidTotalAffixNumber or BracketLookupFailed or CompositeRangeCalcFailed or HasDanglingComposites or AffixTypesCountedIncorrectly)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls 
        ; (if you reload the script really fast globals vars that are out of date can 
        ; cause failures when there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunUniqueTestSuite(Path, SuiteNumber)
{
    Global TestCaseSeparator

    NumTestCases := 0
    Loop, Read, %Path%
    {  
        IfInString, A_LoopReadLine, %TestCaseSeparator%
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%
        TestCaseResult := ParseItemData(TestCase)

        FailedToSepImplicit := InStr(TestCaseResult, "@")  ; failed to properly seperate implicit from normal affixes
        ; TODO: add more unique item test failure conditions

        If (FailedToSepImplicit)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls 
        ; (if you reload the script really fast globals vars that are out of date can 
        ; cause failures where there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunAllTests()
{
    ; change this to the number of available test suites
    TestDataBasePath = %A_WorkingDir%\extras\tests

    NumRareTestSuites := 4
    RareResults := "Rare Items"
    Loop, %NumRareTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Rares%A_Index%.txt
            TestSuiteResult := RunRareTestSuite(TestSuitePath, A_Index)
            RareResults := RareResults . "`n    " . TestSuiteResult
        }
    }

    NumUniqueTestSuites := 1
    UniqResults := "Unique Items"
    Loop, %NumUniqueTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Uniques%A_Index%.txt
            TestSuiteResult := RunUniqueTestSuite(TestSuitePath, A_Index)
            UniqResults := UniqResults . "`n    " . TestSuiteResult
        }
    }

    msgbox, %RareResults%`n`n%UniqResults%
}

If (RunTests)
{
    RunAllTests()
}

; ########### TIMERS ############

; Tick every 100 ms
; Remove tooltip if mouse is moved or 5 seconds pass
ToolTipTimer:
    ToolTipTimeout += 1
    MouseGetPos, CurrX, CurrY
    MouseMoved := (CurrX - X)**2 + (CurrY - Y)**2 > MouseMoveThreshold**2
    If (MouseMoved or ((UseTooltipTimeout = 1) and (ToolTipTimeout >= ToolTipTimeoutTicks)))
    {
        SetTimer, ToolTipTimer, Off
        ToolTip
    }
    return

OnClipBoardChange:
    Global OnlyActiveIfPOEIsFront
    If (OnlyActiveIfPOEIsFront)
    {
        ; do nothing if Path of Exile isn't the foremost window
        IfWinActive, Path of Exile ahk_class Direct3DWindowClass
        {
            ParseClipBoardChanges()
        }
    }
    Else
    {
        ; if running tests parse clipboard regardless if PoE is foremost
        ; so we can check individual cases from test case text files
        ParseClipBoardChanges()
    }
