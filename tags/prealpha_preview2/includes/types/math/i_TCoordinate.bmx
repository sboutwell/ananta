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
