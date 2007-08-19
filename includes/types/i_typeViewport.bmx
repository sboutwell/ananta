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

' -----------------------------------------------------------------
' TViewport contains various draw-to-screen related stuff
' -----------------------------------------------------------------

Type TViewport
	Global g_ResolutionX:Int	
	Global g_ResolutionY:Int	
	Global g_BitDepth:Int
	Global g_FrameRate:Int
	Global g_RefreshRate:Int
	Global g_TargetFrameLength:Int		' the lenght of the frame in milliseconds

	Global g_media_spacedust:TImage		' image global for the "space dust" particle mask
	Global g_media_spaceBG:TImage		' image global for the space background

	Field startX:Int
	Field startY:Int
	Field width:Int
	Field height:Int
	Field midX:Int
	Field midY:Int
	Field cameraPosition_X:Float
	Field cameraPosition_Y:Float
	Field marginalTop:Int
	Field marginalBottom:Int
	Field marginalLeft:Int
	Field marginalRight:Int
	Field borderWidth:Int
	Field borderColor:TColor
	Field msgWindow:TMessageWindow = TMessageWindow.Create() ' create a message window for the viewport
	
	Method InitViewportVariables()
		TViewPort.InitViewportGlobals()	' first load the global values from settings.xml file

		Local xmlfile:TxmlDoc = parseXMLdoc(c_settingsFile)
			' Viewport marginals
			marginalTop				= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/top").ToInt()
			marginalBottom			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/bottom").ToInt()
			marginalLeft			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/left").ToInt()
			marginalRight			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/right").ToInt()
			' Border surrounding the viewport
			borderWidth				= XMLFindFirstMatch(xmlfile,"settings/graphics/border/width").ToInt()
			borderColor 			= TColor.FindColor(XMLFindFirstMatch(xmlfile,"settings/graphics/border/color").ToString())
			' Message window
			msgWindow.defaultColor 	= TColor.FindColor(XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/defaultcolor").ToString())
			msgWindow.timeToLive 	= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/ttl").ToInt()
			msgWindow.maxLineLength = XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/maxlenght").ToInt()
			msgWindow.fontscale 	= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/scale").ToFloat()
			msgWindow.x 			= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/x").ToFloat()
			msgWindow.y		 		= XMLFindFirstMatch(xmlfile,"settings/graphics/messagewindow/y").ToFloat()

		xmlfile.free()

		startX = marginalLeft
		startY = marginalTop

		width		= (TViewport.g_ResolutionX - startX - marginalRight)
		height		= (TViewport.g_ResolutionY - startY - marginalBottom)
		midX		= width / 2
		midY		= height / 2
	EndMethod

	Method DrawLevel(o:TSpaceObject)
	 	'using the object{o} position and direction to draw the map
	
		Rem
			Local TargetScreenOffsetX:Float = (o.xVel) * (C_ScreenWidth/ScreenOffsetMagnitude)  / o.maxSpd
			Local TargetScreenOffsetY:Float = (o.yVel) * (C_ScreenHeight/ScreenOffsetMagnitude) / o.maxSpd
			
			If TargetScreenOffsetX > C_ScreenWidth/ScreenOffsetMagnitude Then TargetScreenOffsetX = C_ScreenWidth/ScreenOffsetMagnitude
			If TargetScreenOffsetY > C_ScreenHeight/ScreenOffsetMagnitude Then TargetScreenOffsetY = C_ScreenHeight/ScreenOffsetMagnitude
			If TargetScreenOffsetX < -(C_ScreenWidth/ScreenOffsetMagnitude) Then TargetScreenOffsetX = -(C_ScreenWidth/ScreenOffsetMagnitude)
			If TargetScreenOffsetY < -(C_ScreenHeight/ScreenOffsetMagnitude) Then TargetScreenOffsetY = -(C_ScreenHeight/ScreenOffsetMagnitude)
			
			If ScreenOffset = False Then 
				TargetScreenOffsetX = 0
				TargetScreenOffsetY = 0
			EndIf
		
			Smooth out the offset transitions to happen over several frames (using globals ScreenOffsetX and Y)
			Elasticity coefficient controls the smoothness factor
			ScreenOffsetX :+ (TargetScreenOffsetX - ScreenOffsetX) * ScreenElasticity*(o.MaxSpd/10)
			ScreenOffsetY :+ (TargetScreenOffsetY - ScreenOffsetY) * ScreenElasticity*(o.MaxSpd/10)
		
	
			CameraPosition_X = o.x + ScreenOffsetX
			CameraPosition_Y = o.y + ScreenOffsetY
	
		EndRem

		CameraPosition_X = o.x
		CameraPosition_Y = o.y

		SetViewport(startX ,startY, width, height)  ' limit the drawing area to viewport margins
	
		SetScale 1,1
		SetBlend AlphaBlend
		SetAlpha 0.7
		TileImage G_media_spaceBG,CameraPosition_X/50,CameraPosition_Y/50
	
		SetBlend AlphaBlend
		SetAlpha 0.85
		SetColor 255,255,255
		TileImage G_media_spacedust,CameraPosition_X,CameraPosition_Y
		
		' draw a colored border around the viewport
		DrawBorder(borderWidth, borderColor)
		
	EndMethod

	Method DrawBorder(w:Int,color:TColor)
		AutoMidHandle False
		SetViewport(0,0, g_ResolutionX, g_ResolutionY)  ' drawing area (whole screen)
		SetBlend SolidBlend
		SetLineWidth(w)
		TColor.SetTColor(color)
		SetRotation(0)
		SetScale(1,1)
		' top border
		DrawLine(startX-w, startY-w, width+startX+w, startY-w)
		' bottom border
		DrawLine(startX-w, startY+height+w, startX+width+w, startY+height+w)
		' left border
		DrawLine(startX-w, startY-w, startX-w, startY+height+w)
		' right border
		DrawLine(startX+width+w, startY-w, startX+width+w, startY+height+w)
	EndMethod

	Method CreateMsg(str:String,colString:String="")
		msgWindow.CreateLine(str,colString)
		TMessageWindow.DrawAll()	' update message windows
	EndMethod
		
	Method DrawMisc()
		TMessageWindow.DrawAll()	' draw message windows
	EndMethod
	
	Function InitGraphicsMode()
		Graphics g_ResolutionX, g_ResolutionY, g_BitDepth, g_RefreshRate, 0
	EndFunction

	Function InitViewportGlobals()
		Local xmlfile:TxmlDoc 	= parseXMLdoc(c_settingsFile)	' load the file into memory
			TViewport.g_ResolutionX		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/x").ToInt()
			TViewport.g_ResolutionY		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/y").ToInt()
			TViewport.g_BitDepth			= XMLFindFirstMatch(xmlfile,"settings/graphics/bitdepth").ToInt()
			TViewport.g_FrameRate			= XMLFindFirstMatch(xmlfile,"settings/graphics/framerate").ToInt()
			TViewport.g_RefreshRate		= XMLFindFirstMatch(xmlfile,"settings/graphics/refreshrate").ToInt()
			
			TViewport.g_media_spacedust 	= LoadImage(c_mediaPath + "spacedust.png")
			TViewport.g_media_spaceBG		= LoadImage(c_mediaPath + "space_bg.jpg")

		xmlfile.free()	' free up the memory
	
		TViewport.g_TargetFrameLength = 1000/TViewport.g_FrameRate		' the lenght of the frame in ms
	EndFunction

	Function Create:TViewport()
		Local vp:TViewport = New TViewport
		Return vp
	EndFunction

EndType

' TMessageWindow is a transparent text area on the screen that shows various messages to the player
Type TMessageWindow
	Global g_L_MessageWindows:TList 	' a list to hold all message windows
	Field fontScale:Float = 1			' font size used in the message window
	Field timeToLive:Int = 40			' time in seconds before a line of text fades
	Field maxLineLength:Int	= 30		' max lenght of a single line before wrapping occurs
	'Field maxLines:Int = 10			' max number of simultaneous lines
	Field L_MessageLines:TList			' a list to hold this window's text lines
	Field x:Float = 10					' starting x-coordinate for the window
	Field y:Float = 10					' starting y-coordinate for the window
	Field defaultColor:TColor			' default font color
	
	' NewLine() creates a new text line into the message window
	Method CreateLine(str:String,colString:String)
		Local col:TColor = Null
		If colSTring <> "" Then col = TColor.FindColor(colString) ' find a color matching the search string
		If col = null Then col = defaultColor ' if no valid color is specified, use the default

		str = "* " + str		' add * to the beginning of the string to indicate starting of a new message
		
		Local L_LineStrings:TList = StringSplitLength(str,maxLineLength) 	' splits the string into chunks of maximum of g_maxLineLength characters
		
		For Local linestring:String = EachIn L_LineStrings
			Local line:TMessageLine = TMessageLine.Create(linestring,col)
			If Not L_MessageLines Then L_MessageLines = CreateList()	' create a list if necessary
			L_MessageLines.AddLast line	' add the newly created object to the end of the list
		Next

	EndMethod

	Method DrawAllLines()
		If Not L_MessageLines Then Return
		Local lineNr:Int = 0
		For Local line:TMessageLine = EachIn L_Messagelines
			line.Draw(x,y + (15 * lineNr * fontScale))
			lineNr = lineNr + 1
		Next
	End Method
	
	Function DrawAll()
		If Not g_L_MessageWindows Then Return
		
		AutoMidHandle False
		'SetViewport(0,0, g_ResolutionX, g_ResolutionY)  ' drawing area (whole screen)
		SetBlend AlphaBlend
		'SetColor(r,g,b)
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
	Field age:Int				' age of the message line in frames
	Field color:TColor			' color of the line
	
	Method Draw(x#,y#)
		SetColor(color.red,color.green,color.blue)
		DrawText(lineString,x,y)
	EndMethod
	
	' Creates a new instance of a message line
	Function Create:TMessageLine(str:String,col:TColor)
		Local ml:TMessageLine = New TMessageLine
		ml.lineString = str
		ml.color = col
		Return ml	' returns a pointer to the newly created line
	End Function
EndType
