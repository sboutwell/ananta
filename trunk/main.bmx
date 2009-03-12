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

SuperStrict
Framework brl.glmax2d
?win32
Import brl.d3d7max2d
?
Import brl.standardio
Import brl.jpgloader
Import brl.pngloader
Import brl.linkedlist
Import brl.Pixmap
Import brl.math
Import brl.freetypefont

' Brucey's modules
Import bah.Libxml		' XML parser library wrapper for BlitzMax by Bruce A. Henderson
Import bah.Cairo		' vector graphics library wrapper for BlitzMax by Bruce A. Henderson
Import bah.random		' SFMT pseudo-random number generator wrapper for consistent galaxy creation

AppTitle = "Ananta"
Include "includes/i_constants.bmx"						'Global constants. All constants must begin with C_
Include "includes/i_globals.bmx"						'Global variables and types. All globals must begin with G_
Include "includes/functions/f_XMLfunctions.bmx"			'Functions related to XML loading, parsing and searching
Include "includes/functions/f_mathfunctions.bmx"		'General math related functions
Include "includes/functions/f_stringfunctions.bmx"		'Functions related to string manipulation
Include "includes/functions/f_graphicsFunctions.bmx"	'Graphics-related functions

' Type definitions
Include "includes/types/entities/i_TPilot.bmx"			'Pilot entities and methods for AI routines
Include "includes/types/entities/i_TSystem.bmx"			'A solar system
Include "includes/types/entities/i_TUni.bmx"			'The galaxy and sectors
Include "includes/types/entities/i_TSpaceObjects.bmx"	'All spaceborne objects and their drawing
Include "includes/types/entities/i_TProtoBody.bmx"		'TStar & TPlanet prototypes from XML files

Include "includes/types/entities/i_TShipModel.bmx"		'Type describing ship models
Include "includes/types/commodity/i_TCommodity.bmx"		'Tradeable/usable commodities (contents read from an xml file)
Include "includes/types/graphics/i_TViewport.bmx"		'Draw-to-screen related stuff
Include "includes/types/graphics/i_TMessageWindow.bmx"	'Messagewindow and messageline types
Include "includes/types/graphics/i_TDebugWindow.bmx"	'Debugwindow and debugline types
Include "includes/types/graphics/i_TMinimap.bmx"		'Minimap
Include "includes/types/graphics/i_TSystemMap.bmx"		'System map extended of TMinimap
Include "includes/types/graphics/i_TStarMap.bmx"		'Star map extended of TMinimap
Include "includes/types/graphics/i_TColor.bmx"			'A structure-like type to map color names to their RGB values
Include "includes/types/graphics/i_TMedia.bmx"			'Type that loads and holds media files
Include "includes/types/i_TDelta.bmx"					'Delta timer
Include "includes/types/math/i_TValue.bmx"				'Scalars and units (distance, mass, etc)


TColor.LoadAll()      				' load all color info from colors.xml (must be loaded before initializing the viewport)
viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
TShipModel.LoadAll()  				' load and parse the contents of shipmodels.xml
TProtoBody.LoadAllProtoBodies()		' load all the sun/planet prototypes from the celestialtypes.xml

GenerateVectorTextures()    		' generate some vector textures as new image files

G_Universe = TUni.Create()
G_Universe.LoadGalaxy(TMedia.g_mediaPath + "galaxy.png")	' load and parse the galaxy image for universe creation



' param, setup
' use =0 to try envionment with planets and manual system creation
' use =1 to try system.populate()

SetupTestEnvironment()



' Main loop
While Not KeyHit(KEY_ESCAPE) And Not AppTerminate() 
	' calculate the deltatimer (alters global variable G_delta)
	G_delta.Calc() 
	
	' checks for keypresses (or other control inputs) and applies their actions
	G_Player.GetInput()
	
	' Update every AI pilot and apply their control inputs to their controlled ships
	TAIPlayer.UpdateAllAI() 

	' update the positions of every moving object (except ships)
	TMovingObject.UpdateAll() 

	' update the positions of every ship and calculate fuel and oxygen consumption
	TShip.UpdateAll()

	' draw the level
	viewport.DrawLevel()
	
	' update and draw particles 
	TParticle.UpdateAndDrawAll()
	 
	' draw each object in the currently active System
	TSystem.GetActiveSystem().DrawAllInSystem(viewport) 

	' draw miscellaneous viewport items needed to be on top (HUD, messages etc)
	viewport.DrawMisc() 
	
	
	' *********** DEBUG INFO ****************
	G_debugWindow.AddText("FPS: " + G_delta.GetFPS()) 
	'G_debugWindow.AddText("Asteroids: " + TAsteroid.g_nrAsteroids) 
	'G_debugWindow.AddText("Ships: " + TShip.g_nrShips) 
	
	If G_Player.GetControlledShip() Then
		G_debugWindow.AddText("Velocity: " + G_Player.GetControlledShip().GetVel()) 
		If G_Player.GetControlledShip().isWarpDriveOn Then
			G_debugWindow.AddText("(warpdrive on)") 
		End If
		G_debugWindow.AddText("Shields: " + G_Player.GetControlledShip().GetIntegrity()) 
	EndIf
	' ***************************************
	
	If G_delta._isFrameRateLimited Then
		G_delta.LimitFPS()        ' limit framerate
		Flip(1) 
	Else
		Flip(0) 
	EndIf
	
	
	
	' clear the whole viewport backbuffer
	SetViewport(0,0,viewport.GetResX(),viewport.GetResY())
	Cls
Wend



' ==================================================================
' ============= temporary helper functions for development =========
' =========== to be moved or integrated somewhere else later =======
' ==================================================================
Function GenerateVectorTextures() 
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.95, 0.95, 0, 1, 1, 0.5) , "star_gen_yellow")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.45, 0.05, 0.05, 0.8, 0.3, 0.3) , "star_gen_red")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.5, 0.5, 0.5, 0.7, 0.7, 0.7) , "star_gen_silver")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.95, 0.95, 0.95, 0.7, 0.7, 0.8) , "star_gen_white")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.9, 0.6, 0.1, 0.45, 0.35, 0.05) , "star_gen_orange")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.7, 0.4, 0.15, 0.3, 0.3, 0.03) , "star_gen_brown")
	TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.3, 0.01, 0.01, 0.15, 0.01, 0.0) , "star_gen_faintred")
End Function



' new generate system test
Function GenerateTestSystem2:TStar() 
	Local system1:TSystem = TSystem.GetActiveSystem()
	
'	DebugLog "populating system "+system1.GetName()+"..."		
	system1.populate()		
	
	Return system1.getMainStar()	
End Function



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
	
	' **************************************************************
	' to see system.populate progress, use GenerateTestSystem2
	' **************************************************************
	GenerateTestSystem2()
	
	' ----------- STARMAP ----------
	Local sMap:TStarMap = viewport.GetStarMap()
	sMap.Center()	' move the starmap "camera" to the middle of the active system
	sMap.UpdateCenteredSector()
	sMap.Update()
	'sMap._isPersistent = TRUE
	' -----------------------------
	
	' generate the player and player's ship
	G_Player = TPlayer.Create("Da Playah") 
	Local s1:TShip = TShipModel.BuildShipFromModel("nadia") 
	s1.SetName("Player ship") 
	s1.SetCoordinates(50000,50000)
	s1.SetSystem(TSystem.GetActiveSystem()) 
	s1._rotation = 90
	' assign the ship for the player to control
	s1.AssignPilot(G_Player) 

	' attach a particle generator (this is to be integrated to TShip)
	Local part1:TParticleGenerator = TParticleGenerator.Create("trail.png", 0, 0, TSystem.GetActiveSystem(), 0.1, 0.3, 400, 0.07) 
	part1.SetRandomDir(2) 
	s1.AddAttachment(part1, - 28, 0, 0, False) 	
	
	'TAttachment.Create(s1, "attach.png", - 10, 10, 0, 0.1, 0.1, False) 	


	viewport.CreateMsg("Total ship mass: " + s1.GetMass()) 
	
	viewport.CenterCamera(s1)           		' select the player ship as the object for the camera to follow
End Function