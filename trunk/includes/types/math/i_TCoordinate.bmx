rem
	TCoordinate is a struct-like types representing a 2d-coordinate pair 
endRem

Type TCoordinate
	Field _x:Float
	Field _y:Float
	
	Method Get:Float[] () 
		Return[_x, _y] 
	End Method
	
	Method GetX:Float() 
		Return _x
	End Method
	
	Method GetY:Float() 
		Return _y
	End Method
	
	Method SetX(x:Float) 
		_x = x
	End Method
	
	Method SetY(y:Float) 
		_y = y
	End Method
	
	Method Set(x:Float, y:Float) 
		_x = x
		_y = y
	End Method
	
	Function Create:TCoordinate(x:Float, y:Float) 
		Local c:TCoordinate = New TCoordinate
		c._x = x
		c._y = y
		Return c
	End Function
End Type
