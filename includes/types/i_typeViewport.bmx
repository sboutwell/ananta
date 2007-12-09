' -----------------------------------------------------------------
' TViewport contains various draw-to-screen related stuff
' -----------------------------------------------------------------

Type TViewport
	Global g_ResolutionX:Int	
	Global g_ResolutionY:Int	
	Global g_BitDepth:Int
	Global g_RefreshRate:Int

	Global g_media_spacedust:TImage		' image global for the "space dust" particle mask
	Global g_media_spaceBG:TImage		' image global for the space background

	Field _startX:Int
	Field _startY:Int
	Field _width:Int
	Field _height:Int
	Field _midX:Int
	Field _midY:Int
	Field _cameraPosition_X:Float
	Field _cameraPosition_Y:Float
	Field _centeredObject:TSpaceObject	' the object the camera is centered on
	Field _marginalTop:Int
	Field _marginalBottom:Int
	Field _marginalLeft:Int
	Field _marginalRight:Int
	Field _borderWidth:Int
	Field _borderColor:TColor
	Field _miniMap:TMinimap			' the minimap associated with this viewport
	Field _msgWindow:TMessageWindow = TMessageWindow.Create()  ' create a message window for the viewport
	
	Field _zoomFactor:Float = 1
	Field _zoomAmount:Float 		' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5
	
	Method InitViewportVariables()

		Local xmlfile:TxmlDoc = parseXMLdoc(c_settingsFile)
			TViewPort.InitViewportGlobals(xmlfile)	' first load the global values from settings.xml file
			' Viewport marginals
			_marginalTop				= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/top").ToInt()
			_marginalBottom			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/bottom").ToInt()
			_marginalLeft			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/left").ToInt()
			_marginalRight			= XMLFindFirstMatch(xmlfile,"settings/graphics/viewportmarginals/right").ToInt()
			' Border surrounding the viewport
			_borderWidth				= XMLFindFirstMatch(xmlfile,"settings/graphics/border/width").ToInt()
			_borderColor 			= TColor.FindColor(XMLFindFirstMatch(xmlfile,"settings/graphics/border/color").ToString())
			' Call msgWindow's InitVariables -method
			_msgWindow.InitVariables(xmlfile)

		xmlfile.free()	' free up memory

		_startX = _marginalLeft
		_startY = _marginalTop

		_width		= (g_ResolutionX - _startX - _marginalRight)
		_height		= (g_ResolutionY - _startY - _marginalBottom)
		_midX		= _width / 2
		_midY = _height / 2
		
		_miniMap = TMinimap.Create(Self.g_ResolutionX - 195, 0, 195, 195) 
	EndMethod

	Method DrawLevel() 
		_CameraPosition_X = _centeredObject.GetX()
		_CameraPosition_Y = _centeredObject.GetY()

		SetViewport(_startX ,_startY, _width, _height)  ' limit the drawing area to viewport margins
	
		SetScale 1, 1
		SetBlend ALPHABLEND
		SetAlpha 0.8
		If _zoomFactor < 0.1 Then SetAlpha (0.8 / 0.1 * _zoomFactor) 
		SetColor 128, 128, 255
		SetMaskColor 255, 255, 255
		
		TileImage G_media_spaceBG, (_CameraPosition_X) / 50, (_CameraPosition_Y) / 50
	
		SetColor 255, 255, 255
		SetAlpha 0.95
		If _zoomFactor < 0.1 Then SetAlpha (0.95 / 0.1 * _zoomFactor) 
		
		' draw the spacedust background. The 5000000 constant is to 
		' "smudge" zooming transitions until a better way
		' to scale parallax background with zoom is figured out.
		TileImage G_media_spacedust, (_CameraPosition_X + 5000000) * _zoomFactor, (_CameraPosition_Y + 5000000) * _zoomFactor
		
		' draw a colored border around the viewport
		DrawBorder(_borderWidth, _borderColor) 
		
	EndMethod

	' CenterCamera sets an object for the camera to follow
	Method CenterCamera(o:TSpaceObject) 
		_centeredObject = o
	End Method
	
	Method DrawBorder(w:Int,color:TColor)
		AutoMidHandle False
		SetHandle(0, 0) 

		SetViewport(0,0, g_ResolutionX, g_ResolutionY)  ' drawing area (whole screen)
		SetBlend SolidBlend
		SetLineWidth(w)
		TColor.SetTColor(color)
		SetRotation(0)
		SetScale(1,1)
		' top border
		DrawLine(_startX - w, _startY - w, _width + _startX + w, _startY - w)
		' bottom border
		DrawLine(_startX - w, _startY + _height + w, _startX + _width + w, _startY + _height + w)
		' left border
		DrawLine(_startX - w, _startY - w, _startX - w, _startY + _height + w)
		' right border
		DrawLine(_startX + _width + w, _startY - w, _startX + _width + w, _startY + _height + w)
	EndMethod

	Method CreateMsg(str:String,colString:String="")
		_msgWindow.CreateMsg(str,colString)
		TMessageWindow.DrawAll()	' update message windows
	EndMethod
		
	Method DrawMisc()
		TMessageWindow.DrawAll() 	' draw message windows
		
		SetBlend(ALPHABLEND) 
		SetAlpha(1) 
		SetColor(255,255,255)

		DrawText "FPS: " + G_delta.GetFPS(), 500, 10
		
		_MiniMap.Draw() 
	EndMethod

	Method GetResX:Int() 
		Return g_ResolutionX
	End Method

	Method GetResY:Int() 
		Return g_ResolutionY
	End Method
	
	Method GetMiniMap:TMinimap() 
		If _minimap Then Return _minimap
		Return Null
	End Method

	Method GetStartX:Int() 
		Return _startX
	End Method

	Method GetStartY:Int()
		Return _startY
	End Method

	Method GetWidth:Int()
		Return _width
	End Method

	Method GetHeight:Int()
		Return _height
	End Method

	Method GetMidX:Int()
		Return _MidX
	End Method

	Method GetMidY:Int()
		Return _MidY
	End Method

	Method GetCameraPosition_X:Float()
		Return _CameraPosition_X
	End Method

	Method GetCameraPosition_Y:Float()
		Return _CameraPosition_Y
	End Method
		
	Method SetZoomFactor(z:Float) 
		_zoomFactor = z
	End Method
	
	Method ZoomIn() 
		_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		_zoomAmount = _zoomAmount + 0.2 * G_delta.GetDelta() 
	End Method
	
	Method ZoomOut() 
		_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		_zoomAmount = _zoomAmount + 0.2 * G_delta.GetDelta() 
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
	End Method
	
	Function InitGraphicsMode()
		Graphics g_ResolutionX, g_ResolutionY, g_BitDepth, g_RefreshRate, 0
	EndFunction

	Function InitViewportGlobals(xmlfile:TxmlDoc)
		g_ResolutionX		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/x").ToInt()
		g_ResolutionY		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/y").ToInt()
		g_BitDepth			= XMLFindFirstMatch(xmlfile,"settings/graphics/bitdepth").ToInt()
		g_RefreshRate		= XMLFindFirstMatch(xmlfile,"settings/graphics/refreshrate").ToInt()
		
		g_media_spacedust 	= LoadImage(c_mediaPath + "spacedust.png")
		g_media_spaceBG		= LoadImage(c_mediaPath + "space_bg.jpg")
	EndFunction

	Function Create:TViewport()
		Local vp:TViewport = New TViewport
		Return vp
	EndFunction

EndType
