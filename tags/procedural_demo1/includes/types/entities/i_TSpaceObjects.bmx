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
	*************************************************************************************************
	***************************************** SPACEOBJECTS ******************************************
	*************************************************************************************************
	Description: All drawable objects that can exist in a star System

	TSpaceObject
		TJumpPoint
		TStellarObject
			TStar
			TPlanet
			TSpaceStation
		TMovingObject
			TShip
			TAsteroid
			TParticle
				TProjectile
			 
EndRem

Type TSpaceObject Abstract
	Field _image:TImage					' The image to represent the object
	Field _alpha:Float = 1				' Alpha channel value of the image
	Field _x:Double, _y:Double			' x-y coordinates of the object
	Field _system:TSystem				' the system the object is in
	Field _rotation:Float				' rotation in degrees
	Field _mass:Long					' The mass of the object in kg
	Field _size:Int						' The visual diameter of the object, to display the object in correct scale in the minimap
	Field _scaleX:Float = 1				' The scale of the drawn image (1 being full resolution, 2 = double size, 0.5 = half size)
	Field _scaleY:Float = 1				
	Field _name:String = "Nameless"		' The name of the object
	Field _isShownOnMap:Int = False		' flag to indicate minimap visibility
	Field _hasGravity:Int	= False			' a true-false flag to indicate gravitational pull
	Field _xVel:Double						' velocity vector x-component
	Field _yVel:Double						' velocity vector y-component
	Field _rotationSpd:Float				' rotation speed in degrees per second
	Field _affectedByGravity:Int = True		' does gravity affect the object?
	Field _canCollide:Int = False			' flag to indicate if this object can collide with other objects with the same flag set
	Field _updated:Int = False			' a flag to indicate if this object has been updated during the frame
	Field _integrity:Float = -1			' the amount of damage the object can handle, -1 for indestructible
	
		
	' attachment-related fields
	Field _L_TopAttachments:TList		' top attachments to the object	(visually above this object)
	Field _L_BottomAttachments:TList	' bottom attachments to the object (visually below this object)
	Field _parentObject:TSpaceObject	' the parent object this object is attached to, if applicable
	Field _xOffset:Float = 0			' x-position of the attachment compared to the x of the parent
	Field _yOffset:Float = 0			' y-position of the attachment compared to the y of the parent
	Field _rotationOffset:Float 		' rotation compared to the parent rotation
	
	Method Destroy() Abstract
	
	' make the object take some damage
	Method SustainDamage(dam:Float) 
		If _integrity = -1 Then Return		' indestructible	
		_integrity = _integrity - dam		' She can't take much more o' this, cap'n!
		If _integrity <= 0 Then Explode()   ' My god, cap'n, she's gonna blow!
	End Method
	
	Method Explode() 
		' a makeshift "explosion" effect for testing. Redo this with some pretty particle fireworks.
		Local expScale:Float = CalcImageSize(_image) / 128.0 * _scaleX * 1.5
		Local part:TParticle = TParticle.Create(TImg.LoadImg("smoke.png"), _x, _y, 2, expScale, 1, _System) 
		part.SetXVel(_xVel) 
		part.SetYVel(_yVel) 
		part.SetRot(Rand(0, 360)) 
		part.SetRotationSpd(Self.GetRotSpd() + Rnd(- 10, 10)) 
		part._affectedByGravity = True
		 
		Destroy() 
	End Method
		
	' draws the body of the spaceobject
	Method DrawBody(vp:TViewport, drawAsAttachment:Int = False)
		If Not _image Then Return	' don't draw if no image is defined
		
		' don't draw the object if it's an attachment 
		' to another object but the method was NOT called with the drawAsAttachment flag on
		If Not drawAsAttachment And _parentObject Then Return
		
		' draw bottom attachments if any
		If _L_BottomAttachments Then
			For Local a:TSpaceObject = EachIn _L_BottomAttachments
				a.Update() 
				a.DrawBody(vp, True) 
			Next
		EndIf
		
		' ********* preload values that are used more than once
		Local startX:Int = vp.GetStartX() 
		Local startY:Int = vp.GetStartY()
		Local midX:Int = vp.GetMidX()
		Local midY:Int = vp.GetMidY()
		' *********
		Local x:Double = (vp.GetCameraPosition_X() - _x) * viewport.GetZoomFactor() + midX + startX
		Local y:Double = (vp.GetCameraPosition_Y() - _y) * viewport.GetZoomFactor() + midY + startY
		
		' This commented code block is trying to define if the object will be visible on the screen to avoid
		' drawing non-visible objects. Not working. So, in the meantime we'll suffer from a performance hit.
		'If x + _size * _scaleX * viewport._zoomfactor / 2 < startX Then Return
		'If x - _size * _scaleX * viewport._zoomFactor / 2 > startX + vp.GetWidth() Then Return
				
		SetViewport(startX, startY, vp.GetWidth(), vp.GetHeight()) 
		'SetViewport(0, 0, 800, 600) 
		SetAlpha _alpha
		SetRotation _rotation + 90
		SetBlend ALPHABLEND
		SetColor 255,255,255
		SetScale _scaleX * viewport._zoomFactor, _scaleY * viewport._zoomFactor
		
		DrawImage _image, x, y
		
		' draw top attachments if any
		If _L_TopAttachments Then
			For Local a:TSpaceObject = EachIn _L_TopAttachments
				a.Update() 
				a.DrawBody(vp, True) 
			Next
		EndIf
	EndMethod
	
	' this update method is currently mainly for attachment positioning purposes...
	Method Update() 
		If _parentObject Then	' is attached to another object...
			Local pRot:Float = _parentObject.GetRot() 
			Local pX:Double = _parentObject.GetX() 
			Local pY:Double = _parentObject.GetY() 
			_x = pX + _xOffset * Cos(pRot) + _yOffset * Sin(pRot) 
			_y = pY + _xOffset * Sin(pRot) - _yOffset * Cos(pRot) 
			_rotation = pRot + _rotationOffset
		EndIf
		_updated = True
	End Method
	
	' attach another object. Attached objects cannot move themselves.
	Method AddAttachment(obj:TSpaceObject, xo:Float = 0, yo:Float = 0, roto:Float = 0, onTop:Int = True) 
		obj._parentObject = Self
		obj._xOffset = xo
		obj._yOffset = yo
		obj._rotationOffset = roto
		
		If Not _L_TopAttachments Then _L_TopAttachments = CreateList() 
		If Not _L_BottomAttachments Then _L_BottomAttachments = CreateList() 
		If onTop Then _L_TopAttachments.AddLast(obj) 
		If Not onTop Then _L_BottomAttachments.AddLast(obj) 
		
		' add the mass to this object's total mass
		_mass:+obj.GetMass() 
		
		' if the parent object is a ship, update ship's performance values
		If TShip(Self) Then	' type-casting
			Local ship:TShip = TShip(Self) 
			ship.UpdatePerformance() 
		End If
	End Method

	Method GetScaleX:Float()
		Return _scaleX
	End Method

	Method GetScaleY:Float()
		Return _scaleY
	End Method
	
	Method GetVel:Float() 
		Return Sqr(_xVel ^ 2 + _yVel ^ 2) 
	End Method
	
	Method GetXVel:Double() 
		Return _xVel
	End Method
	
	Method GetYVel:Double() 
		Return _yVel
	End Method
	
	Method GetRotSpd:Float()
		Return _rotationSpd
	End Method
	
	Method SetXVel(x:Double) 
		_xVel = x
	End Method
	
	Method SetYVel(y:Double) 
		_yVel = y
	End Method
	
	Method SetRotationSpd(r:Float) 
		_rotationSpd = r
	End Method
		
	Method SetRot(r:Float) 
		_rotation = r
	End Method
	
	Method SetSystem(s:TSystem)
		_system = s
	End Method
	
	Method GetMass:Float() 
		Return _mass
	End Method
	
	Method GetRot:Float()
		Return _rotation
	End Method

	Method GetSize:Int()
		Return _size
	End Method
	
	Method GetX:Double() 
		Return _x
	End Method
	
	Method GetY:Double() 
		Return _y
	End Method

	Method GetIntegrity:Float() 
		Return _integrity
	End Method
	
	Method showsOnMap:Int() 
		Return _isShownOnMap
	End Method
	
	Method SetX(coord:Double) 
		_x = coord
	End Method
	
	Method SetY(coord:Double) 
		_y = coord
	End Method
	
	Method SetScaleX(s:Float)
		_scaleX = s
	End Method
	
	Method SetScaleY(s:Float)
		_scaleY = s
	End Method

	Method SetName(s:String) 
		_name = s
	End Method
	
EndType

' Not used
Type TJumpPoint Extends TSpaceObject
	Global g_L_JumpPoints:TList		' a list to hold all JumpPoints
	Field _destinationJp:TJumpPoint	' the connected JumpPoint
	
	Method Destroy() 
		
	End Method
	
	Function Create:TJumpPoint(x:Int,y:Int,System:TSystem,destination:TJumpPoint)
		Local jp:TJumpPoint = New TJumpPoint		' create an instance
		jp._x = x; jp._y = y						' coordinates
		jp._System = System									' the System
		jp._destinationJp = destination					' the destination JumpPoint
		jp._isShownOnMap = True
		
		If Not g_L_JumpPoints Then g_L_JumpPoints = CreateList()	' create a list if necessary
		g_L_JumpPoints.AddLast jp											' add the newly created object to the end of the list

		System.AddSpaceObject(jp) 		' add the jumppoint to the System's space object list

		Return jp																		' return the pointer to this specific object instance
	EndFunction
EndType


' *** STATIONARY STELLAR OBJECTS
Type TStellarObject Extends TSpaceObject Abstract
	Global g_L_StellarObjects:TList			' a list to hold all major stellar bodies (Stars, planets and space stations)
EndType

Type TStar Extends TStellarObject
	
	Method Destroy() 
		
	End Method

	' uses Cairo vector graphics library to generate a star image of a radius supplied by a parameter
	Function GenerateStarTexture:TImage(r:Int) 
		Local cairo:TCairo = TCairo.Create(TCairoImageSurface.CreateForPixmap(r * 2, r * 2)) 
	
		Local normalizeMat:TCairoMatrix = TCairoMatrix.CreateScale(r * 2, r * 2) 
		cairo.SetMatrix(normalizeMat) 
		
		Local pat:TCairoPattern = TCairoPattern.CreateRadial (0.5, 0.5, 6, 0.5, 0.5, 30) 
		pat.AddColorStopRGBA(1, 1, 1, 0.5, 1) 
		pat.AddColorStopRGBA(0, 0.95, 0.95, 0, 1) 
		cairo.SetSource(pat) 
		cairo.Arc(0.5, 0.5, 0.5, 0, 360) 
		cairo.Fill() 
			
		' fix fill color to current
		cairo.Fill() 
		
		' Retrieve the image data from the pixmap
		Local image:TImage = LoadImage(TCairoImageSurface(cairo.getTarget()).pixmap()) 
		
		' destroy context and resources
		cairo.Destroy() 
	
		Return image
	End Function
		
	Function Create:TStar(x:Int=0,y:Int=0,System:TSystem,mass:Long,size:Int,name:String)
		Local st:TStar = New Tstar				' create an instance
		st._name = name								' give a name
		st._x = x; st._y = y							' coordinates
		st._System = System							' the System
		st._mass = mass								' mass in kg
		st._size = size								' size in pixels
		st._hasGravity = True
		st._canCollide = True
		st._isShownOnMap = True

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

		System.AddSpaceObject(st)		' add the body to System's space objects list
		
		Return st																' Return the pointer To this specific Object instance
	EndFunction
EndType

Type TPlanet Extends TStellarObject
	Method Destroy() 
		
	End Method
	
	Function Create:TPlanet(x:Int,y:Int,System:TSystem,mass:Long,size:Int,name:String)
		Local pl:TPlanet = New TPlanet					' create an instance
		pl._name = name										' give a name
		pl._x = x; pl._y = y									' coordinates
		pl._System = System									' the System
		pl._mass = mass										' mass in kg
		pl._size = size										' size in pixels
		pl._hasGravity = True
		pl._canCollide = True
		pl._isShownOnMap = True
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast pl											' add the newly created object to the end of the list
		
		System.AddSpaceObject(pl)		' add the body to System's space objects list
		
		Return pl																' return the pointer to this specific object instance
	EndFunction
EndType

' not used
Type TSpaceStation Extends TStellarObject
	Method Destroy() 
		
	End Method

	Function Create:TSpaceStation(x:Int,y:Int,System:TSystem,mass:Long,size:Int,name:String)
		Local ss:TSpaceStation = New TSpaceStation	' create an instance
		ss._name = name										' give a name
		ss._x = x; ss._y = y									' coordinates
		ss._System = System									' the System
		ss._mass = mass										' mass in kg
		ss._size = size										' size in pixels
		ss._hasGravity = False
		ss._canCollide = True
		ss._isShownOnMap = True
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast ss												' add the newly created object to the end of the list
		
		System.AddSpaceObject(ss)		' add the body to System's space objects list
		
		Return ss																			' return the pointer to this specific object instance
	EndFunction
EndType


' *** MOVING SPACE OBJECTS
Type TMovingObject Extends TSpaceObject Abstract
	Global g_L_MovingObjects:TList			' a list to hold all moving objects

	' This method combines collision detection with gravity for speed optimization
	' (distance between each object must be checked in both operations)
	Method DoGravityAndCollisions(gs:TSpaceObject) 
		' get the X and Y coordinates of the gravity source
		Local gsX:Double = gs.GetX() 
		Local gsY:Double = gs.GetY() 
		Local dist:Double = Distance(_x, _y, gsX, gsY) 
		'If squaredDist > 500000000 Then Return	' don't apply gravity if the source is "too far"

		' apply gravity
		If gs._hasGravity Then
			'g = (G * M) / d^2
			Local a:Double = (c_GravConstant * gs.GetMass()) / dist ^ 2
			
			If a < 0 Then DebugLog Self._name + " affected by negative gravity! Gravsource: " + gs._name
			
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
		If _canCollide And gs._canCollide Then
			Local collisionDistance:Double = Self.GetSize() / 2 + gs.GetSize() / 2
			If Dist < collisionDistance Then
				CollideWith(gs, Dist, collisionDistance) 
			End If
		End If
		
	End Method

	Method ApplyGravityAndCollision() 
		' don't bother iterating if gravity and collisions have no effect to this object
		If Not _affectedByGravity And Not _canCollide Then Return
		
		' iterate through all objects in the active System
		For Local obj:TSpaceObject = EachIn TSystem.GetActiveSystem()._L_SpaceObjects
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
		If NOT obj._updated AND TMovingObject(obj) Then Return
		
		' check for projectile collision
		Local proj:TProjectile = TProjectile(Self) 
		Local proj2:TProjectile = TProjectile(obj) 
		If proj Or proj2 Then
			Local ship:TShip = TShip(obj) 
			' don't collide if the projectile was shot by the colliding ship
			If ship And proj And proj._shotBy = ship Then Return
			If ship And proj2 And proj2._shotBy = ship Then Return
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
		
		'If Self._name = "Player ship" Then
		'	G_debugWindow.AddText ("CollEnergy: " + collEnergy) 
		'End If
		If TStar(obj) Then collEnergy = 99999999
		If collEnergy > 150 Then SustainDamage(CollEnergy) 

		' damage to the other object...
		xVelAbsorb:Double = (optimisedP * (1 - elas) * Self.GetMass() * nX) 
		yVelAbsorb:Double = (optimisedP * (1 - elas) * Self.GetMass() * nY) 
		CollEnergy:Float = 0.5 * obj.GetMass() * xVelAbsorb ^ 2 * yVelAbsorb ^ 2 / 100000000
		'If obj._name = "Player ship" Then
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
	
	' Update the position of the moving object. jumpvalue is for jump engine "warp"
	Method UpdatePosition(jumpValue:Float = 1.0) 
		_x = _x + _xVel * G_delta.GetDelta() * jumpValue
		_y = _y + _yVel * G_delta.GetDelta() * jumpValue
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


Type TShip Extends TMovingObject
	Global g_L_Ships:TList					' a list to hold all ships
	Global g_nrShips:Int
	
	Field _hull:THull
	Field _forwardAcceleration:Float			' maximum forward acceleration (calculated by a routine)
	Field _reverseAcceleration:Float			' maximum reverse acceleration (calculated by a routine)
	Field _rotAcceleration:Float				' maximum rotation acceleration (calculated by a routine)
	Field _engineThrust:Float				' thrust (in newtons) given by the ship's main engines
	Field _reverseThrust:Float				' thrust (in newtons) given by the ship's reverse engines
	Field _rotThrust:Float					' thrust (in newtons) given by the ship's rotation thrusters
	Field _maxRotationSpd:Float				' maximum rotation speed (degrees per second)
	Field _rotKillPercentage:Float = 0.8		' the magnitude of the rotation damper. Values 0 to 1. 1 means max efficiency.
	Field _isSpeedLimited:Int = True			' a flag to indicate if speed limiter is functional
	Field _isRotationLimited:Int = True		' a flag to indicate if rotation limiter is functional
	Field _isLimiterOverrided:Int = False	' flag to indicate if speed and rotation limiters are overrided
	
	Field _throttlePosition:Float = 0		' -1 = full back, +1 = full forward
	Field _controllerPosition:Float = 0		' -1 = full left, +1 = full right

	Field _L_Engines:TList					' all ship's engines as TComponent
	
	Field _L_Weapons:TList					' list holding all weapons as TComponent
	Field _selectedWeaponSlot:TSlot			' the weapon slot currently selected as the active slot
	Field _selectedWeapon:TWeapon			' ... and the weapon itself in the active slot
	
	Field _lastShot:Int						' milliseconds since last shot
	Field _triggerDown:Int = False			' is weapon trigger down
	' todo: integrate weapon-related fields to TWeapon
	
	Field _isJumpDriveOn:Int = False
	Field _pilot:TPilot						' The pilot controlling this ship
	
	' not used... yet
	Field _fuel:Float						' on-board fuel for main engines (calculated by a routine)
	Field _oxygen:Float						' on-board oxygen
	
	Method Update() 
		' apply forward and reverse thrusts
		If _throttlePosition > 0 Then
			ApplyImpulse(_throttlePosition * _forwardAcceleration) 
			' add the engine trail effect
			If _L_Engines AND NOT _isJumpDriveOn Then EmitEngineTrail("tail")		
		EndIf
		
		If _throttlePosition < 0 Then
			ApplyImpulse(_throttlePosition * _reverseAcceleration) 
			' add the engine trail effect
			If _L_Engines AND NOT _isJumpDriveOn Then EmitEngineTrail("nose")		
		EndIf
		
		' firing
		If _triggerDown AND NOT _isJumpDriveOn Then FireWeapon() 
		
		' apply rotation thrusters
		ApplyRotation(_controllerPosition * _rotAcceleration)

		If _controllerPosition = 0 Then ApplyRotKill() 		' if the "joystick" is centered, fire the rotKill thrusters

		' call update method of TMovingObject
		Super.Update()
		
		If _isJumpDriveOn Then UpdatePosition(20)    
	EndMethod
	
	Method EmitEngineTrail(dir:String = "tail")
		Local direct:Int = 1	
		If dir = "nose" Then direct = -1
		For Local eng:TComponent = EachIn _L_Engines
			If eng.GetSlot().GetExposedDir() = dir Then
				Local part:TParticle = TParticle.Create(TImg.LoadImg("trail.png"),  ..
				_x + eng.GetSlot().GetYOffSet() * Cos(_rotation) + eng.GetSlot().GetXOffSet() * Sin(_rotation),  ..
				_y + eng.GetSlot().GetYOffSet() * Sin(_rotation) - eng.GetSlot().GetXOffSet() * Cos(_rotation),  ..
				0.1, 0.03, 0.5, _System) 
				Local randDir:Float = Rand(- 2, 2) 
				part._xVel = _xVel - 150*direct * Cos(_rotation + randDir) 
				part._yVel = _yVel - 150*direct * Sin(_rotation + randDir) 
				part._rotation = _rotation
				IF dir = "nose" Then part._rotation:+180											
			EndIf
		Next
	End Method
	
	
	Method FireWeapon() 
		If Not _selectedWeaponSlot Or Not _selectedWeapon Then Return
		
		If MilliSecs() - _lastShot < _selectedWeapon._ROF Then Return
		Local vel:Int = _selectedWeapon.GetVelocity() 
		Local TTL:Int = _selectedWeapon.GetRange() / vel
		
		Local shot:TProjectile = TProjectile.Create(TImg.LoadImg("shot.png"), _x, _y, TTL, 0.5, 1, _System) 
		
		Local xOff:Float = _selectedWeaponSlot.GetXOffSet() 
		Local yOff:Float = _selectedWeaponSlot.GetYOffSet() 
		
		shot._canCollide = True
		
	    shot._x = _x + yOff * Cos(_rotation) + xOff * Sin(_rotation) 
	    shot._y = _y + yOff * Sin(_rotation) - xOff * Cos(_rotation) 
		shot._rotation = _rotation
		
		shot._xVel = _xVel + vel * Cos(_rotation) 
		shot._yVel = _yVel + vel * Sin(_rotation) 
		shot.SetShooter(Self) 
		
		_lastShot = MilliSecs() 
	End Method

	' set the jump drive status		
	Method JumpDrive(isOn:Int)
		_isJumpDriveOn = isOn
		
		If _isJumpDriveOn Then
			SetThrottle(0)
			SetController(0)
			_triggerDown = False
		EndIf

	End Method
	
	Method GetRotAccel:Float()
		Return _rotAcceleration
	End Method
	
	Method SetThrottle(thr:Float)
		_throttlePosition = thr
	End Method

	Method SetController(cnt:Float)
		_controllerPosition = cnt
	End Method
	
	' apply acceleration to x and y velocity vectors
	Method ApplyImpulse(accel:Float) 
		Local Ximpulse:Float = accel * (Cos(_rotation)) 
		Local Yimpulse:Float = accel * (Sin(_rotation)) 

		_Xvel:+Ximpulse * G_delta.GetDelta() 
		_Yvel:+Yimpulse * G_delta.GetDelta()
	EndMethod
	
	Method ApplyRotation(rotAcceleration:Float)
		_rotationSpd:+rotAcceleration * G_delta.GetDelta() 
		If _isRotationLimited And Not _isLimiterOverrided Then ApplyRotationLimiter() 
	EndMethod

	Method ApplyRotationLimiter() 
		If _rotationSpd > _maxRotationSpd Then	' we're rotating too fast to the RIGHT...
			_rotationSpd:-_rotAcceleration * G_delta.GetDelta()  		' ... so slow down the rotation by firing the LEFT thruster
			' if the rotation speed is now _under_ the limit, set the rotation speed _to_ the limit
			If _rotationSpd < _maxRotationSpd Then _rotationSpd = _maxRotationSpd
		EndIf

		If _rotationSpd < -_maxRotationSpd Then	' we're rotating too fast to the LEFT
			_rotationSpd:+_rotAcceleration * G_delta.GetDelta() 		' ... so slow down the rotation by firing the RIGHT thruster
			' if the rotation speed is now _under_ the limit, set the rotation speed _to_ the limit
			If _rotationSpd > - _maxRotationSpd Then _rotationSpd = -_maxRotationSpd
		EndIf
	EndMethod
	
	' rotkill is a "rotation damper" that fires when the controller is centered
	Method ApplyRotKill() 
		If _rotationSpd = 0.0 Then Return
		If _rotationSpd < 0 Then _rotationSpd:+(_rotKillPercentage * _rotAcceleration * G_delta.GetDelta()) 
		If _rotationSpd > 0 Then _rotationSpd:-(_rotKillPercentage * _rotAcceleration * G_delta.GetDelta()) 
		If Abs(_rotationSpd) <= _rotAcceleration * G_delta.GetDelta() Then
			_rotationSpd = 0.0	' Halt the rotation altogether if rotation speed is less than one impulse of the thruster
		EndIf
	EndMethod
	
	' AutoPilotRotation figures how to fire the turn thrusters in order to rotate into desired orientation
	Method AutoPilotRotation(desiredRotation:Float) 
		Local diff:Float = GetAngleDiff(_rotation,desiredRotation)  ' returns degrees between current and desired rotation

		If Abs(diff) < 1 + _rotAcceleration / 2 Then		' if we're "close enough" to the desired rotation (take the rot thrust performance into account)...
			_controllerPosition = 0 						'... kill the rotation thrusters...
			Return  											' ... and return without turning
		EndIf
		
		' if diff < 0, the desired rotation is faster to reach by rotating to the right, diff > 0 vice versa
		If diff > 0 Then _controllerPosition = 1		' rotation thrusters full right
		If diff < 0 Then _controllerPosition = -1		' rotation thrusters full left
		
		' *********** calculates when to stop rotation ******************
		' Calculate the number of degrees it takes for the ship to stop rotating
		' The absolute value of rotational speed (degrees per second):
		Local rotSpd:Float = Abs(_RotationSpd) 
		' The number of seconds it takes for the rotation to stop: (time)
		Local secondsToStop:Int = Abs(rotSpd) / (_rotAcceleration) 
		' CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
		' s = vt + at^2
		Local degreesToStop:Float = CalcAccelerationDistance(rotSpd, secondsToStop, - _rotAcceleration) 
		' stop rotating if it takes more degrees to stop than the angle difference is
		If degreesToStop >= Abs(diff) Then
			If diff > 0 And _RotationSpd > 0 Then _controllerPosition = -1		' fire the opposing (left)  rotation thrusters
			If diff < 0 And _RotationSpd < 0 Then _controllerPosition = 1 		' fire the opposing (right) rotation thrusters
		EndIf
		' ***************************************************************
	EndMethod
	
	' Precalcphysics calculates ship's performance based on the on-board equipment
	Method PreCalcPhysics() 
		_mass = 0
		_engineThrust = 0
		_reverseThrust = 0
		_rotThrust = 0
		
		For Local slot:TSlot = EachIn _hull.GetSlotList() 
			If slot.GetComponentList() Then	' if this slot has components, iterate through all of them
				For Local component:TComponent = EachIn slot.GetComponentList() 
					If slot.isEngine() Then
						If component.getType() = "engine" Then
							Local prop:TPropulsion = TPropulsion(component.GetShipPart()) 
							If slot.GetExposedDir() = "tail" Then _engineThrust = _engineThrust + prop.GetThrust() 
							If slot.GetExposedDir() = "nose" Then _reverseThrust = _reverseThrust + prop.GetThrust() 
						EndIf
					EndIf
					If slot.isRotThruster() Then
						If component.getType() = "engine" Then
							Local prop:TPropulsion = TPropulsion(component.GetShipPart()) 
							_rotThrust = _rotThrust + prop.GetThrust() 
						EndIf
					EndIf
					If slot.isWeapon() Then
						If component.getType() = "weapon" Then AddWeapon(component, slot) 
					End If
					' add the mass of the component to the ship's total mass
					_mass = _mass + component.GetShipPartMass() 
				Next
			EndIf
		Next
		
		' add the hull mass to the ship's total mass
		_mass = _mass + _hull.GetMass()
	
		UpdatePerformance() 
	EndMethod

	Method UpdatePerformance() 
		_forwardAcceleration = (_engineThrust / _mass) 
		'_reverseAcceleration = ((_engineThrust * _hull.GetReverserRatio()) / _mass) 
		_reverseAcceleration = (_reverseThrust / _mass) 
		_rotAcceleration = (RadToDeg(CalcRotAcceleration(_rotThrust, _size, _mass, _hull.GetThrusterPos()))) 
		_maxRotationSpd = _hull.GetMaxRotationSpd() 
	End Method
	
	Method AddWeapon(comp:TComponent, slot:TSlot) 
		Local weap:TWeapon = TWeapon(comp.GetShipPart()) 
		If Not _L_Weapons Then _L_Weapons = CreateList() 
		_L_Weapons.AddLast(comp) 
		_SelectedWeapon = weap
		_SelectedWeaponSlot = slot
	End Method
	
	Method AssignPilot(p:TPilot)
		_pilot = p					' assign the given pilot as the pilot for this ship
		p.SetControlledShip(Self)	' assign this ship as the controlled ship for the given pilot
	End Method
	
	' AddComponentToSlotID installs a component into a ship's slot. The slot is given as ID string.
	Method AddComponentToSlotID:Int(comp:TComponent, slotID:String) 
		Local slot:TSlot = _hull.FindSlot(slotID) 
		If not slot Return Null
		Local result:Int = AddComponentToSlot(comp, slot) 
		Return result
	End Method

	' As opposed to AddComponentToSlotID, AddComponentToSlot takes the actual slot (not ID) as a parameter
	Method AddComponentToSlot:Int(comp:TComponent, slot:TSlot) 
		Local result:Int = _hull.AddComponent(comp, slot) 
		If TPropulsion(comp.GetShipPart()) Then
			If Not _L_Engines Then _L_Engines = CreateList() 
			_L_Engines.AddLast(comp) 
		EndIf
		 
		Self.PreCalcPhysics()  	' updates the ship performance after component installation
		Return result
	End Method
	
	' RemoveComponentFromSlot removes a component from a specified slot.
	Method RemoveComponentFromSlot:Int(comp:TComponent, slot:TSlot) 
		Local result:Int = _hull.RemoveComponent(comp, slot) 
		Self.PreCalcPhysics() 	' updates the ship performance after component removal
		Return result
	End Method
	
	Method SetSystem(sys:TSystem) 
		_System = sys
		sys.AddSpaceObject(self) 		' add the ship to the System's space objects list		
	End Method

	Method SetCoordinates(x:Int, y:Int) 
		_x = x
		_y = y
	End Method
	
	Method Destroy() 
		_pilot.Kill() 
		_pilot = Null
		
		_System.RemoveSpaceObject(self)
		g_L_Ships.Remove(Self) 
		g_nrShips:-1
	End Method
	
	Function UpdateAll() 
		If Not g_L_Ships Then Return
		For Local o:TShip = EachIn g_L_Ships
			o.Update()
		Next
	EndFunction


	Function Create:TShip(hullID:String, name:String = "Nameless") 

		Local sh:TShip = New TShip		' create an instance of the ship

		' create the hull and copy a few hull fields to corresponding ship fields
		sh._hull = THull.Create(hullID)
		sh._image = sh._hull._image
		sh._size = sh._hull._size
		sh._scaleX = sh._hull._scale
		sh._scaleY = sh._hull._scale
		sh._name = name					' give a name
		sh._isShownOnMap = True
		sh._canCollide = True
		sh._integrity = sh._hull.GetMass() 
		
		If Not g_L_Ships Then g_L_Ships = CreateList() 
		g_L_Ships.AddLast sh
		g_nrShips:+1
		
		Return sh											' return the pointer to this specific object instance
	EndFunction

EndType

Type TAsteroid Extends TMovingObject
	Global g_L_Asteroids:TList
	Global g_nrAsteroids:Int
	
	Method Destroy() 
		' remove the asteroid from all lists so that GC can delete the object
		g_L_Asteroids.Remove(Self) 
		Self._System.RemoveSpaceObject(Self) 
		g_L_MovingObjects.Remove(Self) 
		g_nrAsteroids:-1
	End Method
	
	' destructor, called automatically by GC
	Method Delete() 
		DebugLog "Asteroid deleted by GC"
	End Method
	
	Function Create:TAsteroid(img:String, System:TSystem, x:Float, y:Float, mass:Long) 
		Local a:TAsteroid = New TAsteroid
		a._image = TImg.LoadImg(img) 
		a._mass = mass
		a._System = System
		a._x = x
		a._y = y
		a._isShownOnMap = True
		a._canCollide = True
		a._affectedByGravity = True
		a._integrity = mass
		
		If Not g_L_Asteroids Then g_L_Asteroids = CreateList() 
		g_L_Asteroids.AddLast(a) 
		g_nrAsteroids:+1
		
		If Not g_L_MovingObjects Then g_L_MovingObjects = CreateList() 
		g_L_MovingObjects.AddLast(a) 
		
		System.AddSpaceObject(a) 
		
		Return a
	End Function
EndType


' types directly related to TSpaceObjects
Include "i_TAttachment.bmx"
Include "i_TParticle.bmx"