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

' -----------------------------------------------------------------
' TViewport contains various draw-to-screen related stuff
' -----------------------------------------------------------------

Type TViewport
	Global g_Renderer:String = "opengl"		' the renderer to use (directx / opengl)
	Global g_ResolutionX:Int	
	Global g_ResolutionY:Int	
	Global g_BitDepth:Int
	Global g_RefreshRate:Int

	Global g_media_spaceBG:TImage		' image global for the space background

	Field _startX:Int	' screen coordinates and dimensions of the viewport
	Field _startY:Int	'
	Field _width:Int	'
	Field _height:Int	'
	Field _midX:Int		' center position
	Field _midY:Int		' center position
	Field _cameraPosition_X:Double
	Field _cameraPosition_Y:Double
	Field _camXVel:Double
	Field _camYVel:Double
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
		'_starMap = TStarMap.Create(g_ResolutionX - 195, 200, 195, 195)
		_starMap = TStarMap.Create(_startX, _startY, _height, _width)
		
		 G_debugWindow = TDebugWindow.Create(250, 10 + _marginalTop)

		TScreenParticle.Init() ' populate screen particle array
	EndMethod

	' draws the viewport borders and background images
	Method DrawLevel() 
		 ' set the camera position if an object to follow is defined
		If _centeredObject Then
			_CameraPosition_X:Double = _centeredObject.GetX() 
			_CameraPosition_Y:Double = _centeredObject.GetY() 
			_camXVel:Double = _centeredObject.GetXVel() ' camera velocity for drawing speed lines 
			_camYVel:Double = _centeredObject.GetYVel()
			
			If TShip(_centeredObject) Then
				Local ship:Tship = TShip(_centeredObject)
				If ship.isWarpDriveOn Then 
					_camXVel = _camXVel	* ship.GetWarpRatio()
					_camYVel = _camYVel	* ship.GetWarpRatio()
				EndIf
			EndIf
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
		DrawSpaceDecals()
		' ---------
		
		' draw a colored border around the viewport
		DrawBorder(_borderWidth, _borderColor) 
		
	EndMethod

	' CenterCamera sets an object for the camera to follow
	Method CenterCamera(o:TSpaceObject) 
		If o = Null Then Return
		_centeredObject = o
		ZoomToFit()
		CreateMsg("Viewing: " + ProperCase(_centeredObject.getName()))
	End Method
	
	' draws random "space dust" and velocity lines
	Method DrawSpaceDecals()
		TScreenParticle.UpdateAndDrawAll()
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

	' draws a line into the world, useful for displaying targeting vectors etc
	Method DrawLineToWorld(sx:Double,sy:Double,ex:Double,ey:Double)
		Local x1:Double = (_cameraPosition_X  - sx) * _zoomFactor + _midX + _startX
		Local y1:Double = (_cameraPosition_Y  - sy) * _zoomFactor + _midY + _startY
		
		Local x2:Double = (_cameraPosition_X  - ex) * _zoomFactor + _midX + _startX
		Local y2:Double = (_cameraPosition_Y  - ey) * _zoomFactor + _midY + _startY
		DrawLine(x1,y1,x2,y2)
	End Method

	' draws a circle into the world, useful for hilighting objects etc.
	Method DrawCircleToWorld(x:Double,y:Double,r:Int)
		Local sx:Double = (_cameraPosition_X  - x) * _zoomFactor + _midX + _startX
		Local sy:Double = (_cameraPosition_Y  - y) * _zoomFactor + _midY + _startY
		
		DrawCircle(sx,sy,r)
	End Method
	
	' add a message to the message window
	Method CreateMsg(str:String,colString:String="")
		_msgWindow.CreateMsg(str,colString)
		TMessageWindow.DrawAll()	' update message windows
	EndMethod
	
	' draw miscellanous viewport stuff such as minimaps, hud and messages
	Method DrawMisc()
		_systemMap.Draw() 
		If Not _starMap.isPersistent Or _starMap.isScrolling Then _starMap.Update()
		_starMap.Draw()
		
		SetViewport(0, 0, G_viewport.GetResX(), G_viewport.GetResY()) 
		SetScale(1, 1) 
		SetBlend(ALPHABLEND) 
		SetRotation(0) 
		SetAlpha(1)
		SetColor(255, 255, 255) 
		TMessageWindow.DrawAll()  	' draw message windows
		G_debugWindow.DrawAllLines() 
		
		' draw some miscellaneous information
		DrawText "Hold F1 for controls", GetResX() - 190, GetResY()-25
		If G_timer.isPaused Then 
			SetColor(255,128,50)
			DrawText "*** Paused ***", GetMidX() - 120, _marginalTop + 5
		End If
	EndMethod

	' CycleCamera selects the next/previous SpaceObject in the active system as the object for the camera to follow
	Method CycleCamera(dir:Int = 1)
		Local actsyst:TSystem = TSystem.GetActiveSystem()
		Local currCenteredObject:TSpaceObject = _centeredObject
		Local foundcurrent:Int = False
		Local newCenter:TSpaceObject
		If Not actsyst Then Return
		
		For Local obj:TSpaceObject = EachIn actsyst.GetSpaceObjects()
			If obj = currCenteredObject And dir = 0 Then 
				CenterCamera(newCenter)
				Return
			EndIf
			If obj = currCenteredObject And dir = 1 Then 
				foundCurrent = True
				If obj <> actsyst.GetSpaceObjects().Last() Then Continue
			EndIf
			If TStellarObject(obj) or TShip(obj) Then newCenter = obj ' only cycle ships and stellar objects
			if foundCurrent Then
				CenterCamera(newCenter)
				Return
			EndIf
		Next
		
		' Ok, if we're here, we did not find the current camera object when iterating through the list
		' This may happen when the centered object is destroyed. So, let's reset the camera now:
		If g_player.GetControlledShip() Then 
			CenterCamera(G_player.GetControlledShip())
		Else ' if we don't have the player ship either, let's center the central star
			CenterCamera(TSpaceObject(actsyst.GetMainStar()))
		EndIf
		
	End Method
	
	
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
	
	Method GetCamXVel:Double()
		Return self._camXVel
	End Method

	Method GetCamYVel:Double()
		Return self._camYVel
	End Method

	Method GetCamSpeed:Double()
		Return (GetSpeed(_camXVel,_camYVel))
	End Method
	
	Method SetZoomFactor(z:Float) 
		_zoomFactor = z
	End Method
	
	Method ResetZoomfactor() 
		'_zoomFactor = _defaultZoom
		ZoomToFit()
	End Method
	
	' adjust zoom to fit the centered object on screen
	Method ZoomToFit()
		If NOT _centeredObject Then Return
		Local minSize:Float = 50
		Local hght:Float = _height	' viewport height
		Local sz:Float = _centeredObject.GetSize()	' centered object size
		
		Local objectsApparentSize:Float = GetZoomFactor() * (sz)
		Local doesFitOnScreen:Int = ((hght/sz) >= GetZoomFactor())
		
		
		' if object's apparent size on screen is between allowed limits, return without adjusting zoom
		If objectsApparentSize => (hght/minSize) And doesFitOnScreen Then 
			Return
		ElseIf doesFitOnScreen ' If object appears too small on screen, adjust zoom accordingly
		   SetZoomFactor(hght/minSize/sz)
		   return
		EndIf
		
		'If (hght/sz) >= GetZoomFactor() Then Return ' object fits on screen at the current zoom level, return
		
		SetZoomFactor(hght/sz) ' exact fit 
	End Method
	

	
	Method ZoomIn() 
		_zoomFactor:+_zoomFactor * _zoomAmount / G_timer.GetFPS() /10:Double 
		_zoomAmount = _zoomAmount + _zoomStep / G_timer.GetFPS()  /10:Double
		_isZooming = True
	End Method
	
	Method ZoomOut() 
		_zoomFactor:-_zoomFactor * _zoomAmount / G_timer.GetFPS() /10:Double 
		_zoomAmount = _zoomAmount + _zoomStep / G_timer.GetFPS() /10:Double 
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
		G_debugWindow.addText("down                 - reverse thrust") 
		G_debugWindow.addText("a/d                  - thrust left/right") 
		G_debugWindow.addText("ctrl                 - fire") 
		G_debugWindow.AddText("j                    - warp drive on/off") 
		G_debugWindow.AddText("z/x                  - zoom in/out") 
		G_debugWindow.AddText("alt+z                - reset zoom") 
		G_DebugWindow.AddText("shift+z / shift+x    - system map zoom in/out")
		G_debugWindow.AddText("alt+x                - reset system map zoom") 
		G_DebugWindow.AddText("g                    - starmap on/off")
		G_DebugWindow.AddText("(shift+)wasd         - scroll starmap")		
		G_DebugWindow.AddText("c/v                  - starmap zoom in/out")
		G_DebugWindow.AddText("alt+c                - center starmap")
		G_debugWindow.AddText("alt+enter            - toggle fullscreen") 
		G_debugWindow.AddText("h                    - hyperspace to system under mouse")
		G_debugWindow.AddText("l                    - toggle FBW limiter")
		G_debugWindow.AddText("PGUP/PGDN            - cycle camera objects")
		G_debugWindow.AddText("p                    - toggle pause")
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
		
		g_media_spaceBG = TImg.LoadImg("space_bg.jpg") 
	EndFunction

	Function Create:TViewport()
		Local vp:TViewport = New TViewport
		Return vp
	EndFunction

EndType

' space dust particles
Type TScreenParticle
	Global g_maxParticles:Int = 2200 ' number of particles spread around the specified area
	Global g_ScreenParticles:TScreenParticle [g_maxParticles] ' array holding all particles
	Global g_pAreaWidth:Int  = 2800		' particle area dimensions in screen pixels
	Global g_pAreaHeight:Int = 2000		'
	Global g_particleAreaStartX:Double	' top left (world) coordinate of the particle area
	Global g_particleAreaStartY:Double	' top left (world) coordinate of the particle area
	Global g_particleAreaEndX:Double	' bottom right (world) coordinate of the particle area
	Global g_particleAreaEndY:Double	' bottom right (world) coordinate of the particle area
	Global g_isRandomized:Int = False
	Global g_streakSpeedTreshold:Int = 400
	Global g_streakSpeedLimit:Int = 1200
	Global g_streakCoeff:Double = 1
	Global g_streakAlphaCoeff:Double = 1
	Field _x:Double ' screen coordinates
	Field _y:Double '
	Field _worldX:Double ' world coordinates
	Field _worldY:Double '
			
	
	Method _draw()
		SetColor(255,255,255)
		
		If G_viewport.GetCamSpeed() > g_streakSpeedTreshold Then ' draw a streak
			Local streakStartX:Double = _x
			Local streakStartY:Double = _y 
			Local streakEndX:Double = _x - G_viewport.GetCamXVel() * g_streakCoeff * G_viewport.GetZoomFactor()
			Local streakEndY:Double = _y - G_viewport.GetCamYVel() * g_streakCoeff * G_viewport.GetZoomFactor()
			' return without drawing if no part of the streak is visible on viewport
			If  streakStartx < G_viewport.GetStartX() And streakStartY < G_viewport.GetStartY() And ..
				streakStartx > G_viewport.GetStartX() + G_viewport.GetWidth() And ..
				streakStartY > G_viewport.GetStartY() + G_viewport.GetHeight() And ..
				streakEndx < G_viewport.GetStartX() And streakEndY < G_viewport.GetStartY() And ..
				streakEndx > G_viewport.GetStartX() + G_viewport.GetWidth() And ..
				streakEndY > G_viewport.GetStartY() + G_viewport.GetHeight() Then Return
				
			DrawLine(streakStartX, streakStartY, streakEndX, streakEndY)
		Else ' if we're not moving very fast, plot a pixel instead of a streak
			' don't draw if pixel is not visible on the viewport
			If  _x < G_viewport.GetStartX() Or _y < G_viewport.GetStartY() Or ..
				_x > G_viewport.GetStartX() + G_viewport.GetWidth() Or ..
				_y > G_viewport.GetStartY() + G_viewport.GetHeight() Then Return
			Plot(_x,_y)
		End If
	End Method
	
	Method _isOutOfBoundaries:Int()	' returns true if particle is out of area boundaries
		Return _worldX > g_ParticleAreaEndX Or _worldX < g_ParticleAreaStartX Or _worldY > g_PArticleAreaEndY Or _worldY < g_ParticleAreaStartY
	End Method
	
	Method _randomizePosition()
		_worldX = Rand(g_ParticleAreaStartX,g_ParticleAreaEndX)
		_worldY = Rand(g_ParticleAreaStartY,g_ParticleAreaEndY)
	End Method
	
	' repositions (wrap around) a particle found to be outside the allowed area
	Method _reposition()
		Local maxDeviation:Double = 0 ' how far the particle is from the allowed area border
		If _worldX > g_ParticleAreaEndX Then 
			_worldX = g_ParticleAreaStartX + _worldX - g_ParticleAreaEndX
			local xdev:Double = Abs(_worldX - g_ParticleAreaEndX)
			if xdev > maxDeviation Then maxDeviation = xdev
		EndIf
		If _worldX < g_ParticleAreaStartX Then 
			_worldX = g_ParticleAreaEndX + _worldX - g_ParticleAreaStartX
			Local xDev:Double = Abs(_worldX - g_ParticleAreaStartX)
			if xdev > maxDeviation Then maxDeviation = xdev
		EndIf
		If _worldY > g_ParticleAreaEndY Then 
			_worldY = g_ParticleAreaStartY + _worldY - g_ParticleAreaEndY
			Local xDev:Double = Abs(_worldY - g_ParticleAreaEndY)
			if xdev > maxDeviation Then maxDeviation = xdev
		EndIf
		If _worldY < g_ParticleAreaStartY Then 
			_worldY = g_ParticleAreaEndY + _worldY - g_ParticleAreaStartY
			Local xDev:Double = Abs(_worldY - g_ParticleAreaStartY)
			if xdev > maxDeviation Then maxDeviation = xdev
		EndIf
		
		' *** Re-randomize the whole bunch if we're warping way out of the area
		' This trick is due to a faulty logic in the code which makes the stardust effect
		' 	lag out of screen during extreme speeds with jumpdrive on. Comment the line to see what I mean.
		' I hate it when I have to resort to "duct tape fixes"!  
		' /JP
		If maxDeviation > 4.0 * g_pAreaWidth Then RandomizeAll()  
		' ***
	End Method
	
	Function CalculateScreenLimits()
		g_particleAreaStartX = G_viewport.GetCameraPosition_X() - g_pAreaWidth
		g_particleAreaEndX = G_viewport.GetCameraPosition_X() + g_pAreaWidth
		g_particleAreaStartY = G_viewport.GetCameraPosition_Y() - g_pAreaHeight
		g_particleAreaEndY = G_viewport.GetCameraPosition_Y() + g_pAreaHeight
	End Function
	
	Function RandomizeAll()
		CalculateScreenLimits()
		For Local part:TScreenParticle = EachIn g_ScreenParticles
			part._randomizePosition()
		Next
		g_isRandomized = True
	End Function
	
	' precalculates the length of the speed streaks and streak alpha
	Function CalculateStreakCoeff()
		g_streakAlphaCoeff = 1.0
		Local streakSpeed:Double = G_viewport.GetCamSpeed()
		If streakSpeed > g_streakSpeedLimit Then streakSpeed = g_streakSpeedLimit
		
		
		Local reduction:Double = (streakSpeed / g_streakSpeedTreshold)^(1.0/16.0)
		g_streakCoeff = 1.0 - reduction
		
		' reduce streak alpha gradually IF above the streak treshold
		If streakSpeed > g_streakSpeedTreshold Then g_streakAlphaCoeff = (1.0 - (reduction - 1.0))^15.0
	End Function
	
	Function UpdateAndDrawAll()
		If Not g_isRandomized Then RandomizeAll()
		CalculateScreenLimits()
		CalculateStreakCoeff()
		
		For Local part:TScreenParticle = EachIn g_ScreenParticles
			If G_viewport.GetZoomFactor() < 0.8 Then ' if we're zoomed out far enough, gradually fade the space dust
				SetAlpha (0.65 / 0.8 * G_viewport.GetZoomFactor()) * g_streakAlphaCoeff
			Else
				SetAlpha 0.65 * g_streakAlphaCoeff
			EndIf
			If GetAlpha() < 0.01 Then Return

			If part._isOutOfBoundaries() Then part._reposition()
			' calculate screen position based on world position and zoom
			part._x = G_viewport.GetCameraPosition_X() - part._worldX
			part._y = G_viewport.GetCameraPosition_Y() - part._worldY
			part._x = part._x * G_viewport.GetZoomFactor() + G_viewport.GetMidX() + G_viewport.GetStartX()
			part._y = part._y * G_viewport.GetZoomFactor() + G_viewport.GetMidY() + G_viewport.GetStartY()
			part._draw()
		Next
	End Function
	
	' prepopulate screen particle array
	Function Init()
		For Local i:Int = 0 To g_maxParticles - 1
			g_ScreenParticles[i] = TScreenParticle.Create()
		Next
	End Function
	
	Function Create:TScreenParticle()
		Local part:TScreenParticle = New TScreenParticle
		Return part
	End Function
End Type