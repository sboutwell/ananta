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
	Zoomable generic minimap and the related types and functions
EndRem

Type TMiniMap
	Field _L_blips:TList
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the minimap in pixels
	Field _width:Int	' width of the minimap in pixels
	Field _midX:Float	' middle X coordinate
	Field _midY:Float	' middle Y coordinate
	Field _alpha:Float = 0.8 ' alpha of the map. Affects everything: blips, lines and text.
	Field _cameraX:Double		' absolute camera coordinates
	Field _cameraY:Double
	Field _isScrolling:Int = False	' flag to show if the map is currently scrolling
	Field _scrollSpeed:Float = 500	' the base scroll speed in units per second
	
	Field _defaultZoom:Float = 1
	Field _zoomFactor:Float
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	Field _zoomStep:Float = 0.5			' the amount added to the _zoomAmount per each second of zooming
	Field _isZooming:Int = False		' flag to show if the map is currently zooming
	Field _minZoom:Float	' zoom limits
	Field _maxZoom:Float
	
	Field _minMapBlipSize:Int = 1	' smaller blips than this will be drawn at this size
	
	Field _scale:Float = 1	' how many map pixels does a real world distance unit represent
	
	Field _isPersistent:Int = False  ' no auto clearing the map blips after drawing them? Useful for maps with stationary blips.
	Field isVisible:Int = False		' toggling maps on/off toggles this boolean
	Field _labelsShown:Int = False	' are blip labels visible
	Field _labelTreshold:Float = 1.0	' zoom level at which labels are shown
	
	Field _hasScaleIndicator:Int = True	' scale indicator is a horizontal dynamic scale (with vertical scale lines) on the minimap
	Field _lineStep:Float = 100	' base value for scale indicator step. Step is the space between scale lines.
	Field _unit:String = "" 	' unit visible on the scale gauge (LY, AU, m, etc)

	Field _title:String = "Map"
	Field _titleYOffset:Float = 0 ' position of the title on the map
		
	' adds a blip to the minimap to the given coordinates
	Method AddBlip:TMapBlip(x:Double, y:Double, size:Int) 
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		x = x * _zoomFactor + midX + _startX
		y = y * _zoomFactor + midY + _startY
		
		size = size * _zoomFactor
		If size < _minMapBlipSize Then size = _minMapBlipSize	' ensure blip sizes are larger than the minimum
		Local blip:TMapBlip = TMapBlip.Create(x, y, size) 
		
		If Not _L_blips Then _L_blips = New TList
		If blip.GetSize() > 0 Then _L_blips.AddLast(blip) 
		Return blip
	End Method
	
	' scrolls the minimap along x-axis
	Method scrollX(speed:Int = 1) 
		Local speedMultiplier:Double = (_scrollspeed / _zoomFactor)
		If speedMultiplier < 10 Then speedMultiplier = 10:Double
		_cameraX = _cameraX + (speedMultiplier * speed) * G_delta.GetDelta(False) 	' delta not affected by time compression 
	End Method
	
	' scrolls the minimap along y-axis
	Method scrollY(speed:Int = 1) 
		Local speedMultiplier:Double = (_scrollspeed / _zoomFactor)
		If speedMultiplier < 10 Then speedMultiplier = 10:Double
		_cameraY = _cameraY + (speedMultiplier * speed) * G_delta.GetDelta(False)  	' delta not affected by time compression 
	End Method
	
	Method GetBlipCount:Int()
		If _L_Blips Then Return _L_Blips.Count()
		Return 0
	End Method

	Method SetCamera(x:Double,y:Double)
		_cameraX = x
		_cameraY = y
	End Method
		
	' draws the actual minimap
	Method draw() 
		If Not isVisible Then Return		' return without drawing if hidden
		SetViewport(_startX, _startY, _width, _height)  ' set drawing area

		SetBlend(ALPHABLEND) 
		SetAlpha(_alpha) 
		SetMaskColor(255, 255, 255) 
		SetScale(1, 1) 
		
		DrawBackGround() ' draw the background tint
		
		If _L_Blips Then
			For Local blip:TMapBlip = EachIn _L_Blips
				' If no part of the blip would be visible on the viewport, don't bother to draw it
				If blip.isOverBoundaries(_startX, _startY, _width, _height) Then
					Continue
				Else
					blip.Draw()
					If _labelsShown And _zoomFactor > _labelTreshold Then blip.DrawName()
				EndIf
			Next
			
			' After drawing all blips, clear the list if the map is not set as "persistent"
			' It is useful to set maps with rarely-moving blips as persistent for performance.
			If Not _isPersistent Then ClearMinimap()
		EndIf
		
		DrawDetails() 
	End Method

	Method ClearMinimap()
 		If _L_Blips Then _L_Blips.Clear() 		
	End Method
	
	' draw miscellaneous map details	
	Method DrawDetails() 
		SetHandle(0, 0) 
		If _hasScaleIndicator Then DrawScale() 
	 
		' draw the minimap title
		SetAlpha(1)
		SetColor(255,255,255)
		SetScale(1,1)
		SetRotation(0)
		DrawText(_title, Self._midX - (TextWidth(_title) / 2), Self._StartY + _titleYoffset)
	End Method

	' calculates and draws the scale indicator		
	Method DrawScale() 
		Local lineStepScaled:Double = _lineStep * _zoomFactor * _scale
		
		' this routine calculates how many vertical lines is needed on the current zoom level and linestep
		Local k:Int = 0
		Repeat
			k:+1
			lineStepScaled:Double = _lineStep * 10 ^ k * _zoomFactor * _scale
		Until lineStepScaled > 7 	' 8 is the maximum amount of vertical lines shown before the scale bumps "upward"

		Local lines:Int = _width / lineStepScaled	' number of lines on the scale indicator
		
		Local yPos:Int = _startY + _height - 5		' horizontal position of the scale indicator
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetAlpha(0.8) 
		SetLineWidth(1) 
		
		' center vertical line
		SetColor(255, 255, 0) 
		DrawLine(_midX, yPos + 6, _midX, yPos - 6, False) 
		
		' horizontal line
		SetColor(128, 128, 128) 
		DrawLine(_startX, yPos, _startX + _width, yPos, False) 
		
		' lines to the left of the center object
		For Local i:Int = 1 To lines / 2
			Local lineLength:Int = 2
			If i Mod 5 = 0 Then		' every fifth line is drawn on a different color
				SetColor(255, 255, 255)
				lineLength = 4 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX - i * lineStepScaled, yPos + lineLength,  ..
					_midX - i * lineStepScaled, yPos - lineLength) 
		Next
		
		' lines to the right of the center object
		For Local i:Int = 1 To lines / 2
			Local lineLength:Int = 2
			If i Mod 5 = 0 Then
				SetColor(255, 255, 255) 
				lineLength = 4 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX + i * lineStepScaled, yPos + lineLength,  ..
					_midX + i * lineStepScaled, yPos - lineLength) 
		Next
		
		DisplayLineStep(k)  ' draw the textual presentation of the current line step
	End Method
	
	' draws the scale text indicator on top of the scale line
	Method DisplayLineStep(k:Int) 
		Local prefix:String		' prefix is kilo, mega, giga, tera, etc
		Local val:Long = 10.0 ^ k * _lineStep	' value is the actual line step value without a prefix. Often a huge number with lots of zeroes.
		
		getPrefix(prefix, val) 	' GetPrefix adjusts prefix and value according to the amount of digits in the value
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetBlend(ALPHABLEND) 
		SetAlpha(0.6) 
		SetColor(128, 128, 128) 
		DrawText(Int(val) + prefix + " " + _unit, _startX + 5, _startY + _height - 20) 
	End Method
	
	' draws the background tint of the minimap
	Method DrawBackground()
		SetScale(1, 1) 
		SetAlpha(0.55)
		SetColor(0, 0, 0)
		SetRotation(0)
		DrawRect(_startX,_startY,_width,_height)
	End Method
	
	Method SetTitle(t:String)
		_title = t
	End Method
	
	Method SetZoomFactor(z:Float) 
		_zoomfactor = z
	End Method
	
	Method GetDefaultZoom:Float() 
		Return _defaultZoom
	End Method

	Method ResetZoomFactor() 
		SetZoomFactor(_defaultZoom)
		_isZooming = False
	End Method
	
	Method ZoomIn() 
		If Not isVisible Then Return	' don't bother to zoom non-visible maps
		' When we're zooming, we have to switch off persistency so that the map gets updated
		' Just remember to switch it back on when zooming is stopped if the map is meant to be persistent.
		' Todo: create another field for "default persistency" so TMinimap handles switching persistency on/off itself.
		_isPersistent = False
		_isZooming = True
		_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta(False)  	' false in delta means zoom speed will not be affected by time compression
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(False)  ' add to the zoom rate acceleration
		If _maxZoom And _zoomFactor > _maxZoom Then 	' zoom limit reached
			_zoomFactor = _maxZoom
			StopZoom()
		EndIf
	End Method
	
	Method ZoomOut() 
		If Not isVisible Then Return
		_isPersistent = False
		_isZooming = True
		_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta(False)  ' false in delta means zoom speed will not be affected by time compression
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(False)  ' add to the zoom rate acceleration
		If _minZoom And _zoomFactor < _minZoom Then 	' zoom limit reached
			_zoomFactor = _minZoom
			StopZoom()
		EndIf
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
		_isZooming = False
	End Method
	
	' initialize some minimap variables
	Method Init()
		_midX = _startX + _width / 2.0
		_midY = _startY + _height / 2.0
		_zoomFactor = _defaultZoom
	End Method
	
	Function Create:TMiniMap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TMiniMap = New TMiniMap
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		
		map.Init() 	' calculate the rest of the minimap values
		Return map
	End Function
EndType


Type TMapBlip
	Field _x:Int, _y:Int
	Field _size:Float
	Field _color:TColor
	Field _blipName:String = ""
	Field _System:TSystem
	
	Method GetSystem:TSystem()
		Return _System
	End Method
	
	Method SetSystem:TSystem(s:TSystem)
		_System=s
	End Method	
	
	Method GetSize:Float() 
		Return _size
	End Method
	
	Method GetX:Int() 
		Return _x
	End Method
	
	Method GetY:Int() 
		Return _y
	End Method
	
	Method GetName:String()
		Return _blipName
	End Method	
	
	Method SetName(n:String)
		_blipName = n
	End Method
	
	Method SetSize(sz:Float) 
		_size = sz
	End Method
	
	Method SetBColor(col:TColor) 
		_color = col
	End Method

	' isOverBoundaries checks if the blip would show on the minimap. Returns "true" if not.
	Method isOverBoundaries:Int(startX:Int, startY:Int, width:Int, height:Int) 
		Return _x + _size / 2 < startX Or ..
			_y + _size / 2 < startY Or ..
			_x - _size / 2 > startX + width Or ..
			_y - _size / 2 > startY + height
	End Method
	
	Method Draw() 
		If _size = 0 Then Return		' don't draw 0-sized blips (shouldn't happen as the size check is already done elsewhere)
		If _color Then 
			TColor.SetTColor(_color) 
		Else
			SetColor(255, 255, 255) 	' default color white if not set
		EndIf
		
		If _size < 2 Then	' if the size is smaller than 2 pixels, plot a pixel instead of drawing an oval
			Plot (_x,_y)
		Else
			SetHandle(_size / 2, _size / 2)       ' oval handle to the middle of the oval
			DrawOval (_x, _y, _size, _size) 
		End If
	End Method
	
	Method DrawName()
		SetColor(190, 190, 240)
		SetHandle(TextWidth(_blipName) / 2, TextHeight(_blipName))
		DrawText(Capitalize(_blipName), _x, _y)
	End Method
	
	Function Create:TMapBlip(x:Int, y:Int, size:Int) 
		Local blip:TMapBlip = New TMapBlip
		blip._x = x
		blip._y = y
		blip._size = size
		Return blip
	End Function
	
End Type