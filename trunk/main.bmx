SuperStrict
Import bah.Libxml		' the open-source XML parser library

SetGraphicsDriver GLMax2DDriver() 
AppTitle = ""
Include "includes/i_constants.bmx"					'Global constants. All constants must begin with C_
Include "includes/i_globals.bmx"					'Global variables and types. All globals must begin with G_
Include "includes/functions/f_XMLfunctions.bmx"		'Functions related to XML loading, parsing and searching
Include "includes/functions/f_mathfunctions.bmx"	'General math related functions
Include "includes/functions/f_stringfunctions.bmx"	'Functions related to string manipulation

' Type definitions
Include "includes/types/entities/i_TPilot.bmx"			'Pilot entities and methods for AI routines
Include "includes/types/entities/i_TSector.bmx"			'Sector of space
Include "includes/types/entities/i_TSpaceObjects.bmx"	'All spaceborne objects
Include "includes/types/entities/i_TShipModel.bmx"		'Type describing ship models
Include "includes/types/commodity/i_TCommodity.bmx"		'Tradeable/usable commodities (contents read from an xml file)
Include "includes/types/graphics/i_TViewport.bmx"		'Draw-to-screen related stuff
Include "includes/types/graphics/i_TMessageWindow.bmx"	'Messagewindow and messageline types
Include "includes/types/graphics/i_TMinimap.bmx"		'Minimap
Include "includes/types/graphics/i_TColor.bmx"			'A structure-like type to map color names to their RGB values
Include "includes/types/graphics/i_TMedia.bmx"			'Type loading and holding media files
Include "includes/types/math/i_TCoordinate.bmx"			'Struct-like type to represent a position in 2d space
Include "includes/types/i_TDelta.bmx"					'Delta timer

TColor.LoadAll()      				' load all color info from colors.xml (must be loaded before initializing the viewport)
viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
TShipModel.LoadAll()  				' load and parse the contents of shipmodels.xml

' generate a sector
Local sector1:TSector = TSector.Create(0,0,"Sol")
Local activeSector:TSector = sector1 ' set the newly created sector as the "active sector"

' create a bunch of planets
SeedRnd(MilliSecs()) 
For Local i:Int = 1 To 100
	'Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
	Local pl2:TPlanet = TPlanet.Create(Rand(- 200000, 200000), Rand(- 200000, 200000), sector1, 100000, 10, "Jupiter " + i) 
	pl2._image = TImg.LoadImg("jupiter.png") 
	pl2._rotation=-90
	pl2._scaleX = Rnd(0.5, 2) 
	pl2._scaleY = pl2._scaleX
	pl2._size = 980 * pl2._scaleX
	pl2._mass = (pl2._scaleX ^ 2) * Rand(200000000, 350000000) 
Next

For Local i:Int = 1 To 100
	Local ast:TAsteroid = TAsteroid.Create("asteroid.png", sector1, Rand(- 200000, 200000), Rand(- 200000, 200000), Rand(10, 500)) 
	ast._scaleX = Rnd(0.1, 1.5) 
	ast._scaleY = ast._scaleX
	ast._size = 100 * ast._scaleX
	ast._mass = (ast._scaleX ^ 2) * Rand(2000, 5000) 
	ast.SetRotationSpd(Rand(- 200, 200)) 
	ast.SetXVel(Rand(- 500, 500)) 
	ast.SetYVel(Rand(- 500, 500)) 
Next

' generate the player and player's ship
Local p1:TPlayer = TPlayer.Create("Da Playah") 
Local s1:TShip = TShipModel.BuildShipFromModel("nadia") 
s1.SetName("Player ship")
s1.SetSector(sector1) 
s1.SetCoordinates(0, 0) 
' assign the ship for the player to control
s1.AssignPilot(p1) 

'Local part1:TParticleGenerator = TParticleGenerator.Create("trail.png", 0, 0, sector1, 0.1, 0.3, 400, 0.07) 
'part1.SetRandomDir(2) 
's1.AddAttachment(part1, - 28, 0, 0, False) 

'TAttachment.Create(s1, "attach.png", - 10, 10, 0, 0.1, 0.1, False) 

viewport.CreateMsg("Total ship mass: " + s1.GetMass()) 

' set up bunch of AI pilots for testing

For Local i:Int = 1 To 50
	Local ai:TAIPlayer = TAIPlayer.Create("Da AI Playah") 
	Local ship:TShip = TShipModel.BuildShipFromModel("olympus") 
	ship.SetSector(sector1) 
	ship.SetCoordinates(Rand(- 200000, 200000), Rand(- 200000, 200000)) 
	'ship.SetCoordinates (600, 0)
	ship.AssignPilot(ai) 
	ai.SetTarget(s1)
	ship._xVel = Rand(- 100, 100) 
	ship._yVel = Rand(- 100, 100) 
Next


viewport.CenterCamera(s1)           		' select the player ship as the object for the camera to follow



' Main loop
While Not KeyHit(KEY_ESCAPE) 
	' calculate the deltatimer (alters global variable G_delta)
	G_delta.Calc() 
	
	' checks for keypresses (or other control inputs) and applies their actions
	p1.GetInput()
	'part1.Emit(350) 
	
	' Update every AI pilot and apply their control inputs to their controlled ships
	TAIPlayer.UpdateAllAI() 

	' update the positions of every moving object (except ships), including the ones in other sectors
	TMovingObject.UpdateAll() 

	' update the positions of every ship and calculate fuel and oxygen consumption
	TShip.UpdateAll()

	' draw the level
	viewport.DrawLevel()
	
	' draw each object in the currently active sector
	activeSector.DrawAllInSector(viewport) 

	' update and draw particles
	TParticle.UpdateAndDrawAll() 

	' draw miscellaneous viewport items needed to be on top (HUD, messages etc)
	viewport.DrawMisc() 
	
	If G_delta._isFrameRateLimited Then
		G_delta.LimitFPS()       ' limit framerate
		Flip(1) 
	Else
		Flip(0) 
	EndIf
	
	' clear the whole viewport backbuffer
	SetViewPort(0,0,viewport.GetResX(),viewport.GetResY())
	Cls

Wend

