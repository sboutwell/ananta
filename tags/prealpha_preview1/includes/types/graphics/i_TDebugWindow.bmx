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

' TMessageWindow is a transparent text area on the screen that shows various messages to the player
Type TDebugWindow
	Field _fontScale:Float = 1			' font size used in the message window
	Field _nrLines:Int					' current number of lines
	Field _L_DebugLines:TList			' a list to hold this window's text lines
	Field _x:Float = 10					' starting x-coordinate for the window
	Field _y:Float = 10					' starting y-coordinate for the window
	Field _defaultColor:TColor			' default font color
	
	' AddText() creates a new text line into the window
	Method AddText(str:String, colString:String = Null) 
		Local col:TColor = Null
		If colSTring Then col = TColor.FindColor(colString)  ' find a color matching the search string
		
		Local line:TDebugLine = TDebugLine.Create(str, col) 
		If Not _L_DebugLines Then _L_DebugLines = CreateList()    	' create a list if necessary
		_L_DebugLines.AddLast line	' add the newly created object to the end of the list
		_nrLines = _nrLines + 1

	EndMethod
	
	Method DrawAllLines()
		If Not _L_DebugLines Then Return

		AutoMidHandle False
		SetBlend AlphaBlend
		SetRotation(0)
		SetScale(_fontScale, _fontScale) 

		Local lineNr:Int = 0
		For Local line:TDebugLine = EachIn _L_DebugLines
			line.Draw(_x, _y + (15.0 * lineNr * _fontScale)) 
			lineNr = lineNr + 1
		Next
		
		' after drawing all debug lines, clear the list
		_L_DebugLines.Clear() 
	End Method
	
	Function Create:TDebugWindow(x:Int, y:Int) 
		Local dw:TDebugWindow = New TDebugWindow
		dw._fontScale = 1
		dw._x = x
		dw._y = y
		Return dw	' returns a pointer to the newly created message window
	End Function
	
End Type

Type TDebugLine
	Field _lineString:String		' string containing the actual text data
	Field _color:TColor			' color of the line
	
	Method Draw(x:Float, y:Float) 
		SetBlend(AlphaBlend)
		SetAlpha(1) 
		If _color Then SetColor(_color.GetRed(), _color.GetGreen(), _color.GetBlue()) 
		If Not _color Then SetColor (255, 255, 255) 
		DrawText(_lineString, x, y) 
	EndMethod
	
	' Creates a new instance of a debug line
	Function Create:TDebugLine(str:String, col:TColor) 
		Local ml:TDebugLine = New TDebugLine
		ml._lineString = str
		ml._color = col
		Return ml	' returns a pointer to the newly created line
	End Function
EndType
