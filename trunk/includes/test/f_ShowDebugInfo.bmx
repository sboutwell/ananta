Function ShowDebugInfo()
	' *********** DEBUG INFO ****************
	G_debugWindow.addText("FPS: " + G_timer.GetFPS()) 
	'G_debugWindow.AddText("Asteroids: " + TAsteroid.g_nrAsteroids) 
	'G_debugWindow.AddText("Ships: " + TShip.g_nrShips) 
	
	If G_Player.GetControlledShip() Then
		G_debugWindow.AddText("Velocity: " + G_Player.GetControlledShip().GetVel()) 
		If G_Player.GetControlledShip().isWarpDriveOn Then
			G_debugWindow.AddText("(warpdrive on)") 
		End If
		G_debugWindow.AddText("Shields: " + G_Player.GetControlledShip().GetIntegrity()) 
		'G_Player.GetControlledShip().CalcStopDistance()
	EndIf
	' ***************************************
	
	G_debugWindow.addText("**** GCMemAlloced: " + GCMemAlloced())
	G_debugWindow.addText("Ships: " + TShip.g_nrShips)
	G_debugWindow.addText("Components: " + TComponent.g_nrComponents)
	G_debugWindow.addText("Slots: " + TSlot.g_nrSlots)
End Function
