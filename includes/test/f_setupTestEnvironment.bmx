' test stuff for development

Function SetupTestEnvironment()
	Local sectX:Int = 5793	' starting sector coordinates
	Local sectY:Int = 5649
	
	' make sure the starting sector has at least 1 star in it...
	Local sect:TSector
	sect = TSector.Create(sectX, sectY)
	sect.Populate()

	' set the first system of the generated sector active	
	Local system:TSystem = TSystem(sect._L_systems.ValueAtIndex(1))
	system.SetAsActive()
	
	GenerateTestSystem2()
	
	' ----------- STARMAP ----------
	Local sMap:TStarMap = G_viewport.GetStarMap()
	sMap.Center()	' move the starmap "camera" to the middle of the active system
	sMap.UpdateCenteredSector()
	sMap.Update()
	'sMap._isPersistent = TRUE
	' -----------------------------
	
	' generate the player and player's ship
	G_Player = TPlayer.Create("Da Playah") 
	Local s1:TShip = TShipModel.BuildShipFromModel("nadia") 
	s1.SetName("Player ship") 
	s1.SetCoordinates(250000,250000)
	s1.SetSystem(TSystem.GetActiveSystem()) 
	s1.SetRot(90)
	' assign the ship for the player to control
	s1.AssignPilot(G_Player) 
	s1._integrity = 2000
	Local part1:TParticleGenerator = TParticleGenerator.Create("smoke.png",0,0, TSystem.GetActiveSystem())
	s1.AddAttachment(part1)
	
	rem
	' create AI wingman
	Local aiWingman:TAIPlayer = TAIPlayer.Create("AI")
	Local WingmanShip:TShip = TShipModel.BuildShipFromModel("nadia")
	WingmanShip.SetName("AI Ship")
	WingmanShip.SetCoordinates(250500 + Rand(- 5000, 5000), 250000 + Rand(- 5000, 5000))
	WingmanShip.SetSystem(TSystem.GetActiveSystem())
	WingmanShip.AssignPilot(aiWingman)
	aiWingman.SetTarget(G_player.GetControlledShip())
	aiWingman.SetActionMode(TAIPlayer.fl_follow)
	aiWingman.SetAccuracy(Rnd(0, 1))
	
	SeedRnd(millisecs())
	For local i:Int = 1 To 6
		' create an AI ship for testing
		Local ai:TAIPlayer = TAIPlayer.Create("AI")
		Local a1:TShip = TShipModel.BuildShipFromModel("nadia")
		a1.SetName("AI Ship")
		a1.SetCoordinates(250500 + Rand(-20000,20000),250000 + Rand(-20000,20000))
		a1.SetSystem(TSystem.GetActiveSystem())
		a1.AssignPilot(ai)
		a1.SetRot(45)
		'ai.SetTarget(G_Player.GetControlledShip())
		'ai.SetTargetCoords(a1.GetX(),a1.GetY())
		ai.SetActionMode(TAIPlayer.fl_pursuit)	
		ai.SetAccuracy(Rnd(0,1))
		ai.SetActionMode(TAIPlayer.fl_pursuit)
		ai.SetAccuracy(Rnd(0, 1))
	Next
	endrem
	
	G_viewport.CreateMsg("Player ship mass: " + s1.GetMass()) 
	
	G_viewport.CenterCamera(s1)           		' select the player ship as the object for the camera to follow
End Function

' new generate system test
Function GenerateTestSystem2:TStar() 
	Local system1:TSystem = TSystem.GetActiveSystem()
	
'	DebugLog "populating system "+system1.GetName()+"..."		
	system1.populate()		
	
	Return system1.getMainStar()	
End Function
