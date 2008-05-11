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

' -----------------------------------------------------------------
' TViewport contains various draw-to-screen related stuff
' -----------------------------------------------------------------

Type TViewport
	Global g_Renderer:String = "opengl"		' the renderer to use (directx / opengl)
	Global g_ResolutionX:Int	
	Global g_ResolutionY:Int	
	Global g_BitDepth:Int
	Global g_RefreshRate:Int

	Global g_media_spacedust:TImage		' image global for the "space dust" particle mask
	Global g_media_spaceBG:TImage		' image global for the space background

	Field _startX:Int	' screen coordinates and dimensions of the viewport
	Field _startY:Int	'
	Field _width:Int	'
	Field _height:Int	'
	Field _midX:Int		' center position
	Field _midY:Int		' center position
	Field _cameraPosition_X:Double
	Field _cameraPosition_Y:Double
	Field _centeredObject:TSpaceObject	' the object the camera is centered on
	Field _marginalTop:Int
	Field _marginalBottom:Int
	Field _marginalLeft:Int
	Field _marginalRight:Int
	Field _borderWidth:Int
	Field _borderColor:TColor
	Field _systemMap:TSystemMap ' the system minimap associated with this viewport
	Field _starMap:TStarMap		' the star minimap
	Field _msgWindow:TMessageWindow = TMessageWindow.Create()  ' create a message window for the viewport
	
	Field _defaultZoom:Float = 1
	Field _zoomFactor:Float = 1
	Field _zoomAmount:Float 		' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5
	Field _zoomStep:Float = 0.5			' the amount added to the _zoomAmount per each second of zooming
	Field _isZooming:Int = False	' flag to indicate if we're zooming in or out

		
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

		' calculate the dimensions
		_startX = _marginalLeft
		_startY = _marginalTop

		_width		= (g_ResolutionX - _startX - _marginalRight)
		_height		= (g_ResolutionY - _startY - _marginalBottom)
		_midX		= _width / 2
		_midY = _height / 2
		
		_defaultZoom = 1.0
		_zoomFactor = _defaultZoom
		
		' create minimaps
		_systemMap = TSystemMap.Create(g_ResolutionX - 195, 0, 195, 195) 
		'_starMap = TStarMap.Create(g_ResolutionX - 195, 200,195,195)
		_starMap = TStarMap.Create(_startX, _startY,_height,_width)

	EndMethod

	' draws the viewport borders and background images
	Method DrawLevel() 
		 ' set the camera position if an object to follow is defined
		If _centeredObject Then
			_CameraPosition_X:Double = _centeredObject.GetX() 
			_CameraPosition_Y:Double = _centeredObject.GetY() 
		EndIf

		SetViewport(_startX ,_startY, _width, _height)  ' limit the drawing area to viewport margins
	
		SetScale 1, 1
		SetBlend ALPHABLEND
		SetRotation 0
		
		' ----- draw the space background with zoom-dependent alpha
		SetAlpha 0.8
		If _zoomFactor < 0.1 Then SetAlpha (0.8 / 0.1 * _zoomFactor) 
		SetColor 128, 128, 255
		SetMaskColor 255, 255, 255
		TileImage2(G_media_spaceBG, (_CameraPosition_X:Double) / 50, (_CameraPosition_Y:Double) / 50)
		' -----
		
		SetColor 255, 255, 255
		' ----- draw the space dust with zoom-dependent alpha
		If Not _isZooming And _zoomFactor < 0.1 Then ' if we're zoomed out far enough, gradually fade the space dust
			SetAlpha (0.95 / 0.1 * _zoomFactor) 
		ElseIf _isZooming Then  ' while we are zooming in or out, don't draw the space dust
			SetAlpha 0
		Else
			SetAlpha 0.95
		EndIf
		TileImage2 (G_media_spacedust, _CameraPosition_X:Double * _zoomFactor, _CameraPosition_Y:Double * _zoomFactor)
		' ---------

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
		DrawOblong( _startX-w, _startY-w, _startX + _width, _startY+_height)
	EndMethod

	' add a message to the message window
	Method CreateMsg(str:String,colString:String="")
		_msgWindow.CreateMsg(str,colString)
		TMessageWindow.DrawAll()	' update message windows
	EndMethod
	
	' draw miscellanous viewport stuff such as minimaps, hud and messages
	Method DrawMisc() 
		_systemMap.Draw() 
		If NOT _starMap._isPersistent OR _starMap._isScrolling Then _starMap.Update()
		_starMap.Draw()
		
		SetViewport(0, 0, viewport.GetResX(), viewport.GetResY()) 
		SetScale(1, 1) 
		SetBlend(ALPHABLEND) 
		SetRotation(0) 
		SetAlpha(1)
		SetColor(255, 255, 255) 
		TMessageWindow.DrawAll()  	' draw message windows
		G_debugWindow.DrawAllLines() 
		
		' draw some miscellaneous information
		DrawText "Hold F1 for controls", viewport.GetResX() - 190, GetResY()-25
	EndMethod

	Method GetCenteredObject:TSpaceObject() 
		Return _centeredObject
	End Method
	
	Method GetResX:Int() 
		Return g_ResolutionX
	End Method

	Method GetResY:Int() 
		Return g_ResolutionY
	End Method
	
	Method GetSystemMap:TSystemMap() 
		If _systemMap Then Return _systemMap
		Return Null
	End Method
	
	Method GetStarMap:TStarMap() 
		If _starMap Then Return _starMap
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

	Method GetCameraPosition_X:Double()
		Return _CameraPosition_X
	End Method

	Method GetCameraPosition_Y:Double()
		Return _CameraPosition_Y
	End Method
		
	Method GetZoomFactor:Float()
		Return _zoomFactor
	End Method
	
	Method SetZoomFactor(z:Float) 
		_zoomFactor = z
	End Method
	
	Method ResetZoomfactor() 
		_zoomFactor = _defaultZoom
	End Method
	
	Method ZoomIn() 
		_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta(false) 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(false) 
		_isZooming = True
	End Method
	
	Method ZoomOut() 
		_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta(false) 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(false) 
		_isZooming = True
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
		_isZooming = False
	End Method
	
	Method ShowInstructions() 
		' todo: externalize to a text file
		G_DebugWindow.AddText("")
		G_DebugWindow.AddText("============== Controls ==============")
		G_DebugWindow.AddText("left                 - rotate left")
		G_DebugWindow.AddText("right                - rotate right")
		G_DebugWindow.AddText("up                   - thrust")
		G_debugWindow.AddText("down                 - reverse thrust") 
		G_debugWindow.AddText("ctrl                 - fire") 
		G_debugWindow.AddText("j                    - jump drive") 
		G_debugWindow.AddText("z/x                  - zoom in/out") 
		G_debugWindow.AddText("alt+z                - reset zoom") 
		G_DebugWindow.AddText("shift+z / shift+x    - system map zoom in/out")
		G_debugWindow.AddText("alt+x                - reset system map zoom") 
		G_DebugWindow.AddText("c/v                  - starmap zoom in/out")
		G_DebugWindow.AddText("(shift+)wasd         - scroll starmap")		
		G_DebugWindow.AddText("alt+c                - center starmap")
		G_DebugWindow.AddText("g                    - toggle starmap on/off")
		G_debugWindow.AddText("alt+enter            - toggle fullscreen") 
		G_DebugWindow.AddText("ESC                  - exit")
	End Method
	
	' initializes the graphics mode to use the renderer we've specified (directx or openGL)
	Function InitGraphicsMode()
		Local isWin:Int = False ' are we running Windows?
		?win32
		isWin = True		' yeah we are
		?
		
		If g_Renderer = "directx" And isWin Then
			?win32
			SetGraphicsDriver D3D7Max2DDriver() 
			?
		Else
			SetGraphicsDriver GLMax2DDriver() 
		EndIf
		Graphics g_ResolutionX, g_ResolutionY, g_BitDepth, g_RefreshRate, 0
		'HideMouse()
	EndFunction
	
	Function ToggleFullScreen() 
		If g_BitDepth <> 0 Then
			g_BitDepth = 0
		Else
			g_BitDepth = 32
		EndIf
		InitGraphicsMode() 
	End Function
	
	' fetch some viewport properties from an xml file
	Function InitViewportGlobals(xmlfile:TxmlDoc) 
		g_Renderer = XMLFindFirstMatch(xmlfile, "settings/graphics/renderer").ToString() 
		g_ResolutionX		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/x").ToInt()
		g_ResolutionY		= XMLFindFirstMatch(xmlfile,"settings/graphics/resolution/y").ToInt()
		g_BitDepth			= XMLFindFirstMatch(xmlfile,"settings/graphics/bitdepth").ToInt()
		g_RefreshRate = XMLFindFirstMatch(xmlfile, "settings/graphics/refreshrate").ToInt() 
		
		g_media_spacedust = TImg.LoadImg("spacedust.png") 
		g_media_spaceBG = TImg.LoadImg("space_bg.jpg") 
	EndFunction

	Function Create:TViewport()
		Local vp:TViewport = New TViewport
		Return vp
	EndFunction

EndType
