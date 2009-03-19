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

' -----------------------------------------------------------------
' TPilot is a generic intelligent entity, human or AI
' -----------------------------------------------------------------
Type TPilot Abstract
	Field _name:String									' The name of the pilot
	Field _controlledShip:TShip					' The ship the pilot is controlling
	Field _health:Int												
	Field _money:Long
	
	Method Kill() Abstract
	
	Method SetControlledShip(sh:TShip)
		_controlledShip = sh
	End Method
	
	Method GetControlledShip:TShip() 
		Return _controlledShip
	End Method
	
EndType

' ------------------------------------
' TPlayer represents a human pilot
' ------------------------------------
Type TPlayer Extends TPilot

	Method Kill() 
		SetControlledShip(Null) 
		'game over?
	End Method

	' GetInput handles the keyboard and joystick input for the ship
	' (redo this using event handler)
	Method GetInput()
		If _controlledShip Then
		' ship controls

			' jump to the system in the centre of the screen
			If KeyHit(KEY_H) And G_viewport.GetStarMap().getClosestSystemToScreenCentre()
				Self.GetControlledShip().HyperspaceToSystem(G_viewport.GetStarMap().getClosestSystemToScreenCentre())
			EndIf
		
			If KeyDown(KEY_UP) _controlledShip.SetThrottle(1) 
			If KeyDown(KEY_DOWN) _controlledShip.SetThrottle(- 1) 
			If KeyDown(KEY_RIGHT) _controlledShip.SetController(1) 
			If KeyDown(KEY_LEFT) _controlledShip.SetController(- 1) 	
			If KeyDown(KEY_LCONTROL) Or KeyDown(KEY_RCONTROL) Then _controlledShip.isTriggerDown = True
			If Not KeyDown(KEY_LCONTROL) And Not KeyDown(KEY_RCONTROL) Then _controlledShip.isTriggerDown = False
			' relase controls if keyboard keys are released
			If Not KeyDown(KEY_UP) And Not KeyDown(KEY_DOWN) 		_controlledShip.SetThrottle(0)
			If Not KeyDown(KEY_RIGHT) And Not KeyDown(KEY_LEFT) _controlledShip.SetController(0) 

			If KeyHit(KEY_J) Then
				ToggleBoolean(_controlledShip.isWarpDriveOn)
			End If
		EndIf
		
		' misc controls
		If KeyDown(KEY_F1) Then
			G_viewport.ShowInstructions()
		End If
		
		If KeyHit(KEY_P) Then G_Delta.TogglePause()
		
		If KeyHit(KEY_G) Then G_viewport.GetStarMap().ToggleVisibility()
		
		If KeyHit(KEY_PAGEUP) Then G_viewport.CycleCamera(0)
		If KeyHit(KEY_PAGEDOWN) Then G_viewport.CycleCamera(1)
		
		If Not KeyDown(KEY_LSHIFT) And ..
			Not KeyDown(KEY_RSHIFT) And ..
			Not KeyDown(KEY_RALT) And ..
			Not KeyDown(KEY_LALT) Then
				If KeyDown(KEY_Z) Then G_viewport.ZoomIn() 
				If KeyDown(KEY_X) Then G_viewport.ZoomOut() 
		EndIf
		
		If KeyDown(KEY_LSHIFT) Or KeyDown(KEY_RSHIFT) Then
			If KeyDown(KEY_Z) Then G_viewport.GetSystemMap().ZoomIn() 
			If KeyDown(KEY_X) Then G_viewport.GetSystemMap().ZoomOut() 
			
		EndIf
		
		' starmap scrolling
		If G_viewport.GetStarMap().isVisible Then
			Local multiplier:Float = 1
			If KeyDown(KEY_LSHIFT) Or KeyDown(KEY_RSHIFT) Then 
				multiplier = 10		' with shift multiply the scroll speed by 10
			EndIf
							
			If KeyDown(KEY_A) Then G_viewport.GetStarMap().scrollX(- 1 * multiplier)  	' scroll left
			If KeyDown(KEY_D) Then G_viewport.GetStarMap().scrollX(1 * multiplier)  		' scroll right
			If KeyDown(KEY_S) Then G_viewport.GetStarMap().scrollY(1 * multiplier) 		' scroll down
			If KeyDown(KEY_W) Then G_viewport.GetStarMap().scrollY(- 1 * multiplier) 		' scroll up
			
			If KeyDown(KEY_C) Then G_viewport.GetStarMap().isPersistent = False; G_viewport.GetStarMap().ZoomIn() 	' zoom in starmap
			If KeyDown(KEY_V) Then G_viewport.GetStarMap().isPersistent = False; G_viewport.GetStarMap().ZoomOut() 	' zoom out starmap
		End If
		
		' alt modifiers
		If KeyDown(KEY_LALT) Or KeyDown(KEY_RALT) Then
			If KeyDown(KEY_ENTER) Then TViewport.ToggleFullScreen() 
			If KeyDown(KEY_Z) Then G_viewport.ResetZoomFactor() 
			If KeyDown(KEY_X) Then G_viewport.GetSystemMap().ResetZoomFactor() 
			If KeyDown(KEY_C) Then G_viewport.GetStarMap().Center() 	' center the starmap with shift-c
		End If
		
		If Not KeyDown(KEY_Z) And Not KeyDown(KEY_X) Then
			G_viewport.StopZoom() 
			G_viewport.GetSystemMap().StopZoom() 
		EndIf
		
		If Not G_viewport.GetStarMap().isPersistent And Not KeyDown(KEY_C) And Not KeyDown(KEY_V) Then
			G_viewport.GetStarMap().isPersistent = True
			G_viewport.GetStarMap().StopZoom() 
			G_viewport.GetStarMap().Update()
		EndIf
		
	EndMethod
	
	Function Create:TPlayer(name:String)
		Local pl:TPlayer = New TPlayer
		pl._name = name
		Return pl
	EndFunction			
EndType

' ------------------------------------
' TAIPlayer represents an AI pilot
' ------------------------------------
Type TAIPlayer Extends TPilot
	' flight action modes
	Const fl_wait:Int = 0
	Const fl_approach:Int = 1
	Const fl_follow:Int = 2
	Const fl_pursuit:Int = 3
	Const fl_flee:Int = 4
	' ---
	
	Global g_L_AIPilots:TList				' a list holding all AI pilots
	Field _flyingSkill:Float				' 0 to 1		 	1 = perfect
	Field _aggressiveness:Float				' 0 to 1			1 = most aggressive
	Field _wimpyness:Float					' 0 to 1			1 = always fleeing, 0 = never fleeing
	Field _accuracy:Float					' 0 to 1			1 = perfect
	Field _destinationObject:TSpaceObject	' The destination for AI. Sector, planet, space station etc
	Field _desiredRotation:Float			' planned rotation
	Field _targetObject:TSpaceObject		' target object (for following, pursuing etc)
	Field _targetX:Double					' desired X-coord
	Field _targetY:Double					' desired Y-coord
	Field _actionMode:Int					' current action mode: 0 wait, 1 approach, 2 follow, etc
	
	Field _wantToStop:Int = False
	
	Method SetTarget(obj:TSpaceObject) _targetObject = obj 
	End Method
	Method SetTargetCoords(x:Double,y:Double) 
		_targetX = x 
		_targetY = y
	End Method
	
	Method GetTarget:TSpaceObject() Return _targetObject 
	End Method
	Method GetTargetX:Double() Return _targetX 
	EndMethod		
	Method GetTargetY:Double() Return _targetY 
	EndMethod		
	
	' "Think" is the main AI routine to be called every frame
	Method Think() 
		If Not _controlledShip Return
		
		If Not _targetObject And (_targetX = Null Or _targetY = Null) Then Return
		
		' temporary keybindings for testing AI navigation
		If KeyHit(KEY_U) Then 
			_targetY = _targetObject.GetY()
			_targetX = _targetObject.GetX()
		EndIf
		
		If _targetX AND _targetY Then FlyToTargetCoords()

	EndMethod

	Method FlyToTargetCoords()
		Local maxSpeed:Float = 500
		Local doStop:Int = FALSE
		Local inProximity:Int = FALSE
		
		Local currentSpeed:Double = _controlledShip.GetVel()
		Local dirTotarget:Double = DirectionTo(_controlledShip.GetX(), _controlledShip.GetY(), _targetX, _targetY) 
		Local currentMovingDir:Double = _controlledShip.CalcMovingDirection()
		Local distanceToTarget:Double = Distance(_controlledShip.GetX(),_controlledShip.GetY(),_targetX,_targetY)
		' where we are currenlty drifting in relation to the target direction?
		Local angleDiff:Double = GetAngleDiff(dirToTarget,currentMovingDir)		
		
		' check if we're close enough to start decelerating
		If distanceToTarget < _controlledShip.CalcStopDistance(True) + 100 Then
			doStop = TRUE
		EndIf
		
		G_DebugWindow.AddText("  dist to target: " + distanceToTarget)
		G_DebugWindow.AddText("  my speed: " + currentSpeed)
		G_DebugWindow.AddText("  angle diff: " + angleDiff)
		G_DebugWindow.AddText("  dir to target" + dirToTarget)
		G_DebugWindow.AddText("  current rotation" + _controlledShip.GetRot())
		
		If Abs(angleDiff) < 80.0 And currentSpeed > 10.0 Then 
			' if we're flying generally towards the target, point at the opposite angle between movingdir and dirToTarget
			_desiredRotation = DirAdd(dirToTarget, -angleDiff)
		'ElseIf (currentSpeed <= 30.0 and not _wantToStop) Or Abs(angleDiff) > 160 Then
		ElseIf currentSpeed > 100 Then
			G_DebugWindow.AddText("  Need to slow down and think a bit.")
			DoStop = TRUE
		Else
			G_DebugWindow.AddText("  Wanna point at target")
			_desiredRotation = dirToTarget
		EndIf
		
		G_DebugWindow.AddText("  desired rot: " + _desiredRotation)
		
		' stop
		If doStop Then 
			G_DebugWindow.AddText("  Stopping")
			_wantToStop = True
			DecelerateOnApproach(TRUE) ' true = use reversers for stopping
			Return
		EndIf

		AccelerateToDesiredDir()
	
	End Method
	
	Method AccelerateToDesiredDir(useReverse:Int = False)
		RotateTo(_desiredRotation)
		
		' Thrust lever position (forward/back)
		Local thrust:Float = 1.0 
		If useReverse Then thrust = -1 * thrust
		
		' calculate the rotation sector in which engines can be fired
		Local threshold:Int = 15  ' degrees
		If _controlledShip.GetVel() < 100 Then threshold :- (200/_controlledShip.GetVel()) 'narrow down the sector at lower speeds
		LimitInt(threshold,3,15) ' make sure threshold is between set limits
		
		' fire the engines when within desired heading
		If Abs(GetAngleDiff(_desiredRotation,_controlledShip.GetRot())) < threshold Then 
			_controlledShip.SetThrottle(thrust)
		Else
			_controlledShip.SetThrottle(0)	' cut throttle
		EndIf

	End Method
	
	Method DecelerateOnApproach(useReverse:Int = False)
		If Not _targetX Or Not _targetY Then 
			_wantToStop = False
			Return
		EndIf
		
		If _controlledShip.GetVel() < 5 Then ' don't bother decelerating if we're slow enough
			_controlledShip.SetThrottle(0)	' cut throttle
			_controlledShip.SetController(0) ' center stick
			_wantToStop = False
			Return	
		EndIf
		
		Local dirTotarget:Double = DirectionTo(_controlledShip.GetX(), _controlledShip.GetY(), _targetX, _targetY) 
		Local currentMovingDir:Double = _controlledShip.CalcMovingDirection()
		Local angleDiff:Double = GetAngleDiff(dirToTarget,currentMovingDir)		
		
		If useReverse Then 
			_desiredRotation = DirAdd(dirToTarget, angleDiff)
		Else
			_desiredRotation = DirAdd(dirToTarget, 180 + angleDiff)
		EndIf

		'overshoot check
		If useReverse And Abs(GetAngleDiff(currentMovingDir,_desiredRotation)) > 160 Then _desiredRotation:+180
		If NOt useReverse And Abs(GetAngleDiff(currentMovingDir,_desiredRotation)) < 20 Then _desiredRotation:+180
		
				
		AccelerateToDesiredDir(useReverse)
	End Method
	
	' Stop the ship using either main or reverse engines.
	' Currently the decision which engines to use needs to be done outside this routine.
	Method Stop(useReverse:Int = False)
		If _controlledShip.GetVel() < 5 Then ' don't bother decelerating if we're slow enough
			_controlledShip.SetThrottle(0)	' cut throttle
			_controlledShip.SetController(0) ' center stick
			_wantToStop = False
			Return	
		EndIf
		
		If NOT useReverse Then 
			_desiredRotation = DirAdd(_controlledShip.CalcMovingDirection(), 180) ' aim main engines backward
		Else
			_desiredRotation = _controlledShip.CalcMovingDirection()
		EndIf
		
		AccelerateToDesiredDir(useReverse)
	End Method
	
	Method AimTarget()
		_desiredRotation = DirectionTo(_controlledShip.GetX(), _controlledShip.GetY(), _targetObject.GetX(), _targetObject.GetY()) 
		Local tDist:Double = Distance(_controlledShip.GetX(), _controlledShip.GetY(), _targetObject.GetX(), _targetObject.GetY()) 
		Local rotDiff:Float = Abs(_controlledShip.GetRot() - _desiredRotation) 
		If tDist > 1000 Or rotDiff > 15 Then
			RotateTo(_desiredRotation)     	' use the AI logic to turn to the desired rotation
			_controlledShip.isTriggerDown = False
		Else
			RotateTo(_desiredRotation, True)      	' use the AI logic to turn to the desired rotation
			_controlledShip.isTriggerDown = True		' fire
		EndIf		
	End Method
		
	
	Method RotateTo(heading:Float, aggressiveMode:Int = False) 
		Local diff:Float = GetAngleDiff(_controlledShip.GetRot(),heading)  ' returns degrees between current and desired rotation
		' if we're "close enough" to the desired rotation (take the rot thrust performance into account)...
		If Not aggressiveMode And Abs(diff) < 1 + _controlledShip.GetRotAccel() * G_delta.GetDelta() * 2 Then
			_controlledShip.SetController(0)  	 					'... center the joystick...
			Return  												' ... and return with no further action
		EndIf
		' if diff < 0, the desired rotation is faster to reach by rotating to the right, diff > 0 vice versa
		If diff > 0 Then _controlledShip.SetController(1)  		' rotation thrusters full right
		If diff < 0 Then _controlledShip.SetController(-1) 		' rotation thrusters full left
		If Not aggressiveMode Then	' in "aggressive mode" the AI does not slow down rotation speed before the desired heading has been reached
			' *********** calculates when to stop rotation ******************
			' Calculate the number of degrees it takes for the ship to stop rotating
			' The absolute value of rotational speed (degrees per second):
			Local rotSpd:Float = Abs(_controlledShip.GetRotSpd()) 
			' The number of seconds it takes for the rotation to stop: (time)
			Local SecondsToStop:Float = Abs(rotSpd) / (_controlledShip.GetRotAccel()) 
			' CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
			' s = vt + at^2
			Local degreesToStop:Float = CalcAccelerationDistance(rotSpd, secondsToStop, - _controlledShip.GetRotAccel()) 
			' stop rotating if it takes more degrees to stop than the angle difference is
			If degreesToStop >= Abs(diff) Then
				If diff > 0 And _controlledShip.GetRotSpd() > 0 Then _controlledShip.SetController(-1) 		' fire the opposing (left)  rotation thrusters
				If diff < 0 And _controlledShip.GetRotSpd() < 0 Then _controlledShip.SetController(1)  		' fire the opposing (right) rotation thrusters
			EndIf
			' ***************************************************************
		EndIf
		
	EndMethod

	' called from the main draw routine of TSpaceobject 
	Method DrawAIVectors()
		Local cShip:TShip = TShip(_controlledShip)
		SetAlpha(0.3)
		SetRotation(0)
		SetScale(1,1)
		' line to target
		G_Viewport.DrawLineToWorld(cShip.GetX(),cShip.GetY(),_targetX,_targetY)
		
		' moving direction
		SetColor(255,60,60)
		G_Viewport.DrawLineToWorld(cShip.GetX(),cShip.GetY(),cShip.GetX() + 25 * Cos(cShip.CalcMovingDirection()), ..
						cShip.GetY() + 25 * Sin(cShip.CalcMovingDirection()))
		' planned rotation
		SetColor(0,255,100)
		G_Viewport.DrawLineToWorld(cShip.GetX(),cShip.GetY(),cShip.GetX() + 35 * Cos(_desiredRotation), ..
						cShip.GetY() + 35 * Sin(_desiredRotation))
		
		If _targetObject Then G_Viewport.DrawCircleToWorld(_targetObject.GetX(),_targetObject.GetY(),10)
	End Method
		

	
	Method Kill() 
		SetControlledShip(Null) 
		g_L_AIPilots.Remove(Self) 
	End Method

	Function UpdateAllAI()
		If Not g_L_AIPilots Return
		For Local ai:TAIPlayer = EachIn g_L_AIPilots
			ai.Think()  ' the main AI routine
		Next
	End Function

	Function Create:TAIPlayer(name:String)
		Local pl:TAIPlayer = New TAIPlayer
		pl._name = name

		If Not g_L_AIPilots Then g_L_AIPilots = CreateList()
		g_L_AIPilots.AddLast pl

		Return pl
	EndFunction
EndType