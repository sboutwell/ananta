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

' Returns the difference in degrees between two angles.
' Result is positive when ang2 is to the right of ang1, negative when to the left.
Function GetAngleDiff:Double(ang1:Double,ang2:Double)
	Local diff:Double=ang2-ang1
	While diff>180
		diff=diff-360
	Wend
	While diff<-180
		diff=diff+360
	Wend
	Return diff
End Function

' sums two direction angles in degrees, returned direction 0..360
Function DirAdd:Double(ang:Double,add:Double)
	Local newDir:Double = ang + add
	If newDir < 0 Then newDir:+360
	If newDir>=360 Then newDir:-360
	Return newDir
End Function

' Calculates the distance travelled while accelerating (or decelerating)
' when initial speed (v), time for acceleration (t) and acceleration (a) are given.
' s = vt + ½at^2
Function CalcAccelerationDistance:Double(speed:Double,time:Double,acceleration:Double)
	Return speed * time + (0.5 * acceleration * (time * time))
EndFunction

Function CalcAccelerationTime:Double(speed:Double,distance:Double,acceleration:Double)
	'v   = s + at
	Return -distance*acceleration^-1.0 + speed*acceleration^-1.0
EndFunction



' Functions to convert degrees to radians and vice versa
Function RadToDeg:Float(rad:Float) 
	Return rad * 57.2957795
EndFunction
Function DegToRad:Float(deg:Float)
	Return deg * 0.0174532925
EndFunction

' Calculates rotational inertia of a cylindrical body with given mass and radius
Function CalcRotInertia:Float(mass:Float,radius:Float)
	' I = ½MR^2
	Return 0.5 * mass * (radius * radius) 
EndFunction

' Calculates the rotational acceleration (radians/s^2) 
' when a force is applied perpendicularly to a 
' cylindrical object of given radius at a 
' given distance from the mass center. Capiche? ;)
Function CalcRotAcceleration:Float(force:Int, radius:Float, mass:Float, distance:Double) 
		Return (force*distance)/CalcRotInertia(mass,radius)
EndFunction

' Returns the direction in degrees from point [x1,y1] to point [x2,y2]
Function DirectionTo:Double(x1:Double, y1:Double, x2:Double, y2:Double) 
	Return ATan2(y1 - y2, x1 - x2) + 180
EndFunction

Function DistanceSquared:Double(x1:Double, y1:Double, x2:Double, y2:Double) 
	Return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
End Function

Function Distance:Double(x1:Double, y1:Double, x2:Double, y2:Double) 
	Return Sqr((x1 - x2) ^ 2 + (y1 - y2) ^ 2) 
End Function

Function GetSpeed:Double(xVel:Double, yVel:Double)
	If xVel = 0 AND yVel = 0 Then Return 0
	Return Sqr(xVel ^ 2 + yVel ^ 2) 
End Function

' Fast function to compare distances in x-y plane
' Returns 0 if dst0 is closer to src, or 1 if dst1 is closer to src.
Function ReturnClosestOfTwo:Int(src_x:Double, src_y:Double, dst0_x:Double, dst0_y:Double, dst1_x:Double, dst1_y:Double) 
	Return (src_x - dst0_x) ^ 2 + (src_y - dst0_y) ^ 2 > (src_x - dst1_x) ^ 2 + (src_y - dst1_y) ^ 2
EndFunction

' Returns the image size in pixels. 
' If useDiamager = True, returns corner-to-corner size. Otherwise returns the longest side length.
Function CalcImageSize:Int(img:TImage, useDiameter:Int = True) 
	If useDiameter Then Return Sqr((ImageWidth(img) ^ 2 + ImageHeight(img) ^ 2)) 	
	If ImageWidth(img) > ImageHeight(img) Then Return ImageWidth(img) 
	Return ImageHeight(img)
End Function

Function ToggleBoolean(bool:Int Var) 
	bool = Not bool
End Function

' Returns an integer representation of RGBA pixel values
Function MakeCol:Int(a:Byte, r:Byte, g:Byte, b:Byte) 
	Local n:Int
	Local m:Byte Ptr = Varptr n
	m[0] = b
	m[1] = g
	m[2] = r
	m[3] = a
	Return n
EndFunction

' The opposite of MakeCol: parses an integer representation of a pixel into RGBA values
Function GetCol(px:Int, a:Byte Var, r:Byte Var, g:Byte Var, b:Byte Var) 
	a = px Shr 24
	b = px Shr 16
	g = px Shr 8
	r = px	
End Function

' bit rotating functions
Function rotr:Int(num:Int, amount:Int)
	Return rotateBits(num, 32, - amount)
End Function

Function rotl:Int(num:Int, amount:Int)
	Return rotateBits(num, 32, amount)
End Function

Function rotateBits:Int(num:Int, bitLength:Int = 32, rotate:Int = 1)
'bitLength can be anything up to 32
'if rotate > 0 then rotates left, < 0 rotates right
	Local mask1:Long = $00000000FFFFFFFF:Long Shr (32 - bitLength)
	Local mask2:Long=mask1 Shl bitLength
	
	Local number:Long = Long(num) & mask1	'force number to a long to avoid probs with bit 32

	If rotate > 0
	   number:Shl rotate
	Else
	   number:Shl bitLength - Abs(rotate)
	EndIf
	
	number = ((number & mask2) Shr bitLength) | (number & mask1)
	
	Return number
End Function

' **** Value limiting functions. 
Function limitInt(val:Int Var, limitMin:Int, limitMax:Int)
	If val < limitMin Then val = limitMin
	IF val > limitMax Then val = limitMax
End Function
Function limitLong(val:Long Var, limitMin:Long, limitMax:Long)
	If val < limitMin Then val = limitMin
	IF val > limitMax Then val = limitMax
End Function
Function limitFloat(val:Float Var, limitMin:Float, limitMax:Float)
	If val < limitMin Then val = limitMin
	IF val > limitMax Then val = limitMax
End Function
Function limitDouble(val:Double Var, limitMin:Double, limitMax:Double)
	If val < limitMin Then val = limitMin
	IF val > limitMax Then val = limitMax
End Function
' *************************


' Not sure where to put these. Math functions seem the closest.
' http://www.blitzbasic.com/Community/posts.php?topic=47133
' Perturbatio

Function MouseXSpeed:Int()
	Global lastX:Int =0
	Local result:Int = MouseX()-lastX
	lastX = MouseX()	
	Return result
End Function


Function MouseYSpeed:Int()
	Global lastY:Int =0
	Local result:Int = MouseY()-lastY
	lastY = MouseY()	
	Return result
End Function


Function MouseZSpeed:Int()
	Global lastZ:Int =0
	Local result:Int = MouseZ()-lastZ
	lastZ = MouseZ()	
	Return result
End Function

