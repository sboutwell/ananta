Rem
	Zoomable minimap and the related types and functions
EndRem

Type TMinimap
	Field _L_blips:TList
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the minimap in pixels
	Field _width:Int	' width of the minimap in pixels
	Field _midX:Float	' middle X coordinate
	Field _midY:Float	' middle Y coordinate
	
	Field _scale:Float = 0.01

	Field _defaultZoom:Float = 0.2
	Field _zoomFactor:Float
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	
	Field _alpha:Float
	Field _planetColor:TColor
	Field _shipColor:TColor
	Field _selfColor:TColor
	Field _velColor:TColor
	Field _miscColor:TColor
	
	Field _attitudeIndicator:TImage
	
	Method AddBlip(o:TSpaceObject) 
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		Local x:Int = (viewport.GetCameraPosition_X() - o.GetX()) * _scale * _zoomFactor + midX + _startX
		Local y:Int = (viewport.GetCameraPosition_Y() - o.GetY()) * _scale * _zoomFactor + midY + _startY
		Local size:Int = o.GetSize() * _scale * _zoomFactor
		If size < 2 Then size = 2
		Local blip:TBlip = TBlip.Create(x, y, size) 
		
		' use casting to find out the type of the object
		blip.SetBColor(_miscColor) 
		If TPlanet(o) Then blip.SetBColor(_planetColor) 
		If TShip(o) Then blip.SetBColor(_ShipColor) 
		
		' special behaviour for the centered blip
		If o = viewport._centeredObject Then
			blip.SetBColor(_selfColor) 
			If TShip(o) And blip.GetSize() < 3 Then blip.SetSize(0.0) 
		EndIf

		If Not _L_blips Then _L_blips = New TList
		If blip.GetSize() > 0 Then _L_blips.AddLast(blip) 
	End Method
	
	Method Draw() 
		If Not _L_Blips Then Return
		SetViewport(_startX, _startY, _width, _height) 
		SetBlend(ALPHABLEND) 
		SetAlpha(_alpha) 
		SetMaskColor(255, 255, 255) 
		SetScale(1, 1) 
		For Local blip:TBlip = EachIn _L_Blips
			' If no part of the blip would be visible on the screen, don't bother to draw it
			If blip.isOverBoundaries(_startX, _startY, _width, _height) Then
				Continue
			Else
				blip.Draw() 				
			EndIf
		Next
		
		SetHandle(0, 0) 
		
		' after drawing all blips, clear the list
		If _L_blips Then _L_Blips.Clear() 
		
		' draw miscellaneous map details
		DrawDetails() 
	End Method

	Method DrawDetails() 
		' use type casting to determine if the centered object is a TMovingObject
		Local obj:TMovingObject = TMovingObject(viewport.GetCenteredObject()) 
		If Not obj Then Return		' return if object is not a moving object
		DrawVelocityVector(obj)  	' draw velocity vector for the centered object
		
		' use type casting to determine if the centered object is a TShip
		Local ship:TShip = TShip(viewport.GetCenteredObject()) 
		If Not ship Then Return		' return if the object is not a ship
		DrawAttitudeIndicator(ship)    ' draw the T-shaped attitude indicator to the middle of the map
	End Method	
		
	Method DrawVelocityVector(obj:TMovingObject) 
		TColor.SetTColor(_velColor) 
		SetAlpha(0.3) 
		
		Local vX:Float = obj.GetXVel() / 10
		Local vY:Float = obj.GetYVel() / 10
		
		SetScale(1, 1) 
		SetLineWidth(1) 
		DrawLine(_midX - vX, _midY - vY, _midX, _midY, False) 
	End Method

	Method DrawAttitudeIndicator(obj:TShip) 
		SetScale(0.3, 0.3) 
		SetBlend(ALPHABLEND) 
		SetAlpha(0.5) 
		SetRotation(obj.GetRot() + 90) 
		SetColor(255, 255, 255) 
		DrawImage(_attitudeIndicator, _midX, _midY) 
		SetRotation(0) 
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
		map._midX = x + w / 2.0
		map._midY = y + h / 2.0
		
		map._defaultZoom = 0.2
		map._zoomFactor = map._defaultZoom
		
		map._alpha = 0.8
		map._shipColor = TColor.FindColor("yellow") 
		map._selfColor = TColor.FindColor("lime") 
		map._planetColor = TColor.FindColor("cobalt") 
		map._velColor = TColor.FindColor("lime") 
		map._miscColor = TColor.FindColor("cyan") 
		
		map._attitudeIndicator = TImg.LoadImg("attitude.png") 
		
		Return map
	End Function
EndType

Type TBlip
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
	
	' isOverBoundaries checks if the blip would show on the minimap
	Method isOverBoundaries:Int(startX:Int, startY:Int, width:Int, height:Int) 
		Return _x + _size / 2 < startX Or ..
			_y + _size / 2 < startY Or ..
			_x - _size / 2 > startX + width Or ..
			_y - _size / 2 > startY + height
	End Method
	
	Method SetBColor(col:TColor) 
		_color = col
	End Method
	
	
	Method Draw() 
		If _size = 0 Then Return		' don't draw 0-sized blips
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