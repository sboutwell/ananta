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

Rem
	Star map (extended from TMiniMap)
EndRem

Type TStarMap Extends TMiniMap

	Global G_starColor:TColor[]
	
	Field _centeredSectorX:Int	' centered sector is the sector (0..8192) that the map "camera" is currently in
	Field _centeredSectorY:Int	
	Field _visibleLines:Int[]	' two arrays containing the sectors visible in the minimap
	Field _visibleColumns:Int[] ' at the current camera position and zoom level
	Field _mapOverlayTreshold:Float	' zoom level at which star generation is replaced with overlay galaxy map
	Field _galaxyImage:TImage

	Method SetCamera(x:Double, y:Double)
		_isScrolling = True
		'ClearMiniMap()
		Super.SetCamera(x,y)
		Update()
		_isScrolling = False
	End Method
	
	' scroll map along x axis
	Method scrollX(dir:Int = 1)
		_isScrolling = True
		ClearMiniMap()
		Super.scrollX(dir)
		UpdateCenteredSector()
	End Method

	' scroll map along y axis	
	Method scrollY(dir:Int = 1) 
		_isScrolling = True
		ClearMiniMap()
		Super.scrollY(dir)
		UpdateCenteredSector()
	End Method

	' calculate which sector the map is centered on
	Method UpdateCenteredSector()
		_centeredSectorX = _cameraX / TSector.GetSectorSize()
		_centeredSectorY = _cameraY / TSector.GetSectorSize()
	End Method
		
	Method ToggleVisibility()
		ToggleBoolean(isVisible)	' toggle starmap visibility status
		If isVisible Then 
			UpdateVisibility()	 ' update the visible sectors for the starmap
			If GetBlipCount() = 0 Then Update() ' do an update if map not already populated
		EndIf
	End Method
	
	Method ResetZoomFactor() 
		_isZooming = True
		SetZoomFactor(_defaultZoom)
		Update()
		_isZooming = False
	End Method
	
	Method SetZoomFactor(z:Float) 
		_isZooming = True
		_zoomfactor = z
		Update()
		_isZooming = False
	End Method

	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
		UpdateVisibility()
		_isZooming = False
	End Method
	
	' centers camera to the middle of the active system
	Method Center()
		If Not TSystem.GetActiveSystem() Then Return
		Local sys:TSystem = TSystem.GetActiveSystem()
		_isScrolling = True
		_cameraX = sys.GetX()
		_cameraY = sys.GetY()
		ClearMiniMap()
		Update()
		UpdateCenteredSector()
		'_isScrolling = FALSE
	End Method
	
	Method AddStarMapBlip(s:TSystem)
		Local blip:TMapBlip = AddBlip(s.GetX() - _cameraX,s.GetY() - _cameraY,s.GetSize())
		blip.SetBColor(G_starColor[s._type])
		blip.SetName(s._name)
		blip.SetSystem(s)
	End Method

	' update calculates which sectors should be visible in the map at the current
	' camera position and zoom level, and then populates the starmap
	Method Update()
		If Not isVisible Then Return
		If _zoomFactor < _mapOverlayTreshold Then Return

		If _isScrolling Then 	' don't update the visibility arrays if the map's not moving
			UpdateVisibility()
			_isScrolling = False
		EndIf
		
		For Local line:Int = EachIn _visibleLines
			For Local column:Int = EachIn _visibleColumns
				Local sect:TSector = TSector.Create(column,line)
				sect.Populate()
				For Local sys:TSystem = EachIn sect.GetSystemList()
					AddStarMapBlip(sys)
				Next				
				sect.Forget()
			Next
		Next		
	End Method
	
	Method getBlipUnderMouse:TMapBlip(within:Int=4)
		Local mx:Int=MouseX()
		Local my:Int=MouseY()
		Local s:Int = 0
		
		For Local i:TMapBlip = EachIn _L_blips
			s:Int = (i.getSize()/_zoomFactor) + within
			If mx > (i.getX()-s) And mx < (i.getX()+s)
				If my > (i.getY()-s) And my < (i.getY()+s)
					Return i
				EndIf
			EndIf
		Next
	End Method
	
	' updates arrays holding the galaxy sector X and Y-coordinates that should be visible in the starmap
	Method UpdateVisibility()
		If Not isVisible Then Return
		If _zoomFactor < _mapOverlayTreshold Then Return

		' scaled map dimensions are in galaxy coordinate units, 
		' not light years. To get in light years, divide by _scale
		Local scaledMapHeight:Float = _height / _zoomFactor
		Local scaledMapWidth:Float = _width / _zoomFactor
		
		' the Y-coordinates of the sectors on the top and the bottom edge of the starmap
		Local topSectorY:Int = (_cameraY + scaledMapHeight/2) / TSector.GetSectorSize()
		Local bottomSectorY:Int = (_cameraY - scaledMapHeight/2) / TSector.GetSectorSize()
		' the X-coordinates of the sectors on the left and the right edge of the starmap
		Local leftSectorX:Int = (_cameraX + scaledMapWidth/2) / TSector.GetSectorSize()
		Local rightSectorX:Int = (_cameraX - scaledMapWidth/2) / TSector.GetSectorSize()
		
		' calculate how many star sectors fit on the map horizontally
		_visibleLines = New Int[topSectorY - bottomsectorY + 1]	' dim the Y array
		For Local i:Int = 0 To _visibleLines.Length - 1
			_visibleLines[i] = bottomSectorY + i
		Next
		
		' calculate how many star sectors fit on the map vertically
		_visibleColumns = New Int[leftSectorX - rightSectorX + 1]	' dim the X array
		For Local i:Int = 0 To _visibleColumns.Length - 1
			_visibleColumns[i] = rightSectorX + i
		Next
	End Method
	
	Method GetVisibleLines:Int[]()
		Return _visibleLines
	End Method
	
	Method GetVisibleColumns:Int[]()
		Return _visibleColumns
	End Method
		
	Method DrawDetails()
		Super.DrawDetails()
		If _zoomFactor < _mapOverlayTreshold Then DrawMapOverlay()
		DrawSectorGrid()
		DrawSectorNumber()
		G_debugWindow.AddText("Starmap blips: " + _L_Blips.Count())
		
		' draw the system our mouse is over and show the system underneath
		' we'll have to load the system and place the loaded system in the
		' TSystem._g_ViewingSystem variable
		'
		Local blipOver:TMapBlip = Self.getBlipUnderMouse(4) ' 4 = within radius of 4
		If blipOver
			Local SystemOver:TSystem = blipOver.getSystem()
			
			SetColor 255,0,0
			Local blipName:String = blipOver.getName()
			SetHandle(TextWidth(blipName) / 2, TextHeight(blipName))
			DrawText(ProperCase(blipName), blipOver.getX(), blipOver.getY())
			SetColor 255,255,255
			SetHandle 0,0

			If KeyHit(KEY_H) And SystemOver
				' hyperspace to this system...
				G_Player.GetControlledShip().HyperspaceToSystem(systemOver)
			EndIf
			
			If MouseDown(1)
				' load this system...				
				' now load the new system we're under				
				If systemOver<>Null					
					If systemOver.isPopulated()=0 Then systemOver.populate()
					
					' now draw it
					systemOver.drawSystemQuickly(blipOver.getX(),blipOver.getY(), 200)									
				EndIf				
			Else			
				' when we let go of mousedown(1), forget the viewed system
				If TSystem._g_ViewingSystem<>Null
					TSystem._g_ViewingSystem.forget()
					TSystem._g_ViewingSystem=Null
				EndIf				
			EndIf
			
			If KeyDown(KEY_H) And SystemOver
				' hyperspace to this system...
				G_Player.GetControlledShip().HyperspaceToSystem(systemOver)
			EndIf
		EndIf
	End Method
	
	' draws the galaxy image overlay
	Method DrawMapOverlay()
		SetHandle(0, 0)
		SetRotation(0)
		SetBlend(ALPHABLEND)
		SetAlpha(0.6)
		SetColor(255, 255, 255)
		
		' calculate the dimensions of the galaxy image if the scale was 1.0
		Local mapWidth:Double = 8.0 * TSector.GetSectorSize()
		Local mapHeight:Double = 8.0 * TSector.GetSectorSize()
		' scale the dimensions to the current zoom factor...
		Local scX:Double = mapWidth * _zoomFactor
		Local scY:Double = mapHeight * _zoomFactor
		SetScale(scX, scY)
		
		' adjust the image position according to the camera and scale
		Local x:Double, y:Double
		x = (_cameraX + 12 * TSector.GetSectorSize()) * _zoomFactor
		y = (_cameraY + 12 * TSector.GetSectorSize()) * _zoomFactor
		' NOTE: there seems to be an offset of 1.5 pixels in the image position,
		'		hence the additional (12 * Sectorsize) offset
		
		' draw the galaxy image on top of the minimap
		DrawImage(_galaxyImage, - x + (_midX), - y + (_midY))
	End Method
		
	Method DrawSectorNumber()
		SetAlpha(1)
		SetColor(255,255,255)
		SetScale(1,1)
		SetRotation(0)
		DrawText(_centeredSectorX + ":" + _centeredSectorY, _startX + _width - 80, _StartY + _height - 30)
		' the text should be neatly positioned to the lower right corner of the map 
		' regardless of the resolution and map size
	End Method
	
	Method DrawSectorGrid()
		Local verticalSectors:Int[] = GetVisibleColumns()
		Local horizontalSectors:Int[] = GetVisibleLines()
		
		'If verticalSectors.Length > 100 Or horizontalSectors.Length > 100 Then Return	' don't draw grid if zoomed out enough
		
		SetColor(30,240,30)
		SetBlend(AlphaBlend)
		SetAlpha(0.2)
		SetScale(1, 1)
		If _zoomFactor < 0.25 Then SetAlpha (GetAlpha() / 0.25 * _zoomFactor) 

		For Local lin:Int = EachIn horizontalSectors
			Local xs:Double = _startX
			Local xe:Double = _startX + _width
			Local ys:Double = _midY + (lin*TSector.GetSectorSize()-_cameraY) * _zoomFactor
			Local ye:Double = ys
			DrawLine(xs,ys,xe,ye)
		Next
		
		For Local col:Int = EachIn verticalSectors
			Local ys:Double = _startY
			Local ye:Double = _startY + _height
			Local xs:Double = _midX + (col*TSector.GetSectorSize()-_cameraX) * _zoomFactor
			Local xe:Double = xs
			DrawLine(xs,ys,xe,ye)				
		Next
		
		' Finally draw a different-color square around the centered sector
		HighlightActiveSector()
		
		G_DebugWindow.AddText("Starmap coords: " + _cameraX + ":" + _cameraY)
		G_DebugWindow.AddText("Starmap zoom: " + _zoomFactor)
	End Method

	Method HighlightActiveSector()
		SetAlpha(0.5)
		SetColor(80,255,80)
		Local sectSize:Int = TSector.GetSectorSize()
		
		' top
		Local xs:Double = _midX + (_centeredSectorX * sectSize - _cameraX) * _zoomFactor
		Local xe:Double = xs + sectSize * _zoomFactor
		Local ys:Double = _midY + (_centeredSectorY * sectSize -_cameraY) * _zoomFactor
		Local ye:Double = ys
		DrawLine(xs,ys,xe,ye)
		' bottom
		xs:Double = _midX + (_centeredSectorX * sectSize - _cameraX) * _zoomFactor
		xe:Double = xs + sectSize * _zoomFactor
		ys:Double = _midY + ((_centeredSectorY + 1) * sectSize -_cameraY) * _zoomFactor
		ye:Double = ys
		DrawLine(xs,ys,xe,ye)
		' left
		xs:Double = _midX + (_centeredSectorX * sectSize - _cameraX) * _zoomFactor
		xe:Double = xs
		ys:Double = _midY + (_centeredSectorY * sectSize -_cameraY) * _zoomFactor
		ye:Double = ys + sectSize * _zoomFactor
		DrawLine(xs,ys,xe,ye)
		' right
		xs:Double = _midX + ((_centeredSectorX + 1)* sectSize - _cameraX) * _zoomFactor
		xe:Double = xs
		ys:Double = _midY + (_centeredSectorY * sectSize -_cameraY) * _zoomFactor
		ye:Double = ys + sectSize * _zoomFactor
		DrawLine(xs,ys,xe,ye)

	End Method
			
	Function Create:TStarMap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TStarMap = New TStarMap
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		map._lineStep = 0.1
		map._defaultZoom = 1.5
		map._zoomFactor = 1.5
		map._scale = 10
		'map._minZoom = 0.08
		map._minZoom = 0.0003
		map._scrollSpeed = XMLGetSingleValue("conf/settings.xml","settings/graphics/starmap/scrollspeed").ToFloat()
		map._labelsShown = True
		map._labelTreshold = XMLGetSingleValue("conf/settings.xml","settings/graphics/starmap/labelTreshold").ToFloat()
		map._title = "Starmap"
		map._unit = "ly"
		map._galaxyImage = TImg.LoadImg("galaxy.png", False)
		map._mapOverlayTreshold = XMLGetSingleValue("conf/settings.xml","settings/graphics/starmap/mapOverlayTreshold").ToFloat() 
		
		' hardcoded for now, externalize later
		Local starColor:TColor[] =[ ..
								TColor.FindColor("tomato"),  .. 		' Type 'M' flare star
								TColor.FindColor("coral"),  ..		' Faint Type'M'red star
								TColor.FindColor("red"),  ..		' Type'M'red star
								TColor.FindColor("orange"),  ..		' Type'K'orange star
								TColor.FindColor("yellow"),  ..		' Type'G'yellow star
								TColor.FindColor("white"),  ..	' Type'F'white star
								TColor.FindColor("silver"),  ..	' Type'A'hot white star
								TColor.FindColor("slategray"),  ..	' White dwarf star
								TColor.FindColor("crimson") ..			' Red giant star
							]
		G_starColor = starColor	' assign the array to the global g_starColor

		
		map.Init() ' calculate the rest of the minimap values
		Return map
	End Function
EndType

