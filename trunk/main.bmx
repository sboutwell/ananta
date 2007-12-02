SuperStrict
Import bah.Libxml		' the open-source XML parser library

SetGraphicsDriver GLMax2DDriver() 

Include "includes/i_constants.bmx"					'Global constants. All constants must begin with C_
Include "includes/i_globals.bmx"					'Global variables and types. All globals must begin with G_
Include "includes/functions/f_XMLfunctions.bmx"		'Functions related to XML loading, parsing and searching
Include "includes/functions/f_mathfunctions.bmx"	'General math related functions
Include "includes/functions/f_stringfunctions.bmx"	'Functions related to string manipulation

' Type definitions
Include "includes/types/i_typeSpaceObjects.bmx"			'All spaceborne objects
Include "includes/types/i_typePilot.bmx"				'Pilot entities and methods for AI routines
Include "includes/types/i_typeViewport.bmx"				'Draw-to-screen related stuff
Include "includes/types/i_typeCommodity.bmx"			'Tradeable/usable commodities (contents read from an xml file)
Include "includes/types/i_typeMessageWindow.bmx"		'Messagewindow and messageline types
Include "includes/types/i_typeShipModel.bmx"			'Type describing ship models
Include "includes/types/i_typeMisc.bmx"					'Miscellaneous type definitions
Include "includes/types/i_typeDelta.bmx"				'Delta timer

AutoImageFlags MASKEDIMAGE | FILTEREDIMAGE | MIPMAPPEDIMAGE	' flags For LoadImage()

TColor.LoadAll()  					' load all color info from colors.xml (must be loaded before initializing the viewport)
viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
TShipModel.LoadAll()  				' load and parse the contents of shipmodels.xml
'End


LoadMedia()	' temporary function

' generate a sector
Local sector1:TSector = TSector.Create(0,0,"Sol")
Local activeSector:TSector = sector1 ' set the newly created sector as the "active sector"

'Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
Local pl2:TPlanet = TPlanet.Create(0, 0, sector1, 60000000, 10, "Jupiter") 
pl2._image=G_media_jupiter
pl2._rotation=-90
pl2._scaleX = 1
pl2._scaleY = 1

Local pl1:TPlanet = TPlanet.Create(3000, 0, sector1, 15000000, 2000, "Neptune") 
pl1._image = G_media_jupiter
pl1._rotation = -90
pl1._scaleX = 0.5
pl1._scaleY = 0.5

' generate the player and player's ship
Local p1:TPlayer = TPlayer.Create("Da Playah") 
Local s1:TShip = TShipModel.BuildShipFromModel("nadia") 
s1.SetName("Player ship")
s1.SetSector(sector1) 
s1.SetCoordinates(500, 0) 
' assign the ship for the player to control
s1.AssignPilot(p1) 

viewport.CreateMsg("Total ship mass: " + s1.GetMass()) 

' set up bunch of AI pilots for testing
rem
For Local i:Int = 1 To 100
	Local ai:TAIPlayer = TAIPlayer.Create("Da AI Playah") 
	Local ship:TShip = TShipModel.BuildShipFromModel("olympus") 
	ship.SetSector(sector1) 
	ship.SetCoordinates(Rand(- 1000, 1000), Rand(- 1000, 1000)) 
	'ship.SetCoordinates (600, 0) 
	ship.AssignPilot(ai) 	
	ai.SetTarget(s1) 
Next
endrem

viewport.CenterCamera(s1)         		' select the player ship as the object for the camera to follow

' Main loop
While Not KeyHit(KEY_ESCAPE) 
	G_delta.Calc() 
	' checks for keypresses (or other control inputs) and applies them to the player's controlled ship
	p1.GetInput()
	
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

	' draw miscellaneous viewport items needed to be on top (HUD, messages etc)
	viewport.DrawMisc() 
	G_delta.LimitFPS()  ' a deltatimer delay to limit FPS
	Flip(1) 
	Cls

Wend

' LoadMedia is a temporary function. Will be replaced by a type function reading all values from an XML file
Function LoadMedia()
	AutoMidHandle True
	SetRotation 0  
	SetScale(1,1) 
	G_media_jupiter = LoadImage("media/jupiter.png") 

EndFunction
