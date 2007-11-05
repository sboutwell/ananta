' Splits a string into chunks of a specified lenght. 
' Strings are split between words separated by a delimeter (default:space), never in the middle of a word.
' Returns a list of the splitted strings.

Function StringSplitLength:TList(str:string,length:Int,delim:String=Chr(32))
	Local L_strings:TList = CreateList()	' create a list to hold the splitted strings
	
	Local L_delimitedStrings:TList = StringSplit(str,delim)	' split the string into delimited substrings
	
	Local delimCount:Int = L_delimitedStrings.Count()
	If delimCount = 1 Then Return L_delimitedStrings
	
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


' Splits a string delimited by a given string
' Returns a list of the splitted string
Function StringSplit:TList(str:String,delim:String)
	Local L_strings:TList = CreateList()	' list to hold the splitted strings
	Local delimLength:Int = Len delim		
		
	Repeat
		Local pos:Int = str.Find(delim)
		If pos <> -1 Then
			Local splicedStr:String = str[..pos]	' extract a splice from the beginning of the string to the delimiter position
			str = Trim(str[pos+delimLength..])	' splice the extracted substring + the delimiter out of the main string
			L_Strings.AddLast splicedStr	' add the substring to the list
		Else	' no more delimiters found
			L_Strings.AddLast Trim(str)	' add the rest of the string to the list and exit the loop
			Exit
		EndIf
	Forever

	Return L_strings
EndFunction

' "Rounds" a float into a fixed-point string for display
Function FloatToFixedPoint:String(f:Float, decimals:Int=2)
	Local i:Long = (10^decimals)*f
	Local value:String = String.fromlong(i)
		
	If value.length<=decimals
		return "0."+(RSet("",decimals-value.length)).Replace(" ","0")+value
	ElseIf decimals = 0
		return value[0..value.length-decimals]
	Else
		return value[0..value.length-decimals] + "." + value[value.length-decimals..value.length]  
	EndIf
	
End Function

