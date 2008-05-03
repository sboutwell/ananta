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
	
	Field _defaultZoom:Float = 1
	Field _zoomFactor:Float
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	Field _zoomStep:Float = 0.5			' the amount added to the _zoomAmount per each second of zooming
	
	Field _scale:Float = 1	' how many map pixels does a real world distance unit represent
	
	Field _isPersistent:Int = False  ' no auto clearing the map blips after drawing them? Useful for maps with stationary blips.
	
	Field _hasScaleIndicator:Int = TRUE
	' base value for scale gauge step
	Field _lineStep:Float = 100
	Field _unit:String = "" 	' unit visible on the scale gauge (LY, AU, km, etc)

	Field _title:String = "Map"
	Field _titleXOffset:Float = 0
	Field _titleYOffset:Float = 0
		
	Method AddBlip:TMapBlip(x:Double, y:Double, size:Int) 
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		'x = x * _zoomFactor * _scale + midX + _startX
		'y = y * _zoomFactor * _scale + midY + _startY
		x = x * _zoomFactor + midX + _startX
		y = y * _zoomFactor + midY + _startY
		
		'size = size * _zoomFactor * _scale
		size = size * _zoomFactor
		If size < 1 Then size = 1	' ensure blip sizes are larger than 1
		Local blip:TMapBlip = TMapBlip.Create(x, y, size) 
		
		If Not _L_blips Then _L_blips = New TList
		If blip.GetSize() > 0 Then _L_blips.AddLast(blip) 
		return blip
	End Method
	
	Method draw() 
		SetViewport(_startX, _startY, _width, _height) 
		SetBlend(ALPHABLEND) 
		SetAlpha(_alpha) 
		SetMaskColor(255, 255, 255) 
		SetScale(1, 1) 
		If _L_Blips Then
			For Local blip:TMapBlip = EachIn _L_Blips
				' If no part of the blip would be visible on the viewport, don't bother to draw it
				If blip.isOverBoundaries(_startX, _startY, _width, _height) Then
					Continue
				Else
					blip.Draw() 				
				EndIf
			Next
			
			' after drawing all blips, clear the list
			If Not _isPersistent Then ClearMinimap()
		EndIf
		
		SetHandle(0, 0) 
		' draw miscellaneous map details
		DrawDetails() 
	End Method

	Method ClearMinimap()
 		_L_Blips.Clear() 		
	End Method
	
	Method DrawDetails() 
		If _hasScaleIndicator Then DrawScale() 
	 
		' draw the background tint
		DrawBackGround()
		
		' draw the minimap title
		SetAlpha(1)
		SetColor(255,255,255)
		SetScale(1,1)
		SetRotation(0)
		DrawText(_title, Self._midX + _titleXoffset, Self._StartY + _titleYoffset) 
	End Method	
		
	Method DrawScale() 
		Local lineStepScaled:Double = _lineStep * _zoomFactor * _scale
		
		Local k:Int = 0
		Repeat
			k:+1
			lineStepScaled:Double = _lineStep * 10 ^ k * _zoomFactor * _scale
		Until lineStepScaled > 7

		Local lines:Int = _width / lineStepScaled
		
		Local yPos:Int = _startY + _height - 5
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetAlpha(0.5) 
		SetLineWidth(1) 
		
		' center vertical line
		SetColor(255, 255, 255) 
		DrawLine(_midX, yPos + 6, _midX, yPos - 6, False) 
		
		' horizontal line
		SetColor(128, 128, 128) 
		DrawLine(_startX, yPos, _startX + _width, yPos, False) 
		
		' lines to the left of the center object
		For Local i:Int = 1 To lines / 2
			If i Mod 5 = 0 Then
				SetColor(255, 255, 255) 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX - i * lineStepScaled, yPos + 2,  ..
					_midX - i * lineStepScaled, yPos - 2) 
		Next
		
		' lines to the right of the center object
		For Local i:Int = 1 To lines / 2
			If i Mod 5 = 0 Then
				SetColor(255, 255, 255) 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX + i * lineStepScaled, yPos + 2,  ..
					_midX + i * lineStepScaled, yPos - 2) 
		Next
		
		DisplayLineStep(k) 
	End Method
	
	' draws the scale text indicator on top of the scale line
	Method DisplayLineStep(k:Int) 
		Local prefix:String
		Local val:Long = 10.0 ^ k * _lineStep
		
		GetPrefix(prefix,val)
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetBlend(ALPHABLEND) 
		SetAlpha(0.6) 
		SetColor(128, 128, 128) 
		DrawText(Int(val) + prefix + " " + _unit, _startX + 5, _startY + _height - 20) 
	End Method
	
	Method DrawBackground()
		SetScale(1, 1) 
		SetAlpha(0.15)
		SetColor(64,64,255)
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
		_zoomfactor = _defaultZoom
	End Method
	
	Method ZoomIn() 
		_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta(false) 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(false) 
	End Method
	
	Method ZoomOut() 
		_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta(false) 
		_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta(false) 
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
	End Method
	
	Method Init()
		_midX = _startX + _width / 2.0
		_midY = _startY + _height / 2.0
		_zoomFactor = _defaultZoom
		_titleXOffset = -4 * _title.Length	' center the title text
	End method
	
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
	
	Method GetSize:Float() 
		Return _size
	End Method
	
	Method GetX:Int() 
		Return _x
	End Method
	
	Method GetY:Int() 
		Return _y
	End Method
	
	Method SetSize(sz:Float) 
		_size = sz
	End Method
	
	Method SetBColor(col:TColor) 
		_color = col
	End Method

	' isOverBoundaries checks if the blip would show on the minimap
	Method isOverBoundaries:Int(startX:Int, startY:Int, width:Int, height:Int) 
		Return _x + _size / 2 < startX Or ..
			_y + _size / 2 < startY Or ..
			_x - _size / 2 > startX + width Or ..
			_y - _size / 2 > startY + height
	End Method
	
	Method Draw() 
		If _size = 0 Then Return		' don't draw 0-sized blips
		SetHandle(_size / 2, _size / 2)     ' oval handle to the middle of the oval
		If _color Then 
			TColor.SetTColor(_color)
		Else
			SetColor(255,255,255)
		EndIf
		If _size < 2 Then
			Plot (_x,_y)
		Else
			DrawOval (_x, _y, _size, _size) 
		End If
	End Method
	
	Function Create:TMapBlip(x:Int, y:Int, size:Int) 
		Local blip:TMapBlip = New TMapBlip
		blip._x = x
		blip._y = y
		blip._size = size
		Return blip
	End Function
End Type