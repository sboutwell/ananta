' TMessageWindow is a transparent text area on the screen that shows various messages to the player
Type TMessageWindow
	Global g_L_MessageWindows:TList 	' a list to hold all message windows
	Field _fontScale:Float = 1			' font size used in the message window
	Field _maxLineLength:Int	= 30		' max lenght of a single line before wrapping occurs
	Field _fadeEnabled:Int = TRUE		' fading of old messages true/false
	Field _timeToLive:Int = 10			' time in seconds before a line of text fades
	Field _fadeFactor:Float = 0.25		' alpha change per second for fadeout
	Field _maxLines:Int = 15				' max number of simultaneous lines
	Field _nrLines:Int					' current number of lines
	Field _alpha:Float					' alpha blending for a new line
	Field _L_MessageLines:TList			' a list to hold this window's text lines
	Field _x:Float = 10					' starting x-coordinate for the window
	Field _y:Float = 10					' starting y-coordinate for the window
	Field _defaultColor:TColor			' default font color
	
	' CreateMsg() creates a new text message into the message window
	Method CreateMsg(str:String,colString:String)
		Local col:TColor = Null
		If colSTring <> "" Then col = TColor.FindColor(colString) ' find a color matching the search string
		If col = null Then col = _defaultColor ' if no valid color is specified, use the default

		str = "* " + str		' add * to the beginning of the string to indicate starting of a new message
		
		Local L_LineStrings:TList = StringSplitLength(str,_maxLineLength) 	' splits the string into chunks of maximum of g_maxLineLength characters
		
		For Local linestring:String = EachIn L_LineStrings
			Local line:TMessageLine = TMessageLine.Create(linestring, col, _alpha) 
			If Not _L_MessageLines Then _L_MessageLines = CreateList()	' create a list if necessary
			_L_MessageLines.AddLast line	' add the newly created object to the end of the list
			_nrLines = _nrLines + 1
		Next

	EndMethod
	
	Method DrawAllLines()
		If Not _L_MessageLines Then Return
		Local lineNr:Int = 0
		For Local line:TMessageLine = EachIn _L_Messagelines
			line.Draw(_x, _y + (15.0 * lineNr * _fontScale)) 
			If _fadeEnabled And lineNr = 0 Then line.IncrementAge()  	' increase the age of the oldest line only (and only if fadeEnabled = true)
			If line.GetAge() > _timeToLive Then ' start fading out the line
				line.SetLineAlpha(line.GetLineAlpha() - _fadeFactor * G_delta.GetDelta()) 
				If line.GetLinealpha() <= 0 Then
					_L_MessageLines.RemoveFirst	' remove the line if it has completely faded out
					_nrLines = _nrLines - 1
				EndIf
			EndIf
			lineNr = lineNr + 1
			If _nrLines > _maxLines Then 
				_L_MessageLines.RemoveFirst
				_nrLines = _nrLines - 1
			EndIf
		Next
	End Method
	
	' Load variable values from the xml file
	Method InitVariables(xmlfile:TXMLDoc)
		_defaultColor 	= TColor.FindColor(XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/defaultcolor").ToString())
		_fadeEnabled		= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/fadeEnabled").ToInt()
		_timeToLive = (XMLFindFirstMatch(xmlfile, "settings/graphics/messagewindow/ttl").ToInt()) 
		_fadeFactor = (XMLFindFirstMatch(xmlfile, "settings/graphics/messagewindow/fadefactor").ToFloat()) 
		_maxLineLength 	= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/maxlenght").ToInt()
		_maxLines 		= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/maxlines").ToInt()
		_alpha 			= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/alpha").ToFloat()
		_fontscale 		= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/scale").ToFloat()
		_x 				= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/x").ToFloat()
		_y		 		= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/y").ToFloat()

	End Method
	
	Function DrawAll()
		If Not g_L_MessageWindows Then Return	' return if no message windows exist
		
		AutoMidHandle False
		SetBlend AlphaBlend
		SetRotation(0)
		
		For Local window:TMessageWindow = EachIn g_L_MessageWindows
			SetScale(window._fontScale,window._fontScale)
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
	Field _lineString:String		' string containing the actual text data
	Field _color:TColor			' color of the line
	Field _alpha:Float = 1		' alpha blending factor of the line
	Field _age:Float				' age of the line in seconds (updated only if the line is the first line in the window)
	
	Method Draw(x#,y#)
		SetBlend(AlphaBlend)
		SetAlpha(_alpha)
		SetColor(_color.GetRed(),_color.GetGreen(),_color.GetBlue())
		DrawText(_lineString, x, y) 
	EndMethod
	
	Method SetLineAlpha(a:Float)
		_alpha = a
	End Method
	
	Method GetLineAlpha:Float()
		Return _alpha
	End Method
	
	' Add to the age of the line
	Method IncrementAge() 
		_age = _age + 1 * G_delta.GetDelta() 
	End Method
	
	Method GetAge:Int()
		Return _age
	End Method
	
	' Creates a new instance of a message line
	Function Create:TMessageLine(str:String,col:TColor,al:Float)
		Local ml:TMessageLine = New TMessageLine
		ml._lineString = str
		ml._color = col
		ml._alpha = al
		Return ml	' returns a pointer to the newly created line
	End Function
EndType
