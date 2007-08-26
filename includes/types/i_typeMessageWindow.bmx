Rem
	Naming convention:
	-	All types are named with a T in front (example: TTypeName)
	-	All lists and fields that are global inside a type must begin with g (example: Global g_variableName)
		Note a lower case g as opposed to the capital G for program globals.
	-	All lists are named with L in front of them (example L_ListName)
	
	You can capitalize fields, types and lists as needed for good readability. Use your own judgement.
	
	Thoroughly comment all type definitions, explain their usage and their methods and fields.
	
	Have fun.
EndRem


' TMessageWindow is a transparent text area on the screen that shows various messages to the player
Type TMessageWindow
	Global g_L_MessageWindows:TList 	' a list to hold all message windows
	Field fontScale:Float = 1			' font size used in the message window
	Field maxLineLength:Int	= 30		' max lenght of a single line before wrapping occurs
	Field fadeEnabled:Int = TRUE		' fading of old messages true/false
	Field timeToLive:Int = 10			' time in seconds before a line of text fades
	Field fadeFactor:Float = 0.25		' alpha change per second for fadeout
	Field maxLines:Int = 15				' max number of simultaneous lines
	Field nrLines:Int					' current number of lines
	Field alpha:Float					' alpha blending for a new line
	Field L_MessageLines:TList			' a list to hold this window's text lines
	Field x:Float = 10					' starting x-coordinate for the window
	Field y:Float = 10					' starting y-coordinate for the window
	Field defaultColor:TColor			' default font color
	
	' CreateMsg() creates a new text message into the message window
	Method CreateMsg(str:String,colString:String)
		Local col:TColor = Null
		If colSTring <> "" Then col = TColor.FindColor(colString) ' find a color matching the search string
		If col = null Then col = defaultColor ' if no valid color is specified, use the default

		str = "* " + str		' add * to the beginning of the string to indicate starting of a new message
		
		Local L_LineStrings:TList = StringSplitLength(str,maxLineLength) 	' splits the string into chunks of maximum of g_maxLineLength characters
		
		For Local linestring:String = EachIn L_LineStrings
			Local line:TMessageLine = TMessageLine.Create(linestring,col,alpha)
			If Not L_MessageLines Then L_MessageLines = CreateList()	' create a list if necessary
			L_MessageLines.AddLast line	' add the newly created object to the end of the list
			nrLines = nrLines + 1
		Next

	EndMethod

	Method DrawAllLines()
		If Not L_MessageLines Then Return
		Local lineNr:Int = 0
		For Local line:TMessageLine = EachIn L_Messagelines
			line.Draw(x,y + (15.0 * lineNr * fontScale))
			if self.fadeEnabled And lineNr = 0 Then line.age = line.age + 1 	' increase the age of the oldest line only (and only if fadeEnabled = true)
			if line.age > self.timeToLive Then ' start fading out the line
				line.alpha = line.alpha - self.fadeFactor
				If line.alpha <= 0 Then
					L_MessageLines.RemoveFirst	' remove the line if it has completely faded out
					nrLines = nrLines - 1
				EndIf
			EndIf
			lineNr = lineNr + 1
			If nrLines > self.maxLines Then 
				L_MessageLines.RemoveFirst
				nrLines = nrLines - 1
			EndIf
		Next
	End Method
	
	Function DrawAll()
		If Not g_L_MessageWindows Then Return	' return if no message windows exist
		
		AutoMidHandle False
		SetBlend AlphaBlend
		SetRotation(0)
		
		For Local window:TMessageWindow = EachIn g_L_MessageWindows
			SetScale(window.fontScale,window.fontScale)
			window.DrawAllLines()
		Next
	End Function
	
	Function Create:TMessageWindow()
		Local mw:TMessageWindow = New TMessageWindow

		If Not g_L_MessageWindows Then g_L_MessageWindows = CreateList()	' create a list if necessary
		g_L_MessageWindows.AddLast mw	' add the newly created object to the end of the list
		Return mw	' returns a pointer to the newly created message window
	End Function
	
End Type

Type TMessageLine
	Field lineString:String		' string containing the actual text data
	Field color:TColor			' color of the line
	Field alpha:Float = 1		' alpha blending factor of the line
	Field age:Int				' age of the line in frames (updated only if the line is the first line in the window)
	
	Method Draw(x#,y#)
		SetAlpha(alpha)
		SetColor(color.red,color.green,color.blue)
		DrawText(lineString,x,y)
	EndMethod
	
	' Creates a new instance of a message line
	Function Create:TMessageLine(str:String,col:TColor,al:Float)
		Local ml:TMessageLine = New TMessageLine
		ml.lineString = str
		ml.color = col
		ml.alpha = al
		Return ml	' returns a pointer to the newly created line
	End Function
EndType
