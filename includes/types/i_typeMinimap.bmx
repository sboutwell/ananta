Type TMinimap
	Field _L_blips:TList
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the minimap in pixels
	Field _width:Int	' width of the minimap in pixels
	
	Field _scale:Float = 0.01
	
	Field _zoomFactor:Float = 1
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	
	Field _alpha:Float
	Field _planetColor:TColor
	Field _shipColor:TColor
	Field _selfColor:TColor
	
	Method AddBlip(o:TSpaceObject) 
		
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		Local x:Int = (viewport.GetCameraPosition_X() - o.GetX()) * _scale * _zoomFactor + midX + _startX
		Local y:Int = (viewport.GetCameraPosition_Y() - o.GetY()) * _scale * _zoomFactor + midY + _startY
		Local size:Int = o.GetSize() * _scale * _zoomFactor
		If size < 2 Then size = 2
		Local blip:TBlip = TBlip.Create(x, y, size) 
		
		' use casting to find out the type of the object
		If TPlanet(o) Then blip.SetBColor(_planetColor) 
		If TShip(o) Then blip.SetBColor(_ShipColor) 
		
		' if the object is the centered object, use "_selfcolor" to represent the center dot
		If o = viewport._centeredObject Then blip.SetBColor(_selfColor) 
		
		If Not _L_blips Then _L_blips = New TList
		_L_blips.AddLast(blip) 
	End Method
	
	Method Draw() 
		If Not _L_Blips Then Return
		SetViewport(_startX, _startY, _width, _height) 
		SetBlend(ALPHABLEND) 
		SetAlpha(_alpha) 
		SetMaskColor(255, 255, 255) 
		SetScale(1, 1) 
		For Local blip:TBlip = EachIn _L_Blips
			blip.Draw() 
		Next
		
		' after drawing all blips, clear the list
		If _L_blips Then _L_Blips.Clear() 
	End Method
	
	Method SetZoomFactor(z:Float) 
		_zoomfactor = z
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
	
	Function Create:TMinimap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TMinimap = New TMinimap
		If x + w > viewport.GetResX() Then x = viewport.GetResX() - w
		If y + h > viewport.GetResY() Then y = viewport.GetResY() - h
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		
		map._alpha = 0.8
		map._shipColor = TColor.FindColor("yellow") 
		map._selfColor = TColor.FindColor("lime") 
		map._planetColor = TColor.FindColor("cobalt") 
		Return map
	End Function
EndType

Type TBlip
	Field _x:Int
	Field _y:Int
	Field _size:Float
	
	Field _color:TColor

	Method SetBColor(col:TColor) 
		_color = col
	End Method
	
	Method Draw() 
		' if no part of the blip would be visible on the screen, don't bother to draw it
		If _x - _size > viewport.GetResX() Or _y - _size > viewport.GetResY() ..
			Or _x + _size < 0 Or _y + _size < 0 Then Return
			
		TColor.SetTColor(_color) 
		SetHandle(_size / 2, _size / 2)    ' oval handle to the middle of the oval
		DrawOval(_x, _y, _size, _size) 
	End Method
	
	Function Create:TBlip(x:Int, y:Int, size:Int) 
		Local blip:TBlip = New TBlip
		blip._x = x
		blip._y = y
		blip._size = size
		Return blip
	End Function
End Type