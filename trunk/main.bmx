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

TColor.LoadAll()      				' load all color info from colors.xml (must be loaded before initializing the viewport)
viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
TShipModel.LoadAll()  				' load and parse the contents of shipmodels.xml

GenerateVectorTextures()    		' generate some vector textures as new image files

G_Universe = TUni.Create()
G_Universe.LoadGalaxy(TMedia.g_mediaPath + "galaxy.png")	' load and parse the galaxy image for universe creation

SetupTestEnvironment()		' create the player, and a test system with some planets, asteroids and AI ships


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
		If G_Player.GetControlledShip()._isJumpDriveOn Then
			G_debugWindow.AddText("(jumprive on)") 
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
	TImg.StoreImg(TStar.GenerateStarTexture(1024) , "star_generated") 
End Function

Function GenerateTestSystem:TStar(sSize:Long) 
	Local asteroids:Int = 30
	Local planets:Int = 10
	
	' generate a system
	Local system1:TSystem = TSystem.GetActiveSystem()

	' ================ randomize System and planetary object for testing ===================
	'SeedRnd(MilliSecs()) 
	' create a star
	Local st1:TStar = TStar.Create(0, 0, System1, 1000000, 5, "Sol") 
	st1._image = TImg.LoadImg("star_generated") 
	st1._rotation = -90
	st1._scaleX = 20
	st1._scaleY = st1._scaleX
	st1._size = CalcImageSize(st1._image, False) * st1._scaleX
	st1._mass = (st1._scaleX ^ 2) * 2000000000
	
	system1._mainStar = st1
	
	' create some planets
	For Local i:Int = 1 To planets
		'Function Create:TPlanet(x:Int,y:Int,System:TSystem,mass:Long,size:Int,name:String)
		Local pl2:TPlanet = TPlanet.Create(Rand(- sSize, sSize), Rand(- sSize, sSize), System1, 100000, 10, "Jupiter " + i) 
		
		' Re-randomize the coordinates if the planet is too close to the sun 
		Local again:Int = False
		Repeat
			If Distance(st1.GetX(), st1.GetY(), pl2.GetX(), pl2.GetY()) < st1.GetSize() * 2 Then
				pl2.SetX(Rand(-sSize,sSize))
				pl2.SetY(Rand(-sSize,sSize))
				again = True
				DebugLog("Planet " + i + " too close to the sun, repositioning...")
			Else
				again = False
			EndIf
		Until again = False
		
		pl2._image = TImg.LoadImg("jupiter.png") 
		pl2._rotation=-90
		pl2._scaleX = Rnd(0.5, 2) 
		pl2._scaleY = pl2._scaleX
		pl2._size = CalcImageSize(pl2._image, False) * pl2._scaleX
		pl2._mass = (pl2._scaleX ^ 2) * Rand(200000000, 400000000) 
		pl2._hasGravity = True
	Next
	
	' create some asteroids
	For Local i:Int = 1 To asteroids
		Local scale:Float = Rnd(0.3, 2) 
		Local size:Int = CalcImageSize(TImg.LoadImg("asteroid.png"), False) * scale
		Local mass:Long = (scale ^ 2) * Rand(3000, 10000) 
		
		Local ast:TAsteroid = TAsteroid.Create("asteroid.png", System1, Rand(- sSize, sSize), Rand(- sSize, sSize), mass) 
		ast._scaleX = scale
		ast._scaleY = scale
		ast._size = size
		ast.SetRotationSpd(Rand(- 200, 200)) 
		'Make the asteroid orbit the sun
		ast.SetOrbitalVelocity(st1, Rand(0, 1)) 

	Next
	
	Return st1
End Function

Function SetupTestEnvironment()
	'Local sectX:Int = 16
	'Local sectY:Int = 16
	Local sectX:Int = 5793
	Local sectY:Int = 5649
	
	' make sure the starting sector has at least 1 star in it...
	Local sect:TSector
	sect = TSector.Create(sectX, sectY)
	sect.Populate()
	
	'DebugLog(sect._L_systems.Count() + " systems")
	
	Local system:TSystem = TSystem(sect._L_systems.ValueAtIndex(1))
	system.SetAsActive()
	
	' now the last system of the generated sector should be "active"
	
	'Local sSize:Long = 148000000:Long	' real solar system size
	'Local sSize:Long = 300000000:Long
	Local sSize:Long = 500000:Long
	Local centralStar:TStar = GenerateTestSystem(sSize) 
	
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
	s1.SetSystem(TSystem.GetActiveSystem()) 
	s1._rotation = 90
	' assign the ship for the player to control
	s1.AssignPilot(G_Player) 
	
	
	' find the farthest planet to the center and make the player ship orbit it
	Local orbitedPlanet:TStellarObject
	Local maxDist:Double = 0
	For Local obj:TStellarObject = EachIn TStellarObject.g_L_StellarObjects
		Local dist:Double = Distance(0, 0,obj.GetX(),obj.GetY())
		If TPlanet(obj) And dist > maxDist Then
			orbitedPlanet = obj
			maxDist = dist
		EndIf
	Next
	s1.SetCoordinates(orbitedPlanet.GetX() + OrbitedPlanet.GetSize() * 0.7, orbitedPlanet.GetY()) 
	s1.SetOrbitalVelocity(orbitedPlanet, True) 
	
	' Create one asteroid to orbit the same planet as the player
	Local ascale:Float = orbitedPlanet.GetScaleX() 
	Local asize:Int = CalcImageSize(TImg.LoadImg("asteroid.png"), False) * ascale
	Local amass:Long = (ascale ^ 2) * Rand(3000, 10000) 
	Local ast:TAsteroid = TAsteroid.Create("asteroid.png", TSystem.GetActiveSystem(), Rand(- sSize, sSize), Rand(- sSize, sSize), amass) 
	ast._scaleX = ascale
	ast._scaleY = ascale
	ast._size = asize
	ast.SetRotationSpd(Rand(- 50, 50)) 
	ast.SetX(orbitedPlanet.GetX() + orbitedPlanet.GetSize() * Rnd(0.75, 1.1)) 
	ast.SetY(orbitedPlanet.GetY() + orbitedPlanet.GetSize() * Rnd(0.75, 1.1)) 
	ast.SetOrbitalVelocity(orbitedPlanet,True)
	ast = Null
	
	'Local part1:TParticleGenerator = TParticleGenerator.Create("trail.png", 0, 0, TSystem.GetActiveSystem(), 0.1, 0.3, 400, 0.07) 
	'part1.SetRandomDir(2) 
	's1.AddAttachment(part1, - 28, 0, 0, False) 
	
	'TAttachment.Create(s1, "attach.png", - 10, 10, 0, 0.1, 0.1, False) 
	
	viewport.CreateMsg("Total ship mass: " + s1.GetMass()) 
	's1.SetCoordinates(100000,100000)
	' set up bunch of AI pilots
	
	For Local i:Int = 1 To 25
		Local ai:TAIPlayer = TAIPlayer.Create("Da AI Playah") 
		Local ship:TShip = TShipModel.BuildShipFromModel("olympus") 
		ship.SetSystem(TSystem.GetActiveSystem()) 
		ship.SetCoordinates(Rand(- sSize, sSize), Rand(- sSize, sSize)) 
		'ship.SetCoordinates (600, 0)
		ship.AssignPilot(ai) 
		ai.SetTarget(s1)		' make the AI ship try to point at the player ship
		'ship._xVel = Rand(- 100, 100) 
		'ship._yVel = Rand(- 100, 100) 
		ship.SetOrbitalVelocity(centralStar, Rand(0, 1) )
	Next
	
	viewport.CenterCamera(s1)           		' select the player ship as the object for the camera to follow
End Function