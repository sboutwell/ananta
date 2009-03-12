rem
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

' TColor is a type handling mapping of named colors (colors.xml) into their equivalent RGB values
Type TColor Final
	Global g_L_Colors:TList ' list containing all colors
	Field _name:String		' name of the color
	Field _red:Int			' red component
	Field _green:Int			' green component
	Field _blue:Int			' blue component

	Method GetRed:Int() Return _red	End Method
	Method GetGreen:Int() Return _green	End Method
	Method GetBlue:Int() Return _blue End Method
	Method GetName:String() Return _name End Method
	
	Function GetRGB(r:Int var, g:Int var, b:Int var, col:TColor)
		r = col.GetRed()
		g = col.GetGreen()
		b = col.GetBlue()
	End Function
	
	' SetTColor() is a SetColor replacement that uses named colors instead of RGB values
	' Is a fast enough function to be used in the main loop
	Function SetTColor(color:TColor) 
		SetColor(color.GetRed(), color.GetGreen(), color.GetBlue()) 
		Return
	End Function

	' FindColor takes the color name as a search string and returns the matching TColor object
	' FindColor is a relatively slow function, so don't call it in the main loop
	Function FindColor:TColor(colorname:String) 
		If Not g_L_Colors Then DebugLog "FindColor: no colors defined" ; Return Null	' return if the list is empty
		
		For Local color:TColor = EachIn g_L_Colors
			If color.GetName() = colorname Then Return color	' Matching color found, return the object
		Next

		DebugLog "FindColor: no color matching the name '" + colorname + "' found"
		Return Null
	End Function

	
	' LoadAll() parses colors.xml and creates a TColor type instance for each color found in the file
	Function LoadAll() 
		DebugLog "    Loading color info..."
		Local colornode:TxmlNode = LoadXMLFile(c_colorsFile)
		' ------------------------------------------------------------------------------------
		' Creating instance of each found color
		' ------------------------------------------------------------------------------------
		Local children:TList = colornode.getChildren() 			' get all color names
		For colornode = EachIn children							' iterate through colors
			'Print "      Color found: " + colornode.GetName()
			Local color:TColor = TColor.Create(colornode.GetName())	' create a color prototype instance
			
			Local colorChildren:TList = colornode.getChildren()
			' search the color node to find RGB info and save them into fields
			For Local value:TxmlNode = EachIn colorChildren	' iterate through values
				If value.GetName() = "r" Then color._red	= value.GetText().ToInt()
				If value.GetName() = "g" Then color._green 	= value.GetText().ToInt()
				If value.GetName() = "b" Then color._blue	= value.GetText().ToInt()
			Next
		Next
		DebugLog "    Colors loaded."
		Return
	EndFunction

	Function Create:TColor(colorname:String)
		Local c:TColor = New TColor ' create an instance
		c._name = colorname			' give a name

		If Not g_L_Colors Then g_L_Colors = CreateList()	' create a list if necessary
		g_L_Colors.AddLast c	' add the newly created object to the end of the list
		
		Return c	' return the pointer to this specific object instance
	End Function

End Type
