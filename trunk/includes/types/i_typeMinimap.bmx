Type TMinimap
	Field _L_blips:TList
	Field _scale:Float = 0.01
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the minimap in pixels
	Field _width:Int	' width of the minimap in pixels
	
	Field _alpha:Float
	Field _planetColor:TColor
	Field _shipColor:TColor
	Field _centerColor:TColor
	
	Method AddBlip(o:TSpaceObject) 
		
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		Local x:Int = (viewport.GetCameraPosition_X() - o.GetX()) * _scale + midX + _startX
		Local y:Int = (viewport.GetCameraPosition_Y() - o.GetY()) * _scale + midY + _startY
		Local size:Int = o.GetSize() * _scale
		If size < 2 Then size = 2
		Local blip:TBlip = TBlip.Create(x, y, size) 
		
		' use casting to find out the type of the object
		If TPlanet(o) Then blip.SetBColor(_planetColor) 
		If TShip(o) Then blip.SetBColor(_ShipColor) 
		
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
		
		DrawCenter() 
		
		' after drawing all blips, clear the list
		If _L_blips Then _L_Blips.Clear() 
	End Method
	
	Method DrawCenter() 
		SetAlpha(1) 
		TColor.SetTColor(Self._centerColor) 
		DrawOval(_startX + _width / 2, _startY + _height / 2, 2, 2) 
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
		map._centerColor = TColor.FindColor("lime") 
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
		TColor.SetTColor(_color) 
		SetHandle(_size / 2, _size / 2)   ' oval handle to the middle of the oval
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