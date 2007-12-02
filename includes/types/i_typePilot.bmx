' -----------------------------------------------------------------
' TPilot is a generic intelligent entity, human or AI
' -----------------------------------------------------------------
Type TPilot Abstract
	Field _name:String									' The name of the pilot
	Field _controlledShip:TShip					' The ship the pilot is controlling
	Field _health:Int												
	Field _money:Long
	
	Method SetControlledShip(sh:TShip)
		_controlledShip = sh
	End Method
	
EndType

' ------------------------------------
' TPlayer represents a human pilot
' ------------------------------------
Type TPlayer Extends TPilot
	' GetInput handles the keyboard and joystick input for the ship
	Method GetInput()
		If NOT _controlledShip Then Return	' return if the player has no ship to control
		' keyboard controls
		If KeyDown(KEY_UP)		_controlledShip.SetThrottle(1)		
		If KeyDown(KEY_DOWN) 	_controlledShip.SetThrottle(-1)	
		If KeyDown(KEY_RIGHT) 	_controlledShip.SetController(1)	
		If KeyDown(KEY_LEFT) 	_controlledShip.SetController(-1)	

		' relase controls if keyboard keys are released
		If Not KeyDown(KEY_UP) And Not KeyDown(KEY_DOWN) 		_controlledShip.SetThrottle(0)
		If Not KeyDown(KEY_RIGHT) And Not KeyDown(KEY_LEFT) 	_controlledShip.SetController(0)
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
	Global g_L_AIPilots:TList				' a list holding all AI pilots

	Field _flyingSkill:Float					' 0 to 1		 	1 = perfect
	Field _aggressiveness:Float				' 0 to 1			1 = most aggressive
	Field _wimpyness:Float					' 0 to 1			1 = always fleeing, 0 = never fleeing
	Field _accuracy:Float					' 0 to 1			1 = perfect
	Field _destinationObject:TSpaceObject	' The destination for AI. Sector, planet, space station etc
	Field _desiredRotation:Float				' planned rotation
	Field _targetObject:TSpaceObject			' target object (for shooting, pursuing etc)
	

	' "Think" is the main AI routine to be called
	Method Think() 
		If Not _controlledShip Return
		_desiredRotation = DirectionTo(_controlledShip.GetX(), _controlledShip.GetY(), _targetObject.GetX(), _targetObject.GetY()) 
		'_controlledShip.AutoPilotRotation(_desiredRotation) 	' use the ship's autopilot function to rotate the ship as desired
		RotateTo(_desiredRotation)  	' use the AI logic to manually turn to the desired rotation
	EndMethod

	Method SetTarget(obj:TSpaceObject)
		_targetObject = obj
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
	
	Function UpdateAllAI()
		If NOT g_L_AIPilots Return
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