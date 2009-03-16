
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
	Field isTriggerDown:Int = False			' is weapon trigger down
	' todo: integrate weapon-related fields to TWeapon
	
	Field isWarpDriveOn:Int = False
	Field _warpRatio:Double = 10:Double			' base warp ratio for warp travel 	
	Field _maxWarpRatio:Double = 5000:Double	' max warp ratio for warp travel 	
	
	Field _pilot:TPilot						' The pilot controlling this ship
	
	' not used... yet
	Field _fuel:Float						' on-board fuel for main engines (calculated by a routine)
	Field _oxygen:Float						' on-board oxygen
	
	Method GetRotAccel:Float()
		Return _rotAcceleration
	End Method
	
	Method GetWarpRatio:Double()
		Return _warpRatio
	End Method
	
	Method GetForwardAcceleration:Float()
		Return _forwardAcceleration
	End Method
	
	Method GetReverseAcceleration:Float()
		Return _reverseAcceleration
	End Method
	
	Method GetPilot:TPilot()
		Return _pilot
	End Method
	
	Method SetThrottle(thr:Float)
		_throttlePosition = thr
	End Method

	Method SetController(cnt:Float)
		_controllerPosition = cnt
	End Method
	
	Method SetSystem(sys:TSystem) 
		_System = sys
		sys.AddSpaceObject(Self) 		' add the ship to the System's space objects list		
	End Method

	Method SetCoordinates(x:Int, y:Int) 
		_x = x
		_y = y
	End Method
	
	Method Update() 
		' apply forward and reverse thrusts
		If _throttlePosition > 0 Then
			ApplyImpulse(_throttlePosition * _forwardAcceleration) 
			' add the engine trail effect
			If _L_Engines And Not isWarpDriveOn Then EmitEngineTrail("tail")		
		EndIf
		
		If _throttlePosition < 0 Then
			ApplyImpulse(_throttlePosition * _reverseAcceleration) 
			' add the engine trail effect
			If _L_Engines And Not isWarpDriveOn Then EmitEngineTrail("nose")		
		EndIf
		
		' firing
		If isTriggerDown And Not isWarpDriveOn Then FireWeapon() 
		
		' apply rotation thrusters
		ApplyRotation(_controllerPosition * _rotAcceleration)

		If _controllerPosition = 0 Then ApplyRotKill() 		' if the "joystick" is centered, fire the rotKill thrusters

		' call update method of TMovingObject
		Super.Update()
		
		If isWarpDriveOn Then UpdatePosition(CalcWarpValue())  
		If Self._pilot = G_player Then G_DebugWindow.AddText("Max warp ratio: " + CalcWarpValue())
	EndMethod
	
	Method CalcWarpValue:Double()
		Local gravityCoeff:Double = (_strongestGravity:Double^(1.0:Double/4.0:Double)^2.0:Double)
		If gravityCoeff < 0.00000000000000001:Double Then Return _maxWarpRatio
		Local ratio:Double = _warpRatio:Double / gravityCoeff:Double
		If ratio > _maxWarpRatio Then Return _maxWarpRatio
		Return ratio
	End Method
	
	Method CalcStopDistance:Double(useReverse:Int = False)
		Local stopTime:Double
		Local acceleration:Float
		If useReverse Then 
			acceleration = GetReverseAcceleration()
		Else
			acceleration = GetForwardAcceleration() 
		EndIf
		IF acceleration = 0 Then Return -1 ' can never stop with zero acceleration
		
		stopTime = GetVel() / acceleration
		G_DebugWindow.AddText("decel: " + acceleration)
		G_DebugWindow.AddText("stop time: " + stopTime)
		G_DebugWindow.AddText("stop dist: " + CalcAccelerationDistance(GetVel(),stopTime,acceleration)/2)
		
		Return CalcAccelerationDistance(GetVel(),stopTime,acceleration)/2
	End Method

	
	Method EmitEngineTrail(dir:String = "tail")
		Local direct:Int = 1	
		If dir = "nose" Then direct = -1
		For Local eng:TComponent = EachIn _L_Engines
			If eng.GetSlot().GetExposedDir() = dir Then
				Local part:TParticle = TParticle.Create(TImg.LoadImg("trail.png"),  ..
				_x + eng.GetSlot().GetYOffSet() * Cos(_rotation) + eng.GetSlot().GetXOffSet() * Sin(_rotation),  ..
				_y + eng.GetSlot().GetYOffSet() * Sin(_rotation) - eng.GetSlot().GetXOffSet() * Cos(_rotation),  ..
				0.1, 0.03, 0.5, _System) 
				Local randDir:Float = Rnd(- 2.0, 2.0) 
				part._xVel = _xVel - 150*direct * Cos(_rotation + randDir) * Abs(_throttlePosition)
				part._yVel = _yVel - 150*direct * Sin(_rotation + randDir) * Abs(_throttlePosition)
				part._rotation = _rotation
				If dir = "nose" Then part._rotation:+180											
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
		
		shot.canCollide = True
		
	    shot._x = _x + yOff * Cos(_rotation) + xOff * Sin(_rotation) 
	    shot._y = _y + yOff * Sin(_rotation) - xOff * Cos(_rotation) 
		shot._rotation = _rotation
		
		shot._xVel = _xVel + vel * Cos(_rotation) 
		shot._yVel = _yVel + vel * Sin(_rotation) 
		shot.SetShooter(Self) 
		
		_lastShot = MilliSecs() 
	End Method

	' set the warp drive status		
	Method SetWarpDrive(isOn:Int)
		isWarpDriveOn = isOn
		
		If isWarpDriveOn Then
			SetThrottle(0)
			SetController(0)
			isTriggerDown = False
		EndIf

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
	' Do not call in the main loop.
	Method PreCalcPhysics() 
		_mass = 0
		_engineThrust = 0
		_reverseThrust = 0
		_rotThrust = 0
		
		For Local slot:TSlot = EachIn _hull.GetSlotList() ' iterate through all equipment slots
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
		If Not slot Return Null
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
	
	Method Destroy() 
		If _pilot Then _pilot.Kill() 
		_pilot = Null
		
		If _System Then _System.RemoveSpaceObject(Self)
		g_L_Ships.Remove(Self) 
		g_nrShips:-1
	End Method
	
	Function UpdateAll() 
		If Not g_L_Ships Then Return
		For Local o:TShip = EachIn g_L_Ships
			o.Update()
		Next
	EndFunction

	Method HyperspaceToSystem(s:TSystem)
		If s=_system Return ' can't hyperspace to the system you're already in
		
		' we are going to immediately jump to this system
		Local currentlyActiveSystem:TSystem = TSystem._g_ActiveSystem
		If currentlyActiveSystem currentlyActiveSystem.forget();TSystem._g_ActiveSystem=Null
						
		s.populate() ' load it up		
		Self.SetSystem(s) ' assign the ship's current system		
		s.SetAsActive() ' set as active
		
		G_Viewport.CenterCamera(self)
						
		' position us by the star	
		Local farthestDistance:Double = 0
		Local FarthestObject:TStellarObject = s.getFarthestObjectInSystem(farthestDistance)
				
		' position us at the farthest object
		If FarthestObject Then			
			Self.SetCoordinates(FarthestObject.GetX() + FarthestObject.GetSize() * 3, FarthestObject.GetY()) 
			Self.SetOrbitalVelocity(FarthestObject, True) 		
		Else
			Self.SetCoordinates(500000,500000)
		EndIf
		
		' centre the viewport
		Local sMap:TStarMap = G_viewport.GetStarMap()		
		sMap.Center()	' move the starmap "camera" to the middle of the active system
		sMap.UpdateCenteredSector()
		sMap.Update()	
		
		G_viewport.CreateMsg("Hyperspaced to " + s.getName())
	End Method

	Function Create:TShip(hullID:String, name:String = "Nameless") 

		Local sh:TShip = New TShip		' create an instance of the ship

		' create the hull and copy a few hull fields to corresponding ship fields
		sh._hull = THull.Create(hullID)
		sh._image = sh._hull._image
		sh._size = sh._hull._size
		sh._scaleX = sh._hull._scale
		sh._scaleY = sh._hull._scale
		sh._name = name					' give a name
		sh.isShownOnMap = True
		sh.canCollide = True
		sh._integrity = sh._hull.GetMass() 
		
		If Not g_L_Ships Then g_L_Ships = CreateList() 
		g_L_Ships.AddLast sh
		g_nrShips:+1
		
		Return sh											' return the pointer to this specific object instance
	EndFunction

EndType

