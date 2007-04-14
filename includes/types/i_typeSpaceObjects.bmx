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
	Field image:TImage					' The image to represent the object
	Field x:Float,y:Float				' x-y coordinates of the object
	Field sector:TSector				' the sector the object is in
	Field rotation:Float				' rotation in degrees
	Field mass:Long						' The mass of the object in kg
	Field size:Int						' The visual diameter of the object, to display the object in correct scale in the minimap
	Field scaleX:Float = 1				' The scale of the drawn image (1 being full resolution, 2 = double size, 0.5 = half size)
	Field scaleY:Float = 1				
	Field name:String	= "Nameless"	' The name of the object
	Method DrawBody(viewport:TViewport)
		SetViewport(viewport.startX ,viewport.startY, viewport.width, viewport.height)
		If image Then 
			SetAlpha 1
			SetRotation rotation+90
			SetBlend MASKBLEND
			SetColor 255,255,255
			SetScale scaleX, scaleY
			DrawImage image, (viewport.cameraPosition_X-x) + viewport.midX + viewport.startX, (viewport.cameraPosition_Y-y) + viewport.midY + viewport.startY
		Else
			SetHandle( size/2,size/2 )
			SetRotation rotation+90
			SetBlend SOLIDBLEND
			SetColor 155,255,155
			DrawOval( (viewport.cameraPosition_X-x) + viewport.midX + viewport.startX, (viewport.cameraPosition_Y-y) + viewport.midY + viewport.startY, size, size)
			'SetColor 255,255,155
			'DrawLine(  (viewport.cameraPosition_X-x) + viewport.midX + viewport.startX, (viewport.cameraPosition_Y-y) + viewport.midY + viewport.startY,  (viewport.cameraPosition_X-x) + viewport.midX + viewport.startX, (viewport.cameraPosition_Y-y) + viewport.midY + viewport.startY + size)
			SetHandle (0,0)
			SetColor 255,255,155
		EndIf
	EndMethod
	
EndType

Type TJumpPoint Extends TSpaceObject
	Global g_L_JumpPoints:TList		' a list to hold all JumpPoints
	Field destinationJp:TJumpPoint	' the connected JumpPoint
	
	Function Create:TJumpPoint(x:Int,y:Int,sector:TSector,destination:TJumpPoint)
		Local jp:TJumpPoint = New TJumpPoint		' create an instance
		jp.x = x; jp.y = y									' coordinates
		jp.sector = sector									' the sector
		jp.destinationJp = destination					' the destination JumpPoint

		If Not g_L_JumpPoints Then g_L_JumpPoints = CreateList()	' create a list if necessary
		g_L_JumpPoints.AddLast jp											' add the newly created object to the end of the list

		If Not sector.L_SpaceObjects Then sector.L_SpaceObjects = CreateList()	' create a bodies-list for the SECTOR
		sector.L_SpaceObjects.AddLast jp											' put this object inside the SECTOR

		Return jp																		' return the pointer to this specific object instance
	EndFunction
EndType


' *** STATIONARY STELLAR OBJECTS
Type TStellarObject Extends TSpaceObject Abstract
	Global g_L_StellarObjects:TList			' a list to hold all major stellar bodies (Stars, planets and space stations)
	Field hasGravity:Int	= False			' a true-false flag to indicate gravitational pull
EndType

Type TStar Extends TStellarObject
	Function Create:TStar(x:Int=0,y:Int=0,sector:TSector,mass:Long,size:Int,name:String)
		Local st:TStar = New Tstar				' create an instance
		st.name = name								' give a name
		st.x = x; st.y = y							' coordinates
		st.sector = sector							' the sector
		st.mass = mass								' mass in kg
		st.size = size								' size in pixels

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list
		
		If Not sector.L_SpaceObjects Then sector.L_SpaceObjects = CreateList()	' create a bodies-list for the SECTOR
		sector.L_SpaceObjects.AddLast st									' put this Object inside the SECTOR
		
		Return st																' Return the pointer To this specific Object instance
	EndFunction
EndType

Type TPlanet Extends TStellarObject
	Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
		Local pl:TPlanet = New TPlanet					' create an instance
		pl.name = name										' give a name
		pl.x = x; pl.y = y									' coordinates
		pl.sector = sector									' the sector
		pl.mass = mass										' mass in kg
		pl.size = size										' size in pixels

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast pl											' add the newly created object to the end of the list
		
		If Not sector.L_SpaceObjects Then sector.L_SpaceObjects = CreateList()	' create a bodies-list for the SECTOR
		sector.L_SpaceObjects.AddLast pl										' put this object inside the SECTOR
		
		Return pl																' return the pointer to this specific object instance
	EndFunction
EndType

Type TSpaceStation Extends TStellarObject
	Function Create:TSpaceStation(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
		Local ss:TSpaceStation = New TSpaceStation	' create an instance
		ss.name = name										' give a name
		ss.x = x; ss.y = y									' coordinates
		ss.sector = sector									' the sector
		ss.mass = mass										' mass in kg
		ss.size = size										' size in pixels
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast ss												' add the newly created object to the end of the list
		
		If Not sector.L_SpaceObjects Then sector.L_SpaceObjects = CreateList()	' create a bodies-list for the SECTOR
		sector.L_SpaceObjects.AddLast ss												' put this object inside the SECTOR
		
		Return ss																			' return the pointer to this specific object instance
	EndFunction
EndType


' *** MOVING SPACE OBJECTS
Type TMovingObject Extends TSpaceObject Abstract
	Global g_L_MovingObjects:TList			' a list to hold all moving objects
	Field xVel:Float								' velocity vector x-component
	Field yVel:Float								' velocity vector y-component
	Field rotationSpd:Float					' rotation speed

	Method Update()
		' rotate the object
		rotation :+ rotationSpd
		If rotation<0 rotation:+360
		If rotation>=360 rotation:-360
			
		' update the position
		x = x + xVel
		y = y + yVel
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

	Field hull:THull
	Field forwardAcceleration:Float			' maximum forward acceleration (calculated by a routine)
	Field reverseAcceleration:Float			' maximum reverse acceleration (calculated by a routine)
	Field rotAcceleration:Float				' maximum rotation acceleration (calculated by a routine)
	Field engineThrust:Float				' thrust (in newtons) given by the ship's engines
	Field rotThrust:Float					' thrust (in newtons) given by the ship's rotation thrusters
	Field maxRotationSpd:Float				' maximum rotation speed (degrees per frame)
	Field rotKillPercentage:Float = 0.8		' the magnitude of the rotation damper. Values 0 to 1. 1 means max efficiency.
	Field isSpeedLimited:Int = True			' a flag to indicate if speed limiter is functional
	Field isRotationLimited:Int = True		' a flag to indicate if rotation limiter is functional
	Field isLimiterOverrided:Int = False	' flag to indicate if speed and rotation limiters are overrided

	Field throttlePosition:Float = 0		' -1 = full back, +1 = full forward
	Field controllerPosition:Float = 0		' -1 = full left, +1 = full right

	Field fuel:Float						' on-board fuel for main engines (calculated by a routine)
	Field oxygen:Float						' on-board oxygen
	Field pilot:TPilot						' The pilot controlling this ship
	
	Method Update()
		' apply forward and reverse thrusts
		If throttlePosition > 0 Then ApplyImpulse(throttlePosition * forwardAcceleration)
		If throttlePosition < 0 Then ApplyImpulse(throttlePosition * reverseAcceleration)
		
		' apply rotation thrusters
		ApplyRotation(controllerPosition * rotAcceleration)

		If controllerPosition = 0 Then ApplyRotKill()		' if the "joystick" is centered, fire the rotKill thrusters

		super.Update()  ' call update method of TMovingObject
	EndMethod

	Method ApplyThrottle(thr:Float)
		throttlePosition = thr
	End Method

	Method ApplyController(cnt:Float)
		controllerPosition = cnt
	End Method
	
	Method ApplyImpulse(Thrust:Float)
		Local Ximpulse:Float = Thrust*(Cos(rotation))
		Local Yimpulse:Float = Thrust*(Sin(rotation))

		Xvel :+ Ximpulse
		Yvel :+ Yimpulse
	EndMethod
	
	Method ApplyRotation(rotAcceleration:Float)
		rotationSpd:+rotAcceleration
		If isRotationLimited And Not isLimiterOverrided Then ApplyRotationLimiter()
	EndMethod

	Method ApplyRotationLimiter()
		If rotationSpd > maxRotationSpd Then	' we're rotating too fast to the RIGHT...
			rotationSpd :- rotAcceleration		' ... so slow down the rotation by firing the LEFT thruster
			If rotationSpd < maxRotationSpd Then rotationSpd = maxRotationSpd
		EndIf

		If rotationSpd < -maxRotationSpd Then	' we're rotating too fast to the LEFT
			rotationSpd :+ rotAcceleration		' ... so slow down the rotation by firing the RIGHT thruster
			If rotationSpd > maxRotationSpd Then rotationSpd = -maxRotationSpd
		EndIf
	EndMethod
	
	Method ApplyRotKill()
		If rotationSpd < 0 Then	rotationSpd :+ (rotKillPercentage * rotAcceleration)
		If rotationSpd > 0 Then	rotationSpd :- (rotKillPercentage * rotAcceleration)
		If Abs(rotationSpd) <= rotAcceleration Then rotationSpd = 0.0	' Halt the rotation altogether if rotation speed is less than one impulse of the thruster
	EndMethod
	
	' AutoPilotRotation figures how to fire the turn thrusters in order to rotate into desired orientation
	Method AutoPilotRotation(desiredRotation:Float) 
		Local diff:Float = GetAngleDiff(rotation,desiredRotation)  ' returns degrees between current and desired rotation

		If Abs(diff) < 1 + rotAcceleration/2 Then		' if we're "close enough" to the desired rotation (take the rot thrust performance into account)...
			controllerPosition = 0 						'... kill the rotation thrusters...
			Return  											' ... and return without turning
		EndIf
		
		' if diff < 0, the desired rotation is faster to reach by rotating to the right, diff > 0 vice versa
		If diff > 0 Then controllerPosition = 1		' rotation thrusters full right
		If diff < 0 Then controllerPosition = -1		' rotation thrusters full left
		
		' *********** calculates when to stop rotation ******************
		' Calculate the number of degrees it takes for the ship to stop rotating
		' The absolute value of rotational speed (degrees per frame):
		Local rotSpd:Float = Abs(RotationSpd)
		' The number of frames it takes for the rotation to stop: (time)
		Local framesToStop:Int 	 = Abs(rotSpd) / (rotAcceleration)
		' CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
		' s = vt + at^2
		Local degreesToStop:Float = CalcAccelerationDistance(rotSpd, framesToStop, -rotAcceleration)
		' stop rotating if it takes more degrees to stop than the angle difference is
		If degreesToStop >= Abs(diff) Then
			If diff > 0 And RotationSpd > 0 Then controllerPosition = -1		' fire the opposing (left)  rotation thrusters
			If diff < 0 And RotationSpd < 0 Then controllerPosition = 1 		' fire the opposing (right) rotation thrusters
		EndIf
		' ***************************************************************
	EndMethod
	
	' Precalcphysics calculates ship's mass and performance based on the on-board equipment
	Method PreCalcPhysics()
		For Local eSlot:TSlot = EachIn hull.L_engineSlots
			For Local component:TComponent= EachIn eSlot.L_parts
				'engineThrust = engineThrust + component.ShipPart.thrust
				mass = mass + component.ShipPart.mass
			Next
		Next
	
		mass = mass + hull.mass
	
		forwardAcceleration = ( engineThrust/mass ) / TViewport.g_frameRate
		reverseAcceleration = ( (engineThrust*hull.reverserRatio)/mass ) / TViewport.g_frameRate
		rotAcceleration = ( RadToDeg( CalcRotAcceleration(rotThrust,size,mass,hull.thrusterPos) ) ) / TViewport.g_frameRate
		maxRotationSpd = hull.maxRotationSpd / TViewport.g_FrameRate
	EndMethod

	Method AssignPilot(p:TPilot)
		pilot = p				' assign the given pilot as the pilot for this ship
		p.controlledShip = Self	' assign this ship as the controlled ship for the given pilot
	End Method

	Function UpdateAll()
		If Not g_L_Ships Then Return
		For Local o:TShip = EachIn g_L_Ships
			o.Update()
		Next
	EndFunction


	Function Create:TShip(x:Int,y:Int,hullID:String,sector:TSector,name:String)

		Local sh:TShip = New TShip		' create an instance of the ship

		' create the hull and copy a few hull fields to corresponding ship fields
		sh.hull = THull.Create(hullID)
		sh.image = sh.hull.image
		sh.size = sh.hull.size
		sh.scaleX = sh.hull.scale
		sh.scaleY = sh.hull.scale
		
		sh.name = name					' give a name
		sh.x = x; sh.y = y				' coordinates
		sh.sector = sector				' the sector
		
		If Not g_L_Ships Then g_L_Ships = CreateList()
		g_L_Ships.AddLast sh
		
		If Not sector.L_SpaceObjects Then sector.L_SpaceObjects = CreateList()	' create a bodies-list for the SECTOR if necessary
		sector.L_SpaceObjects.AddLast sh					' put this object inside the SECTOR
		
		Return sh											' return the pointer to this specific object instance
	EndFunction

EndType

Type TAsteroid Extends TMovingObject

EndType

Type TProjectile Extends TMovingObject

EndType
