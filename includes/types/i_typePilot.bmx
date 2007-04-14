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

' -----------------------------------------------------------------
' TPilot is a generic intelligent entity, human or AI
' -----------------------------------------------------------------
Type TPilot Abstract
	Field name:String									' The name of the pilot
	Field controlledShip:TShip					' The ship the pilot is controlling
	Field health:Int												
	Field money:Long
EndType

' ------------------------------------
' TPlayer represents a human pilot
' ------------------------------------
Type TPlayer Extends TPilot
	' GetInput handles the keyboard and joystick input for the ship
	Method GetInput()
		' keyboard controls
		If KeyDown(KEY_UP)		controlledShip.ApplyThrottle(1)		
		If KeyDown(KEY_DOWN) 	controlledShip.ApplyThrottle(-1)	
		If KeyDown(KEY_RIGHT) 	controlledShip.ApplyController(1)	
		If KeyDown(KEY_LEFT) 	controlledShip.ApplyController(-1)	

		' relase controls if keyboard keys are released
		If Not KeyDown(KEY_UP) And Not KeyDown(KEY_DOWN) 		controlledShip.ApplyThrottle(0)
		If Not KeyDown(KEY_RIGHT) And Not KeyDown(KEY_LEFT) 	controlledShip.ApplyController(0)
	EndMethod
	
	Function Create:TPlayer(name:String)
		Local pl:TPlayer = New TPlayer
		pl.name = name
		Return pl
	EndFunction			
EndType

' ------------------------------------
' TAIPlayer represents an AI pilot
' ------------------------------------
Type TAIPlayer Extends TPilot
	Global g_L_AIPilots:TList				' a list holding all AI pilots

	Field flyingSkill:Float					' 0 to 1		 	1 = perfect
	Field aggressiveness:Float				' 0 to 1			1 = most aggressive
	Field wimpyness:Float					' 0 to 1			1 = always fleeing, 0 = never fleeing
	Field accuracy:Float					' 0 to 1			1 = perfect
	Field destinationObject:TSpaceObject	' The destination for AI. Sector, planet, space station etc
	Field desiredRotation:Float				' planned rotation
	Field targetObject:TSpaceObject			' target object (for shooting, pursuing etc)
	

	' "Think" is the main AI routine to be called
	Method Think()
		desiredRotation = DirectionTo(controlledShip.x,controlledShip.y,targetObject.x,targetObject.y)
		'controlledShip.AutoPilotRotation(desiredRotation)	' use the ship's autopilot function to rotate the ship as desired
		RotateTo(desiredRotation) 	' use the AI logic to manually turn to the desired rotation
	EndMethod

	Method RotateTo(desiredRotation:Float,aggressiveMode:Int=False) 
		Local diff:Float = GetAngleDiff(controlledShip.rotation,desiredRotation)  ' returns degrees between current and desired rotation

		If Abs(diff) < 1 + controlledShip.rotAcceleration/2 Then	' if we're "close enough" to the desired rotation (take the rot thrust performance into account)...
			controlledShip.ApplyController(0)	 					'... center the joystick...
			Return  												' ... and return with no further action
		EndIf
		
		' if diff < 0, the desired rotation is faster to reach by rotating to the right, diff > 0 vice versa
		If diff > 0 Then controlledShip.ApplyController(1) 		' rotation thrusters full right
		If diff < 0 Then controlledShip.ApplyController(-1) 		' rotation thrusters full left
		
		If Not aggressiveMode Then
			' *********** calculates when to stop rotation ******************
			' Calculate the number of degrees it takes for the ship to stop rotating
			' The absolute value of rotational speed (degrees per frame):
			Local rotSpd:Float = Abs(controlledShip.RotationSpd)  
			' The number of frames it takes for the rotation to stop: (time)
			Local framesToStop:Int 	 = Abs(rotSpd) / (controlledShip.rotAcceleration)
			' CalcAccelerationDistance:Float(speed:Float,time:Float,acceleration:Float)
			' s = vt + at^2
			Local degreesToStop:Float = CalcAccelerationDistance(rotSpd, framesToStop, -controlledShip.rotAcceleration)
			' stop rotating if it takes more degrees to stop than the angle difference is
			If degreesToStop >= Abs(diff) Then
				If diff > 0 And controlledShip.RotationSpd > 0 Then controlledShip.ApplyController(-1) 		' fire the opposing (left)  rotation thrusters
				If diff < 0 And controlledShip.RotationSpd < 0 Then controlledShip.ApplyController(1)  		' fire the opposing (right) rotation thrusters
			EndIf
			' ***************************************************************
		EndIf
	EndMethod

	Function Create:TAIPlayer(name:String)
		Local pl:TAIPlayer = New TAIPlayer
		pl.name = name

		If Not g_L_AIPilots Then g_L_AIPilots = CreateList()
		g_L_AIPilots.AddLast pl

		Return pl
	EndFunction
EndType