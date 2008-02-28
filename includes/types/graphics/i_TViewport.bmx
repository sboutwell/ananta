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

		_startX = _marginalLeft
		_startY = _marginalTop

		_width		= (g_ResolutionX - _startX - _marginalRight)
		_height		= (g_ResolutionY - _startY - _marginalBottom)
		_midX		= _width / 2
		_midY = _height / 2
		
		_defaultZoom = 1.0
		_zoomFactor = _defaultZoom
		
		_miniMap = TMinimap.Create(Self.g_ResolutionX - 195, 0, 195, 195) 
	EndMethod

	Method DrawLevel() 
		_CameraPosition_X = _centeredObject.GetX() 
		_CameraPosition_Y = _centeredObject.GetY()

		SetViewport(_startX ,_startY, _width, _height)  ' limit the drawing area to viewport margins
	
		SetScale 1, 1
		SetBlend ALPHABLEND
		SetRotation 0
		
		' ----- draw the space background with zoom-dependent alpha
		SetAlpha 0.8
		If _zoomFactor < 0.1 Then SetAlpha (0.8 / 0.1 * _zoomFactor) 
		SetColor 128, 128, 255
		SetMaskColor 255, 255, 255
		TileImage G_media_spaceBG, (_CameraPosition_X) / 50, (_CameraPosition_Y) / 50
		' -----
		
		SetColor 255, 255, 255
		' ----- draw the space dust with zoom-dependent alpha
		If Not _isZooming And _zoomFactor < 0.1 Then ' if we're zoomed out far enough, gradually fade the space dust
			SetAlpha (0.95 / 0.1 * _zoomFactor) 
		ElseIf _isZooming Then  ' if we are zooming in or out, don't draw the space dust
			SetAlpha 0
		Else
			SetAlpha 0.95
		EndIf
		TileImage G_media_spacedust, _CameraPosition_X * _zoomFactor, _CameraPosition_Y * _zoomFactor
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
		TMessageWindow.DrawAll()  	' draw message windows
		G_debugWindow.DrawAllLines() 
		_MiniMap.Draw() 

		SetViewport(0, 0, viewport.GetResX(), viewport.GetResY()) 
		SetScale(1, 1) 
		SetRotation(0) 
		SetBlend(ALPHABLEND) 
		SetAlpha(1)
		SetColor(255, 255, 255) 
		
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
	
	Method ResetZoomfactor() 
		_zoomFactor = _defaultZoom
	End Method
	
	Method ZoomIn() 
		_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta() 
		_isZooming = True
	End Method
	
	Method ZoomOut() 
		_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta() 
		_isZooming = True
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
		_isZooming = False
	End Method
	
	Method ShowInstructions()
		G_DebugWindow.AddText("")
		G_DebugWindow.AddText("============== Controls ==============")
		G_DebugWindow.AddText("left                 - rotate left")
		G_DebugWindow.AddText("right                - rotate right")
		G_DebugWindow.AddText("up                   - thrust")
		G_debugWindow.AddText("down                 - reverse thrust") 
		G_debugWindow.AddText("a                    - fire") 
		G_debugWindow.AddText("z/x                  - zoom in/out") 
		G_debugWindow.AddText("ctrl+z               - reset zoom") 
		G_DebugWindow.AddText("shift+z / shift+x    - map zoom in/out")
		G_debugWindow.AddText("ctrl+x               - reset map zoom") 
		G_debugWindow.AddText("alt+enter            - toggle fullscreen") 
		G_DebugWindow.AddText("ESC                  - exit")
	End Method
	
	Function InitGraphicsMode() 
		If g_Renderer = "directx" Then
			SetGraphicsDriver D3D7Max2DDriver() 
		Else
			SetGraphicsDriver GLMax2DDriver() 
		EndIf
		Graphics g_ResolutionX, g_ResolutionY, g_BitDepth, g_RefreshRate, 0
		HideMouse()
	EndFunction
	
	Function ToggleFullScreen() 
		If g_BitDepth <> 0 Then
			g_BitDepth = 0
		Else
			g_BitDepth = 32
		EndIf
		InitGraphicsMode() 
	End Function
	
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
