' Returns the difference in degrees between two angles.
' Result is positive when ang2 is to the right of ang1, negative when to the left.
Function GetAngleDiff:Float(ang1:Float,ang2:Float)
	Local diff:Float=ang2-ang1
	While diff>180
		diff=diff-360
	Wend
	While diff<-180
		diff=diff+360
	Wend
	Return diff
End Function

' Calculates the distance travelled while accelerating (or decelerating)
' when initial speed (v), time for acceleration (t) and acceleration (a) are given.
' s = vt + ½at^2
Function CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
	Return speed * time + (0.5 * acceleration * (time * time))
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
	Return 0.5 * mass * radius * radius
EndFunction

' Calculates the rotational acceleration (radians/s^2) 
' when a force is applied perpendicularly To a cylindrical object of given radius at a given distance from the mass center
Function CalcRotAcceleration:Float(force:Int,radius:Float,mass:Float,distance:Float)
		Return (force*distance)/CalcRotInertia(mass,radius)
EndFunction

' Returns the direction in degrees from point [x1,y1] to point [x2,y2]
Function DirectionTo:Float(x1:Float,y1:Float,x2:Float,y2:Float)
	Local direction:Float = ATan2(y1-y2,x1-x2)+180
	Return direction
EndFunction