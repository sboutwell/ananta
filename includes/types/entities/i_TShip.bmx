
Type TShip Extends TMovingObject
	Global g_L_Ships:TList					' a list to hold all ships
	Global g_nrShips:Int = 0
	
	Field _hull:THull
	Field _forwardAcceleration:Float			' maximum forward acceleration (calculated by a routine)
	Field _reverseAcceleration:Float			' maximum reverse acceleration (calculated by a routine)
	Field _rotAcceleration:Float				' maximum rotation acceleration (calculated by a routine)
	Field _leftAcceleration:Float
	Field _rightAcceleration:Float
	Field _engineThrust:Float				' thrust (in newtons) given by the ship's main engines
	Field _reverseThrust:Float				' thrust (in newtons) given by the ship's reverse engines
	Field _rotThrust:Float					' thrust (in newtons) given by the ship's rotation thrusters
	Field _leftThrust:Float
	Field _rightThrust:Float
	Field _maxRotationSpd:Float				' maximum rotation speed (degrees per second)
	Field _rotKillPercentage:Float = 0.8		' the magnitude of the rotation damper. Values 0 to 1. 1 means max efficiency.
	Field _maxSpeed:Double = 600
	Field _isSpeedLimited:Int = True			' a flag to indicate if speed limiter is functional
	Field _isRotationLimited:Int = True		' a flag to indicate if rotation limiter is functional
	Field isLimiterOverridden:Int = False	' flag to indicate if speed and rotation limiters are overridden
	
	Field _throttlePosition:Float = 0		' -1 = full back, +1 = full forward
	Field _controllerPosition:Float = 0		' -1 = full left, +1 = full right
	Field _transPosition:Float = 0			' translation thruster position (left/right)
	
	Field _L_Engines:TList					' all ship's engines as TComponent
	
	Field _L_Weapons:TList					' list holding all weapons as TComponent
	Field _L_MiscEquipment:TList			
	Field _selectedWeaponSlot:TSlot			' the weapon slot currently selected as the active slot
	Field _selectedWeapon:TWeapon			' ... and the weapon itself in the active slot
	
	Field _lastShot:Int						' milliseconds since last shot
	Field isTriggerDown:Int = False			' is weapon trigger down
	
	Field isWarpDriveOn:Int = False
	Field _warpRatio:Double = 10:Double			' base warp ratio for warp travel 	
	Field _maxWarpRatio:Double = 5000:Double	' max warp ratio for warp travel 	
	
	Field _pilot:TPilot						' The pilot controlling this ship
	
	Method Delete()
		g_nrShips:-1
	End Method
	
	Method New()
		g_nrShips:+1
	End Method
	
	Method Destroy() 
		If _pilot Then _pilot.Kill() 
		_pilot = Null
		_hull = Null
		If _selectedWeaponSlot Then _selectedWeaponSlot.Destroy()
		
		_selectedWeaponSlot = Null
		_selectedWeapon = Null
		If _L_Engines Then
			For Local e:TComponent = EachIn _L_Engines
				e.Destroy()
			Next
			_L_Engines.Clear()
		End If
		
		If _L_Weapons Then
			For Local w:TComponent = EachIn _L_Weapons
				w.Destroy()
			Next
			_L_Weapons.Clear()
		End If
		If _L_MiscEquipment Then
			For Local e:TComponent = EachIn _L_MiscEquipment
				e.Destroy()
			Next
			_L_MiscEquipment.Clear()
		End If
		
		If _System Then _System.RemoveSpaceObject(Self)
		g_L_Ships.Remove(Self) 
		Super.Destroy()
	End Method

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
	
	Method GetLeftAcceleration:Float()
		Return _leftAcceleration
	End Method
	
	Method GetRightAcceleration:Float()
		Return _rightAcceleration
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
	
	Method SetTrans(trn:Float)
		_transPosition = trn
	End Method
	
	Method SetSystem(sys:TSystem) 
		_System = sys
		If sys <> Null Then sys.AddSpaceObject(Self) 		' add the ship to the System's space objects list		
	End Method

	Method SetCoordinates(x:Int, y:Int) 
		_x = x
		_y = y
	End Method
	
	' returns current forward (+) or reverse (-) acceleration depending on throttle position
	Method GetCurrentYAcceleration:Float()
		Local acc:Float = 0
		If _throttlePosition < 0 Then acc = _reverseAcceleration
		If _throttlePosition > 0 Then acc = _forwardAcceleration
		Return _throttlePosition * acc
	End Method
	
	' returns current right (+) or left (-) acceleration depending on lateral thruster position
	Method GetCurrentXAcceleration:Float()
		Local acc:Float = 0
		If _transPosition  < 0 Then acc = _leftAcceleration 
		If _transPosition > 0 Then acc = _rightAcceleration
		Return _transPosition * acc
	End Method
	
	Method Update() 
		If isWarpDriveOn Then
			SetThrottle(0)
			SetController(0)
			isTriggerDown = False
		End If

		ApplyRotation(_controllerPosition * _rotAcceleration)

		'(speed limiting now included in adjustthrusts)
		'If GetVel() > _maxSpeed And _isSpeedLimited And Not isLimiterOverridden Then LimitSpeed()
		
		'' apply player input
		If _isSpeedLimited And Not isLimiterOverridden Then AdjustThrusts()
		ApplyThrusts()		
	
		

		If _controllerPosition = 0 Then ApplyRotKill() 		' if the "joystick" is centered, fire the rotKill thrusters

		' firing
		If isTriggerDown Then FireWeapon() 
		
		' call update method of TMovingObject
		Super.Update()
		
		If isWarpDriveOn Then
			UpdatePosition(CalcWarpValue())
		EndIf

		If Self._pilot = G_player Then G_DebugWindow.AddText("Max warp ratio: " + CalcWarpValue())
	EndMethod
	
	Method AdjustThrusts()
		Local ax:Float,ay:Float
		Local a:Float
		
		If _throttlePosition<>0 Or _transPosition<>0	'if pilot is applying throttle, we want to go as fast as possible in throttle direction
			ax = (Cos( _rotation ) * _throttlePosition - Sin(_rotation) * _transPosition ) * _maxSpeed / Sqr(_throttlePosition * _throttlePosition + _transPosition * _transPosition)
			ay = (Sin( _rotation ) * _throttlePosition + Cos(_rotation) * _transPosition ) * _maxSpeed / Sqr(_throttlePosition * _throttlePosition + _transPosition * _transPosition)
			'ax = (Cos( _rotation ) * _throttlePosition ) * _maxSpeed
			'ay = (Sin( _rotation ) * _throttlePosition ) * _maxSpeed
		ElseIf GetVel() > _maxSpeed	'if going faster than limit, we want to slow down
			ax = GetXVel() * _maxSpeed / GetVel()
			ay = GetYVel() * _maxSpeed / GetVel()
		EndIf
		If ax<>0 Or ay<>0
			ax:- GetXVel()	'subtract current velocity from desired velocity to get change vector
			ay:- GetYVel()
			
			'solve quadratic equation to find what proportion of thrust we can apply without going over limit
			Local a:Float,b:Float,c:Float
			a = ax*ax + ay*ay
			b = 2*( ax*GetXVel() + ay*GetYVel() )
			c = GetXVel() * GetXVel() + GetYVel()*GetYVel() - _maxSpeed * _maxSpeed
			
			Local lambda1:Float,lambda2:Float, lambda:Float
			lambda1 = ( -b + Sqr(b*b - 4*a*c) )/(2*a)
			lambda2 = ( -b - Sqr(b*b - 4*a*c) )/(2*a)
			lambda=Min(Max(lambda1,lambda2),1.0)
			
			ax:*lambda
			ay:*lambda
			
			'work out accelerations in direction of throttle and trans
			Local dThrottle:Float, dTrans:Float
			dThrottle = Cos(_rotation)*ax + Sin(_rotation)*ay
			dTrans = Cos(_rotation)*ay - Sin(_rotation)*ax
			
			'multiply amounts by a big number to make up for the fact that this isn't all being applied this frame
			'(this should have some clever maths, but that would require knowing a lot about the timing code)
			dThrottle:*10
			dTrans:*10
			
			'work out if we need to scale down the throttles to get them within the levels allowed by the engines
			Local scaleThrottle:Float=1.0, scaleTrans:Float=1.0
			If dThrottle>0
				scaleThrottle=Min(dThrottle,_forwardAcceleration)/dThrottle
			ElseIf dThrottle<0
				scaleThrottle=-Min(-dThrottle,_reverseAcceleration)/dThrottle
			EndIf
			If dTrans>0
				scaleTrans=Min(dTrans,_rightAcceleration)/dTrans
			ElseIf dTrans<0
				scaleTrans=-Min(-dTrans,_leftAcceleration)/dTrans
			EndIf


			Local scale:Float = Min(scaleThrottle,scaleTrans)
			Local dx:Float=getxvel()+Cos(_rotation)*dThrottle*scaleThrottle -Sin(_rotation)*dTrans*scaleTrans
			Local dy:Float=getyvel()+Sin(_rotation)*dThrottle*scaleThrottle +Cos(_rotation)*dTrans*scaleTrans
			If Sqr(dx*dx+dy*dy)<=_maxspeed	'can scale trans/throttle independently
				dThrottle:*scaleThrottle
				dTrans:*scaleTrans
			Else
				dThrottle:*scale
				dTrans:*scale
			EndIf
			
			
				
			If dThrottle
				If dThrottle>0 dThrottle:/_forwardAcceleration Else dThrottle:/_reverseAcceleration
				SetThrottle dThrottle
			EndIf
			If dTrans
				If dTrans>0 dTrans:/_rightAcceleration Else dTrans:/_leftAcceleration
				SetTrans dTrans
			EndIf
		
			'Rem
			If Self=G_Player.GetControlledShip()
				G_debugWindow.AddText("scaleThrottle: "+scaleThrottle)
				G_debugWindow.AddText("scaleTrans: "+scaleTrans)
				G_debugWindow.AddText("dThrottle: "+dThrottle)
				G_debugWindow.AddText("dTrans: "+dTrans)
				G_debugWindow.AddText("ax: "+ax)
				G_debugWindow.AddText("ay: "+ay)
				G_debugWindow.Addtext("dp: "+(Cos(_rotation)*getxvel()+Sin(_rotation)*getyvel())/getvel())
			EndIf
			'EndRem
	
		EndIf
			
	EndMethod
	
	Method ApplyThrusts()
		If _throttlePosition > 0 Then
			ApplyVerticalImpulse(_throttlePosition * _forwardAcceleration) 
			If _L_Engines Then EmitEngineTrail(0, _throttlePosition)	' tail
		EndIf
		If _throttlePosition < 0 Then
			ApplyVerticalImpulse(_throttlePosition * _reverseAcceleration) 
			If _L_Engines Then EmitEngineTrail(180, _throttlePosition) ' nose
		EndIf
		If _transPosition < 0 And _leftAcceleration > 0 Then
			ApplyHorizontalImpulse(_transPosition * _leftAcceleration)
			If _L_Engines Then EmitEngineTrail(270, _transPosition)	'left
		End If
		If _transPosition > 0 And _rightAcceleration > 0 Then
			ApplyHorizontalImpulse(_transPosition * _rightAcceleration)
			If _L_Engines Then EmitEngineTrail(90, _transPosition)	'right
		End If
	End Method
	
	Method CalcWarpValue:Double()
		Local gravityCoeff:Double = (_strongestGravity:Double^(1.0:Double/4.0:Double)^2.0:Double)
		If gravityCoeff < 0.00000000000000001:Double Then Return _maxWarpRatio
		Local ratio:Double = _warpRatio:Double / gravityCoeff:Double
		If ratio > _maxWarpRatio Then Return _maxWarpRatio
		Return ratio
	End Method
	
	' calculate the distance it takes for this ship to come to a full stop
	Method CalcStopDistance:Double(useReverse:Int = False)
		Local acceleration:Float
		If useReverse Then 
			acceleration = GetReverseAcceleration()
		Else
			acceleration = GetForwardAcceleration() 
		EndIf
		
		Return CalcAccelerationDistance(GetVel(),CalcStopTime(GetVel(), acceleration),acceleration)
	End Method

	Method LimitSpeed()
		If GetVel() <= _maxSpeed Then Return
		Local overSpeed:Double = GetVel() - _maxSpeed ' how much we're above speed limit
		Local moveDir:Float = CalcMovingDirection()  ' current moving direction
		'Local oppDir:Float = DirAdd(moveDir,180)	  ' opposite dir to the moving dir (direction for deceleration)
		
		Local relMoveDir:Float = DirAdd(moveDir,-_rotation) ' moving direction in relation to ship's rotation
		Local relOppDir:Float = DirAdd(relMoveDir,180) ' opposite dir in relation to ship's rotation
		
		' take player's attempted thrust into consideration to allow direction change while FBW decelerates
		Local appliedXAccel:Float = GetCurrentXAcceleration()
		Local appliedYAccel:Float = GetCurrentYAcceleration()
		Local appliedDir:Float
		Local angleDiff:Float
		If appliedXAccel <> 0 Or appliedYAccel <> 0 Then
			appliedDir:Float = DirAdd(DirectionTo(0, 0, appliedXAccel, appliedYAccel), - 90)
			angleDiff:Float = GetAngleDiff(relOppDir, appliedDir)			
			If angleDiff > - 90 And angleDiff < 90 Then
				Local adjustedDir:Float = anglediff / 2:Float ' half of the angle difference
				limitFloat(adjustedDir, - 45, 45)
				relOppdir = DirAdd(relOppDir, adjustedDir)
			EndIf
		EndIf
		
		' required acceleration is how much would be needed to get below the speed limit
		'Local requiredXaccel:Float = overSpeed * Sin(relOppDir)
		'Local requiredYaccel:Float = overSpeed * Cos(relOppDir)
		
		' ... but the thrusters will not necessarily manage to generate that much opposing thrust, 
		' so we'll have to calculate how to fire the thrusters in order to decelerate:
		' -- direction of thrust controller levers
		Local throttleDir:Float = 1
		Local transDir:Float = 1
		If relMoveDir < 90 Or relMoveDir > 270 Then throttleDir = -1
		If relMoveDir >= 0 And relMoveDir <= 180 Then transDir = -1
		
		' -- maximum available thrust acceleration
		Local maxYAccel:Float = _forwardAcceleration
		If throttleDir < 0 Then maxYAccel = _reverseAcceleration 
		Local maxXAccel:Float = _rightAcceleration
		If transDir < 0 Then maxXAccel = _leftAcceleration
		
		' trigonometry for vertical and lateral thrust
		Local actualXAccel:Float = Tan(relOppDir) * maxYAccel * throttleDir
		Local actualYAccel:Float = Tan(90:Float - relOppDir) * maxXAccel * transDir

		' stay within limits
		limitFloat(actualXAccel,-maxXaccel,maxXAccel)
		limitFloat(actualYAccel,-maxYaccel,maxYAccel)
		
		Local actualThrottlePos:Float = 0
		Local actualTransPos:Float = 0
		
		actualThrottlePos = (actualYAccel/maxYAccel) 
		actualTransPos = (actualXAccel/maxXaccel)
						
		limitFloat(actualThrottlePos,-1:Float,1:Float)
		limitFloat(actualTransPos, - 1:Float, 1:Float)

		SetThrottle(actualThrottlePos)
		SetTrans(actualTransPos)
	End Method
	
	Method GetSelectedWeapon:TWeapon()
		Return _selectedWeapon
	End Method
	
	Method GetSelectedWeaponSlot:TSlot()
		Return _selectedWeaponSlot
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

	Method ToggleWarpDrive()
		ToggleBoolean(isWarpDriveOn)
	End Method
	
	Method ToggleLimiter()
		Toggleboolean(isLimiterOverridden)
		Local status:String = "active"
		If isLimiterOverridden Then Status = "inactive"
		G_Viewport.CreateMsg("FBW limiter " + status)
	End Method
	
	' apply acceleration to x and y velocity vectors
	Method ApplyVerticalImpulse(accel:Float) 
		Local Ximpulse:Float = accel * (Cos(_rotation)) 
		Local Yimpulse:Float = accel * (Sin(_rotation)) 

		_Xvel:+Ximpulse * G_delta.GetDelta() 
		_Yvel:+Yimpulse * G_delta.GetDelta()
	EndMethod
	
	Method ApplyHorizontalImpulse(accel:Float) 
		Local Ximpulse:Float = accel * (Cos(_rotation + 90)) 
		Local Yimpulse:Float = accel * (Sin(_rotation + 90)) 

		_Xvel:+Ximpulse * G_delta.GetDelta() 
		_Yvel:+Yimpulse * G_delta.GetDelta()
	EndMethod
	
	
	
	Method ApplyRotation(rotAcceleration:Float)
		_rotationSpd:+rotAcceleration * G_delta.GetDelta() 
		If _isRotationLimited And Not isLimiterOverridden Then ApplyRotationLimiter()
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
	' Do not call in the main loop as it is quite slow.
	Method PreCalcPhysics() 
		' reset performance values
		_mass = 0
		_engineThrust = 0
		_reverseThrust = 0
		_rotThrust = 0
		_rightThrust = 0
		_leftThrust = 0
		'
				
		For Local slot:TSlot = EachIn _hull.GetSlotList() ' iterate through all equipment slots
			If slot.GetComponentList() Then	' if this slot has components, iterate through all of them
				For Local component:TComponent = EachIn slot.GetComponentList() 
					If slot.isEngine() Then
						If component.getType() = "engine" Then
							Local prop:TPropulsion = TPropulsion(component.GetShipPart()) 
							If slot.GetExposedDir() = 180 Then _engineThrust = _engineThrust + prop.GetThrust() 
							If slot.GetExposedDir() = 0 Then _reverseThrust = _reverseThrust + prop.GetThrust() 
							If slot.GetExposedDir() = 270 Then _rightThrust = _rightThrust + prop.GetThrust()
							If slot.GetExposedDir() = 90 Then _leftThrust = _leftThrust + prop.GetThrust()
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
	
		UpdatePerformance() ' updates acceleration values 
	EndMethod

	Method UpdatePerformance() 
		If _mass = 0 Then Return
		_forwardAcceleration = (_engineThrust / _mass) 
		_reverseAcceleration = (_reverseThrust / _mass) 
		_leftAcceleration  = (_leftThrust / _mass)
		_rightAcceleration  = (_rightThrust / _mass)
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
		If Not slot Then
			If G_Debug Then Print "AddComponentToSlotID error: slot " + slotID + " not found for hull " + _hull.GetID()
			Return Null
		End If
		Local result:Int = AddComponentToSlot(comp, slot) 
		Return result
	End Method

	' As opposed to AddComponentToSlotID, AddComponentToSlot takes the actual slot (not ID) as a parameter
	Method AddComponentToSlot:Int(comp:TComponent, slot:TSlot) 
		Local result:Int = _hull.AddComponent(comp, slot) 
		If TPropulsion(comp.GetShipPart()) Then
			If Not _L_Engines Then _L_Engines = CreateList() 
			_L_Engines.AddLast(comp) 
			' create particle generators for engines and attach engines to the ship so the generators will follow
			comp.CreateParticleGenerator()
			AddAttachment(comp,slot.GetXOffset(),slot.GetYOffSet(),DirAdd(slot.GetExposedDir(),180),False)
		Else ' misc equipment
			If Not _L_MiscEquipment Then _L_MiscEquipment = CreateList()
			_L_MiscEquipment.AddLast(comp)
		EndIf
		Self.PreCalcPhysics()  	' updates the ship performance after component installation
		Return Result
	End Method
	
	' calls the engines pointing to the specific direction to emit their particle generators
	Method EmitEngineTrail(dir:Float = 180, thrust:Float = 1)
		If Not _L_Engines Then Return
		Local co:TComponent
		For co = EachIn _L_Engines
			If co.GetRotOffset() = dir Then co.EmitParticles(thrust)
		Next
	End Method
	
	Function UpdateAll() 
		If Not g_L_Ships Then Return
		For Local o:TShip = EachIn g_L_Ships
			o.Update()
		Next
	EndFunction

	Method HyperspaceToSystem(s:TSystem)
		If s.GetUniqueID() = _system.GetUniqueID() Return ' can't hyperspace to the system you're already in
		
		' we are going to immediately jump to this system
		Local currentlyActiveSystem:TSystem = TSystem._g_ActiveSystem
		If currentlyActiveSystem currentlyActiveSystem.forget();TSystem._g_ActiveSystem=Null
						
		If Not s.isPopulated() Then s.populate() ' load it up		
		SetSystem(s) ' assign the ship's current system
		s.SetAsActive() ' set as active
		
		G_Viewport.CenterCamera(Self)
						
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
		GCCollect()
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
		sh.ResetCollisionLevels()
		sh._integrity = sh._hull.GetMass() 
		
		If Not g_L_Ships Then g_L_Ships = CreateList() 
		g_L_Ships.AddLast sh
		
		Return sh											' return the pointer to this specific object instance
	EndFunction

EndType

