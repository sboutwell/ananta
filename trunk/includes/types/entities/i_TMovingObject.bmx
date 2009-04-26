' *** MOVING SPACE OBJECTS
Type TMovingObject Extends TSpaceObject Abstract
	Global g_L_MovingObjects:TList			' a list to hold all moving objects

	Method Destroy()
		if g_L_MovingObjects Then g_L_MovingObjects.Remove(self)
		Super.Destroy() ' call destroy of TSpaceObject
	End Method
	
	' This method combines collision detection with gravity for speed optimization
	' (distance between each object must be checked in both operations)
	Method DoGravityAndCollisions(gs:TSpaceObject) 
		' get the X and Y coordinates of the gravity source
		Local gsX:Double = gs.GetX() 
		Local gsY:Double = gs.GetY() 
		Local dist:Double = Distance(_x, _y, gsX, gsY) 
		'If squaredDist > 500000000 Then Return	' don't apply gravity if the source is "too far"

		' apply gravity
		If gs.hasGravity And isAffectedByGravity Then
			'g = (G * M) / d^2
			Local a:Double = (c_GravConstant * gs.GetMass()) / dist ^ 2
			
			If a < 0 Then DebugLog self.getName() + " affected by negative gravity! Gravsource: " + gs.GetName()
			
			' update strongest gravity source fields
			If not _strongestGravSource Or _strongestGravity < a Then 
				_strongestGravSource = gs
				_strongestGravity = a
			EndIf
			' ******* NOTE: at some point it might be worthwhile to apply gravity for the strongest gravity source only ******
			
			' get the direction to the gravity source
			Local dirToGravSource:Double = DirectionTo(_x, _y, gsX, gsY) 
			
			' calculate X and Y components of the acceleration
			Local aX:Double = a * (Cos(dirToGravSource)) 
			Local aY:Double = a * (Sin(dirToGravSource)) 
	
			' add to the velocity of the space object
			_Xvel:+aX * G_delta.GetDelta() 
			_Yvel:+aY * G_delta.GetDelta() 
		EndIf

		' do a preliminary circle-to-circle collision detection
		If canCollide And gs.canCollide Then
			If _myCollisionLevel & gs._collisionLevels Or gs._myCollisionLevel & _collisionLevels Then
		
				Local collisionDistance:Double = Self.GetSize() / 2 + gs.GetSize() / 2
				If Dist < collisionDistance Then
					CollideWith(gs, Dist, collisionDistance) 
				End If
			EndIf
		End If
		
	End Method

	Method ApplyGravityAndCollision() 
		' don't bother iterating if gravity and collisions have no effect on this object
		If Not isAffectedByGravity And Not canCollide Then Return
		
		' iterate through all objects in the active System
		For Local obj:TSpaceObject = EachIn TSystem.GetActiveSystem().GetSpaceObjects()
			If obj = Self Then Continue						' don't apply gravity or collision if source is self!
			'If obj._System <> Self._System Then Continue 	' return if the object is in another System
			DoGravityAndCollisions(obj)  	' do gravity and collision checking against 'obj'
		Next
	End Method
	
	' This method is called in collision with 'obj'
	Method CollideWith(obj:TSpaceObject, actualDistance:Double, collisionDistance:Double) 
		' Return if the MOVING object we're colliding with hasn't been updated yet
		' This check ensures that collisions between moving objects are checked only after both
		' objects' positions have been updated. Failure to do so will lead to a double collision response.
		If Not obj.isUpdated And TMovingObject(obj) Then Return
		
		' check for projectile collision
		Local proj:TProjectile = TProjectile(Self) 
		Local proj2:TProjectile = TProjectile(obj) 
		If proj Or proj2 Then
			Local ship:TShip = TShip(obj) 
			' don't collide if the projectile was shot by the colliding ship
			If ship And proj And proj.GetShooter() = ship Then Return
			If ship And proj2 And proj2.GetShooter() = ship Then Return
			CheckProjectileCollision(obj) 
		EndIf
		
		' use type casting to convert spaceobject into moving object, if applicable
		Local mObj:TMovingObject = Null
		If TMovingObject(obj) Then mObj = TMovingObject(obj) 
		' ---
		
		Local collNormalAngle:Float = ATan2(obj.GetY() - _y, obj.GetX() - _x) 
		' position the two balls exactly touching
		Local moveDist1:Double = (collisionDistance - actualDistance) * (obj.GetMass() / Float((_mass + obj.GetMass()))) 
		Local moveDist2:Double = (collisionDistance - actualDistance) * (_mass / Float((_mass + obj.GetMass()))) 
		_x = _x + moveDist1 * Cos(collNormalAngle + 180) 
		_y = _y + moveDist1 * Sin(collNormalAngle + 180) 
		obj.SetX(obj.GetX() + moveDist2 * Cos(collNormalAngle)) 
		obj.SetY(obj.GetY() + moveDist2 * Sin(collNormalAngle)) 
		
		
		' COLLISION RESPONSE
		' n = vector connecting the centers of the colliding circles
		' find the components of the normalised vector n
		Local nX:Double = Cos(collNormalAngle) 
		Local nY:Double = Sin(collNormalAngle) 
		' find the length of the components of movement vectors (dot product)
		Local a1:Double = GetXVel() * nX + GetYVel() * nY
		Local a2:Double = 0
		If mObj Then
			a2 = mObj.GetXVel() * nX + mObj.GetYVel() * nY
		EndIf
		' optimisedP = 2(a1 - a2)
		'             ----------
		'              m1 + m2
		Local optimisedP:Double = (2.0 * (a1 - a2)) / (_mass + obj.GetMass()) 
		
		' now find out the resultant vectors
		Local elas:Float = 0.7 ' 30% elastic collision
		Self.SetXVel(Self.GetXVel() - (optimisedP * elas * obj.GetMass() * nX)) 
		Self.SetYVel(Self.GetYVel() - (optimisedP * elas * obj.GetMass() * nY)) 
		
		' find out how much kinetic energy is transformed into damage
		Local xVelAbsorb:Double = (optimisedP * (1 - elas) * obj.GetMass() * nX) 
		Local yVelAbsorb:Double = (optimisedP * (1 - elas) * obj.GetMass() * nY) 
		Local CollEnergy:Float = 0.5 * Self.GetMass() * xVelAbsorb ^ 2 * yVelAbsorb ^ 2 / 100000000
		
		'If Self.GetName() = "Player ship" Then
		'	G_debugWindow.AddText ("CollEnergy: " + collEnergy) 
		'End If
		If TStar(obj) Then collEnergy = 99999999
		If collEnergy > 150 Then SustainDamage(CollEnergy) 

		' damage to the other object...
		xVelAbsorb:Double = (optimisedP * (1 - elas) * Self.GetMass() * nX) 
		yVelAbsorb:Double = (optimisedP * (1 - elas) * Self.GetMass() * nY) 
		CollEnergy:Float = 0.5 * obj.GetMass() * xVelAbsorb ^ 2 * yVelAbsorb ^ 2 / 100000000
		'If obj.GetName() = "Player ship" Then
		'	G_debugWindow.AddText ("CollEnergy: " + collEnergy) 
		'End If
		If collEnergy > 150 Then obj.SustainDamage(CollEnergy) 

				
		'G_DebugWindow.AddText(optimisedP)
		
		If mObj Then
			mObj.SetXVel(mObj.GetXVel() + (optimisedP * Self.GetMass() * nX)) 
			mObj.SetYVel(mObj.GetYVel() + (optimisedP * Self.GetMass() * nY)) 
		End If
		
		
		'endrem
	End Method

	' special weapons collision test and damage
	Method CheckProjectileCollision(obj:TSpaceObject) 
		Local proj:TProjectile = TProjectile(Self) 
		If proj Then	' if this object is a projectile...
			Self.SetXVel(obj.GetXVel()) 
			Self.SetYVel(obj.GetYVel()) 
			
			obj.SustainDamage(proj.GetDamage()) 
			
			
			' if the shot object is an asteroid, award the shooter with some shields
			If TAsteroid(obj) Then proj.GetShooter().SustainDamage(- proj.GetDamage() / 10) 
			
			' destroy the projectile
			Self.Explode() 
			
		End If
		
		If TProjectile(obj) Then	' if the object we're colliding with is a projectile...
			Local proj:TProjectile = TProjectile(obj) 
			proj.SetXVel(GetXVel()) 
			proj.SetYVel(GetYVel()) 
			
			SustainDamage(proj.GetDamage()) 
			
			' if the shot object is an asteroid, award the shooter with some shields
			If TAsteroid(Self) Then proj.GetShooter().SustainDamage(- proj.GetDamage() / 5) 
			
			obj.Explode() 
		End If
	EndMethod
		
	' CalcOrbitalVelocity calculates the radial velocity required to maintain a stable orbit around body
	Method CalcOrbitalVelocity:Double(body:TSpaceObject) 
		Return Sqr(c_GravConstant * body.GetMass() / Distance(_x, _y, body.GetX(), body.GetY())) 
	End Method
	
	' Returns the direction in degrees the object is moving to
	Method CalcMovingDirection:Double()
		Return DirectionTo(_x,_y, _x + _xVel, _y + _yVel)
	End Method
	
	' SetOrbitalVelocity sets xVel and yVel to maintain a stable orbit around body
	Method SetOrbitalVelocity(body:TSpaceObject, clockwise:Int = True) 
		Local vel:Double = CalcOrbitalVelocity(body) 
		Local dirTo:Float = DirectionTo(_x, _y, body.GetX(), body.GetY()) 
		Local dir:Float
		
		If clockwise Then dir = dirTo - 90
		If Not clockwise Then dir = dirTo + 90
		
		_yVel = Sin(dir) * vel
		_xVel = Cos(dir) * vel				 
	End Method
	
	' Update the position of the moving object. warpvalue is given when a ship's warp drive's on
	Method UpdatePosition(warpValue:Float = 1.0) 
		_x = _x + _xVel * G_delta.GetDelta() * warpValue
		_y = _y + _yVel * G_delta.GetDelta() * warpValue
	End Method
	
	Method Update() 
		' if attached to a moving object, override velocity with the parent object's velocity
		If TMovingObject(_parentObject) Then
			Local o:TMovingObject = TMovingObject(_parentObject) 
			_xVel = o.GetXVel() 
			_yVel = o.GetYVel() 
			' call the update-method of TSpaceObject to update rotation and position
			Super.Update() 
			Return
		EndIf
		
		' rotate the object
		_rotation:+_rotationSpd * G_delta.GetDelta() 
		If _rotation < 0 _rotation:+360
		If _rotation>=360 _rotation:-360
		
		' update the position
		UpdatePosition()
    	
		' call the update-method of TSpaceObject
		Super.Update() 
		
		' apply gravity and do collision checking
		ApplyGravityAndCollision() 
	EndMethod
	
	Function UpdateAll()
		If Not g_L_MovingObjects Then Return
		For Local o:TMovingObject = EachIn g_L_MovingObjects
			o.Update() 
		Next
	EndFunction
	
EndType

