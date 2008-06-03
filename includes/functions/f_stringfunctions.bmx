Rem
This file is part of Ananta.

    Ananta is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ananta is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ananta.  If not, see <http://www.gnu.org/licenses/>.


Copyright 2007, 2008 Jussi Pakkanen
endrem

' Splits a string into chunks of a specified lenght. 
' Strings are split between words separated by a delimeter (default:space), never in the middle of a word.
' Returns a list of the splitted strings.

Function StringSplitLength:TList(str:String,length:Int,delim:String=Chr(32))
	Local L_strings:TList = CreateList()	' create a list to hold the splitted strings
	
	Local L_delimitedStrings:String[] = SmartSplit(str, delim)	' split the string into delimited substrings
	
	Local delimCount:Int = L_delimitedStrings.Length
	'If delimCount = 1 Then Return L_delimitedStrings
	
	Local tempString:String = ""
	
	Local counter:Int = 0
	
	For Local delimStr:String = EachIn L_delimitedStrings ' iterate through the delimited strings
		counter = counter + 1
		If tempString = "" Then
			tempString = delimStr + delim
			If counter = delimCount Then L_strings.AddLast tempString
		ElseIf Len (tempString + delimStr) > length Then
			L_strings.AddLast tempString
			tempString = "  " + delimStr + delim
			If counter = delimCount Then L_strings.AddLast tempString
		Else
			tempString = tempString + delimStr + delim
			If counter = delimCount Then L_strings.AddLast tempString
		EndIf
	Next
	
	Return L_strings
EndFunction


'###############################################################################
' Split a string into substrings
' From http://www.blitzbasic.com/codearcs/codearcs.php?code=1560
' by CoderLaureate, bug fix by Chris Eykamp
' This code has been declared by its author to be Public Domain code.
Function SmartSplit:String[] (str:String, dels:String, text_qual:String = "~q") 
	Local Parms:String[] = New String[1]
	Local pPtr:Int = 0
	Local chPtr:Int = 0
	Local delPtr:Int = 0
	Local qt:Int = False
	Local str2:String = ""
	
	Repeat
		Local del:String = Chr(dels[delPtr])
		Local ch:String = Chr(str[chPtr])
		If ch = text_qual Then 
			If qt = False Then
				qt = True
			Else
				qt = False
			End If
		End If
		If ch = del Then
			If qt = True Then str2:+ ch
		Else
			str2:+ ch
		End If
		If ch = del Or chPtr = str.Length - 1 Then
			If qt = False Then
				Parms[pPtr] = str2.Trim()
				str2 = ""
				pPtr:+ 1
				Parms = Parms[..pPtr + 1]
				If dels.length > 1 And delPtr < dels.length Then delPtr:+ 1
			End If
		End If
		chPtr:+ 1
		If chPtr >= str.Length Then Exit
	Forever
	If Parms.Length > 1 Then Parms = Parms[..Parms.Length - 1]
	Return Parms
			
End Function	

' "Rounds" a float into a fixed-point string for display
Function FloatToFixedPoint:String(f:Float, decimals:Int=2)
	Local i:Long = (10^decimals)*f
	Local value:String = String.fromlong(i)
		
	If value.length<=decimals
		'return "0."+(RSet("",decimals-value.length)).Replace(" ","0")+value
		Return "0." + ""[Len("") - decimals - value.Length..].Replace(" ", "0") + value
	ElseIf decimals = 0
		Return value[0..value.Length - decimals] 
	Else
		Return value[0..value.length-decimals] + "." + value[value.length-decimals..value.length]  
	EndIf
	
End Function

' capitalizes the FIRST letter of a string
Function ProperCase:String(str:String)
	Return Chr(str[0]).ToUpper() + str[1..]
End Function

' this method will return an array of integers from the planetChance string
' this will allow us to pick a number from it quickly
'
' Yet Another String to Array Routine - BMX by altitudems
' http://www.blitzbasic.com/codearcs/codearcs.php?code=1417
' This code has been declared by its author to be Public Domain code.

Function StringToIntArray:Int [] (_String:String, _Delimiter:String)
	Local TempArray:Int [1]
	Local TempString:String
	While _String.Find(_Delimiter) <> -1
		TempString = _String[.._String.Find(_Delimiter)]
		_String = _String[TempString.Length+1..]
		TempArray[TempArray.Length - 1] = Int(TempString)
		TempArray = TempArray[..TempArray.Length+1]
	Wend
	TempString = _String
	TempArray[TempArray.Length - 1] = Int(TempString)
	Return TempArray
End Function

