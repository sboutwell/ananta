Rem
	Naming convention:
	-	All types are named with a T in front (example: TTypeName)
	-	All lists and fields that are global inside a type must begin with g (example: Global g_variableName)
		Note a lower case g as opposed to the capital G for program globals.
	-	All lists are named with L in front of them (example L_ListName)
	
	You can capitalize fields, types and lists as needed for good readability. Use your own judgement.
	
	Thoroughly comment all type definitions, explain their usage and their methods and fields.
	
	Have fun.
EndRem


Rem
	*************************************************************************************************
	***************************************** SPACEOBJECTS ******************************************
	*************************************************************************************************
	Description: All drawable objects that can exist in a star sector

	TSpaceObject
		TJumpPoint
		TStellarObject
			TStar
			TPlanet
			TSpaceStation
		TMovingObject
			TShip
			TAsteroid
			TProjectile
			 
EndRem

Type TSpaceObject Abstract
	Field _image:TImage					' The image to represent the object
	Field _x:Float,_y:Float				' x-y coordinates of the object
	Field _sector:TSector				' the sector the object is in
	Field _rotation:Float				' rotation in degrees
	Field _mass:Long						' The mass of the object in kg
	Field _size:Int						' The visual diameter of the object, to display the object in correct scale in the minimap
	Field _scaleX:Float = 1				' The scale of the drawn image (1 being full resolution, 2 = double size, 0.5 = half size)
	Field _scaleY:Float = 1				
	Field _name:String	= "Nameless"	' The name of the object
	
	Method DrawBody(vp:TViewport)
		If _image Then 
			' ********* preload values that are used more than once (-->_veeery_ slight performance boost)
			Local startX:Int = vp.GetStartX()
			Local startY:Int = vp.GetStartY()
			Local midX:Int = vp.GetMidX()
			Local midY:Int = vp.GetMidY()
			' *********

			SetViewport(startX, startY, vp.GetWidth(), vp.GetHeight())
			SetAlpha 1
			SetRotation _rotation+90
			SetBlend MASKBLEND
			SetColor 255,255,255
			SetScale _scaleX, _scaleY
			DrawImage _image, (vp.GetCameraPosition_X()- _x) + midX + startX, (vp.GetCameraPosition_Y()- _y) + midY + startY
		EndIf
	EndMethod
	
	Method GetMass:Float() 
		Return _mass
	End Method
	
	Method GetRot:Float()
		Return _rotation
	End Method

	Method GetSize:Int()
		Return _size
	End Method
	
	Method GetX:Float()
		Return _x
	End Method
	
	Method GetY:Float()
		Return _y
	End Method

	Method SetX(coord:Float)
		_x = coord
	End Method
	
	Method SetY(coord:Float)
		_y = coord
	End Method
	
EndType

Type TJumpPoint Extends TSpaceObject
	Global g_L_JumpPoints:TList		' a list to hold all JumpPoints
	Field _destinationJp:TJumpPoint	' the connected JumpPoint
	
	Function Create:TJumpPoint(x:Int,y:Int,sector:TSector,destination:TJumpPoint)
		Local jp:TJumpPoint = New TJumpPoint		' create an instance
		jp._x = x; jp._y = y						' coordinates
		jp._sector = sector									' the sector
		jp._destinationJp = destination					' the destination JumpPoint

		If Not g_L_JumpPoints Then g_L_JumpPoints = CreateList()	' create a list if necessary
		g_L_JumpPoints.AddLast jp											' add the newly created object to the end of the list

		sector.AddSpaceObject(jp)		' add the jumppoint to the sector's space object list

		Return jp																		' return the pointer to this specific object instance
	EndFunction
EndType


' *** STATIONARY STELLAR OBJECTS
Type TStellarObject Extends TSpaceObject Abstract
	Global g_L_StellarObjects:TList			' a list to hold all major stellar bodies (Stars, planets and space stations)
	Field _hasGravity:Int	= False			' a true-false flag to indicate gravitational pull
EndType

Type TStar Extends TStellarObject
	Function Create:TStar(x:Int=0,y:Int=0,sector:TSector,mass:Long,size:Int,name:String)
		Local st:TStar = New Tstar				' create an instance
		st._name = name								' give a name
		st._x = x; st._y = y							' coordinates
		st._sector = sector							' the sector
		st._mass = mass								' mass in kg
		st._size = size								' size in pixels

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

		sector.AddSpaceObject(st)		' add the body to sector's space objects list
		
		Return st																' Return the pointer To this specific Object instance
	EndFunction
EndType

Type TPlanet Extends TStellarObject
	Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
		Local pl:TPlanet = New TPlanet					' create an instance
		pl._name = name										' give a name
		pl._x = x; pl._y = y									' coordinates
		pl._sector = sector									' the sector
		pl._mass = mass										' mass in kg
		pl._size = size										' size in pixels

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast pl											' add the newly created object to the end of the list
		
		sector.AddSpaceObject(pl)		' add the body to sector's space objects list
		
		Return pl																' return the pointer to this specific object instance
	EndFunction
EndType

Type TSpaceStation Extends TStellarObject
	Function Create:TSpaceStation(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
		Local ss:TSpaceStation = New TSpaceStation	' create an instance
		ss._name = name										' give a name
		ss._x = x; ss._y = y									' coordinates
		ss._sector = sector									' the sector
		ss._mass = mass										' mass in kg
		ss._size = size										' size in pixels
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast ss												' add the newly created object to the end of the list
		
		sector.AddSpaceObject(ss)		' add the body to sector's space objects list
		
		Return ss																			' return the pointer to this specific object instance
	EndFunction
EndType


' *** MOVING SPACE OBJECTS
Type TMovingObject Extends TSpaceObject Abstract
	Global g_L_MovingObjects:TList			' a list to hold all moving objects
	Field _xVel:Float								' velocity vector x-component
	Field _yVel:Float								' velocity vector y-component
	Field _rotationSpd:Float					' rotation speed

	Method GetRotSpd:Float()
		Return _rotationSpd
	End Method

	Method Update()
		' rotate the object
		_rotation :+ _rotationSpd
		If _rotation < 0 _rotation:+360
		If _rotation>=360 _rotation:-360
			
		' update the position
		_x = _x + _xVel
		_y = _y + _yVel
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

	Field _hull:THull
	Field _forwardAcceleration:Float			' maximum forward acceleration (calculated by a routine)
	Field _reverseAcceleration:Float			' maximum reverse acceleration (calculated by a routine)
	Field _rotAcceleration:Float				' maximum rotation acceleration (calculated by a routine)
	Field _engineThrust:Float				' thrust (in newtons) given by the ship's engines
	Field _rotThrust:Float					' thrust (in newtons) given by the ship's rotation thrusters
	Field _maxRotationSpd:Float				' maximum rotation speed (degrees per frame)
	Field _rotKillPercentage:Float = 0.8		' the magnitude of the rotation damper. Values 0 to 1. 1 means max efficiency.
	Field _isSpeedLimited:Int = True			' a flag to indicate if speed limiter is functional
	Field _isRotationLimited:Int = True		' a flag to indicate if rotation limiter is functional
	Field _isLimiterOverrided:Int = False	' flag to indicate if speed and rotation limiters are overrided

	Field _throttlePosition:Float = 0		' -1 = full back, +1 = full forward
	Field _controllerPosition:Float = 0		' -1 = full left, +1 = full right

	Field _fuel:Float						' on-board fuel for main engines (calculated by a routine)
	Field _oxygen:Float						' on-board oxygen
	Field _pilot:TPilot						' The pilot controlling this ship
	
	Method Update()
		' apply forward and reverse thrusts
		If _throttlePosition > 0 Then ApplyImpulse(_throttlePosition * _forwardAcceleration)
		If _throttlePosition < 0 Then ApplyImpulse(_throttlePosition * _reverseAcceleration)
		
		' apply rotation thrusters
		ApplyRotation(_controllerPosition * _rotAcceleration)

		If _controllerPosition = 0 Then ApplyRotKill()		' if the "joystick" is centered, fire the rotKill thrusters

		super.Update()  ' call update method of TMovingObject
	EndMethod

	Method GetRotAccel:Float()
		Return _rotAcceleration
	End Method
	
	Method SetThrottle(thr:Float)
		_throttlePosition = thr
	End Method

	Method SetController(cnt:Float)
		_controllerPosition = cnt
	End Method
	
	Method ApplyImpulse(Thrust:Float)
		Local Ximpulse:Float = Thrust*(Cos(_rotation))
		Local Yimpulse:Float = Thrust*(Sin(_rotation))

		_Xvel :+ Ximpulse
		_Yvel :+ Yimpulse
	EndMethod
	
	Method ApplyRotation(rotAcceleration:Float)
		_rotationSpd:+rotAcceleration
		If _isRotationLimited And Not _isLimiterOverrided Then ApplyRotationLimiter()
	EndMethod

	Method ApplyRotationLimiter()
		If _rotationSpd > _maxRotationSpd Then	' we're rotating too fast to the RIGHT...
			_rotationSpd :- _rotAcceleration		' ... so slow down the rotation by firing the LEFT thruster
			If _rotationSpd < _maxRotationSpd Then _rotationSpd = _maxRotationSpd
		EndIf

		If _rotationSpd < -_maxRotationSpd Then	' we're rotating too fast to the LEFT
			_rotationSpd :+ _rotAcceleration		' ... so slow down the rotation by firing the RIGHT thruster
			If _rotationSpd > _maxRotationSpd Then _rotationSpd = -_maxRotationSpd
		EndIf
	EndMethod
	
	Method ApplyRotKill()
		If _rotationSpd = 0.0 Then Return
		If _rotationSpd < 0 Then _rotationSpd :+ (_rotKillPercentage * _rotAcceleration)
		If _rotationSpd > 0 Then _rotationSpd :- (_rotKillPercentage * _rotAcceleration)
		If Abs(_rotationSpd) <= _rotAcceleration Then 
			_rotationSpd = 0.0	' Halt the rotation altogether if rotation speed is less than one impulse of the thruster
		EndIf
	EndMethod
	
	' AutoPilotRotation figures how to fire the turn thrusters in order to rotate into desired orientation
	Method AutoPilotRotation(desiredRotation:Float) 
		Local diff:Float = GetAngleDiff(_rotation,desiredRotation)  ' returns degrees between current and desired rotation

		If Abs(diff) < 1 + _rotAcceleration/2 Then		' if we're "close enough" to the desired rotation (take the rot thrust performance into account)...
			_controllerPosition = 0 						'... kill the rotation thrusters...
			Return  											' ... and return without turning
		EndIf
		
		' if diff < 0, the desired rotation is faster to reach by rotating to the right, diff > 0 vice versa
		If diff > 0 Then _controllerPosition = 1		' rotation thrusters full right
		If diff < 0 Then _controllerPosition = -1		' rotation thrusters full left
		
		' *********** calculates when to stop rotation ******************
		' Calculate the number of degrees it takes for the ship to stop rotating
		' The absolute value of rotational speed (degrees per frame):
		Local rotSpd:Float = Abs(_RotationSpd)
		' The number of frames it takes for the rotation to stop: (time)
		Local framesToStop:Int 	 = Abs(rotSpd) / (_rotAcceleration)
		' CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
		' s = vt + at^2
		Local degreesToStop:Float = CalcAccelerationDistance(rotSpd, framesToStop, -_rotAcceleration)
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
		_rotThrust = 0
		
		For Local slot:TSlot = EachIn _hull.GetSlotList() 
			If slot.GetComponentList() Then	' if this slot has components, iterate through all of them
				For Local component:TComponent = EachIn slot.GetComponentList() 
					If slot.isEngine() Then _engineThrust = _engineThrust + component.GetThrust() 
					If slot.isRotThruster() Then _rotThrust = _rotThrust + component.GetThrust() 
					' add the mass of the component to the ship's total mass
					_mass = _mass + component.GetShipPartMass() 
				Next
			EndIf
		Next
		
		' add the hull mass to the ship's total mass
		_mass = _mass + _hull.GetMass()
	
		_forwardAcceleration = ( _engineThrust/_mass ) / TViewport.g_frameRate
		_reverseAcceleration = ( (_engineThrust*_hull.GetReverserRatio())/_mass ) / TViewport.g_frameRate
		_rotAcceleration = ( RadToDeg( CalcRotAcceleration(_rotThrust,_size,_mass,_hull.GetThrusterPos()) ) ) / TViewport.g_frameRate
		_maxRotationSpd = _hull.GetMaxRotationSpd() / TViewport.g_FrameRate
	EndMethod

	Method AssignPilot(p:TPilot)
		_pilot = p					' assign the given pilot as the pilot for this ship
		p.SetControlledShip(Self)	' assign this ship as the controlled ship for the given pilot
	End Method
	
	' AddComponentToSlotID installs a component into a ship's slot. The slot is given as ID string.
	Method AddComponentToSlotID:Int(comp:TComponent, slotID:String) 
		Local slot:TSlot = _hull.FindSlot(slotID) 
		If not slot Return Null
		Local result:Int = AddComponentToSlot(comp, slot) 
		Self.PreCalcPhysics() 	' updates the ship performance after component installation
		Return result
	End Method

	' As opposed to AddComponentToSlotID, AddComponentToSlot takes the actual slot (not ID) as a parameter
	Method AddComponentToSlot:Int(comp:TComponent, slot:TSlot) 
		Local result:Int = _hull.AddComponent(comp, slot) 
		Return result
	End Method
	
	' RemoveComponentFromSlot removes a component from a specified slot.
	Method RemoveComponentFromSlot:Int(comp:TComponent, slot:TSlot) 
		Local result:Int = _hull.RemoveComponent(comp, slot) 
		Self.PreCalcPhysics() 	' updates the ship performance after component removal
		Return result
	End Method
	
	Method SetSector(sect:TSector) 
		_sector = sect
		sect.AddSpaceObject(self) 		' add the ship to the sector's space objects list		
	End Method

	Method SetCoordinates(x:Int, y:Int) 
		_x = x
		_y = y
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
		
		If Not g_L_Ships Then g_L_Ships = CreateList() 
		g_L_Ships.AddLast sh
		
		Return sh											' return the pointer to this specific object instance
	EndFunction

EndType

Type TAsteroid Extends TMovingObject

EndType

Type TProjectile Extends TMovingObject

EndType
