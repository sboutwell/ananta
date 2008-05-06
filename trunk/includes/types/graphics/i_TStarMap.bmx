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

Rem
	Star map (extended from TMiniMap)
EndRem

Type TStarMap Extends TMiniMap
	Field _centeredSectorX:Int	' centered sector is the sector (0..8192) that the map "camera" is currently in
	Field _centeredSectorY:Int	
	Field _visibleLines:Int[]	' two arrays containing the sectors visible in the minimap
	Field _visibleColumns:Int[] ' at the current camera position and zoom level
	Field _starColor:TColor		' default color of the star blip

	Method SetCamera(x:Double,y:Double)
		_isScrolling = TRUE
		'ClearMiniMap()
		super.SetCamera(x,y)
		Update()
		_isScrolling = FALSE
	End Method
	
	' scroll map along x axis
	Method scrollX(dir:Int = 1)
		_isScrolling = True
		ClearMiniMap()
		super.scrollX(dir)
		UpdateCenteredSector()
	End Method

	' scroll map along y axis	
	Method scrollY(dir:Int = 1) 
		_isScrolling = TRUE
		ClearMiniMap()
		super.scrollY(dir)
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
		If NOT TSystem.GetActiveSystem() Then Return
		Local sys:TSystem = TSystem.GetActiveSystem()
		_isScrolling = TRUE
		_cameraX = sys.GetX()
		_cameraY = sys.GetY()
		ClearMiniMap()
		Update()
		UpdateCenteredSector()
		'_isScrolling = FALSE
	End Method
	
	Method AddStarMapBlip(s:TSystem)
		Local blip:TMapBlip = AddBlip(s.GetX() - _cameraX,s.GetY() - _cameraY,s.GetSize())
		blip.SetBColor(_starColor)
	End Method

	' update calculates which sectors should be visible in the map at the current
	' camera position and zoom level, and then populates the starmap
	Method Update()
		If not isVisible Then Return
		'If not _centeredSectorX Or Not _centeredSectorY Return
		If _isScrolling Then 	' don't update the visibility arrays if the map's not moving
			UpdateVisibility()
			_isScrolling = FALSE
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
	
	' updates arrays holding the galaxy sector X and Y-coordinates that should be visible in the starmap
	Method UpdateVisibility()
		If not isVisible Then Return
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
		super.DrawDetails()
		DrawSectorGrid()
		DrawSectorNumber()
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
	
	' unfinished
	Method DrawSectorGrid()
		Local verticalSectors:Int[] = GetVisibleLines()
		Local horizontalSectors:Int[] = GetVisibleColumns()
		
		'For Local line:Int = EachIn horizontalSectors
		'	For Local column:Int = EachIn verticalSectors
				'G_DebugWindow.AddText(column + ":" +line)
		'	Next
		'Next
	End Method
		
	Function Create:TStarMap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TStarMap = New TStarMap
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		map._lineStep = 0.1
		map._defaultZoom = 0.3
		map._zoomFactor = 0.5
		map._scale = 10
		map._minZoom = 0.01
		map._title = "Galaxy map"
		map._unit = "ly"
		map._starColor = TColor.FindColor("yellow")
		
		map.Init() ' calculate the rest of the minimap values
		Return map
	End Function
EndType

