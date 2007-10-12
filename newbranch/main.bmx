SuperStrict
Import BaH.Libxml		' the open-source XML parser library

Include "includes\i_constants.bmx"					'Global constants. All constants must begin with C_
Include "includes\i_globals.bmx"					'Global variables and types. All globals must begin with G_
Include "includes\functions\f_XMLfunctions.bmx"		'Functions related to XML loading, parsing and searching
Include "includes\functions\f_mathfunctions.bmx"	'General math related functions
Include "includes\functions\f_stringfunctions.bmx"	'Functions related to string manipulation

' Type definitions
Include "includes\types\i_typeSpaceObjects.bmx"			'All spaceborne objects
Include "includes\types\i_typePilot.bmx"				'Pilot entities and methods for AI routines
Include "includes\types\i_typeViewport.bmx"				'Draw-to-screen related stuff
Include "includes\types\i_typeCommodity.bmx"			'Tradeable/usable commodities (contents read from an xml file)
Include "includes\types\i_typeMessageWindow.bmx"		'Messagewindow and messageline types
Include "includes\types\i_typeMisc.bmx"					'Miscellaneous type definitions

AutoImageFlags MASKEDIMAGE|FILTEREDIMAGE|MIPMAPPEDIMAGE	' flags for LoadImage()

TColor.LoadAll()					' load all color info from colors.xml (must be loaded before initializing the viewport)
viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
'End


LoadMedia()	' temporary function

' generate a sector
Local sector1:TSector = TSector.Create(0,0,"Sol")
Local activeSector:TSector = sector1 ' set the newly created sector as the "active sector"

'Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
Local pl2:TPlanet = TPlanet.Create(-600,-100,sector1,100,10,"Jupiter")
pl2._image=G_media_jupiter
pl2._rotation=-90
pl2._scaleX = 1
pl2._scaleY = 1
pl2._size = 100

' generate the player and player's ship
Local p1:TPlayer = TPlayer.Create("Da Playah")
Local s1:TShip = TShip.Create(500,0,"samplehull2",sector1,"Da Ship")


' ******* test to load up some equipment into slots ******
Local engine:TPropulsion = TPropulsion.FindEngine("trilliumengine1")    ' find and Return the specs of "trilliumengine1" into a Type variable
Local component:TComponent = TComponent.Create(engine)   ' create an actual component based on the specs saved in the type variable
s1.AddComponentToSlotID(component, "engineslot1") 
engine:TPropulsion = TPropulsion.FindEngine("trilliumthruster1") 
component:TComponent = TComponent.Create(engine) 
s1.AddComponentToSlotID(component, "rightrotthruster") 
component:TComponent = TComponent.Create(engine) 
s1.AddComponentToSlotID(component, "leftrotthruster") 
' ********************************************************

s1.PreCalcPhysics() 

viewport.CenterCamera(s1)		' select the player ship as the object for the camera to follow

' assign the ship for the player to control
s1.AssignPilot(p1)


' set up an AI pilot for testing
Local ai1:TAIPlayer = TAIPlayer.Create("Da AI Playah")
Local s2:TShip = TShip.Create(1000,50,"samplehull2",sector1,"AI ship")
s2._rotation=180
s2.AssignPilot(ai1)
s2._engineThrust = 25000
s2._rotThrust = 45000
s2.PreCalcPhysics()
' make the player ship as the target ship for the AI
ai1.SetTarget(s1) 

viewport.CreateMsg("Total ship mass: " + s1.GetMass()) 

' Main loop
While Not KeyHit(KEY_ESCAPE)
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
	
	'Flip(0) 
	Flip
	Cls
	'	GCCollect() ' Garbage collection
	
Wend

' LoadMedia is a temporary function. Will be replaced by a type function reading all values from an XML file
Function LoadMedia()
	AutoMidHandle True
	SetRotation 0  
	SetScale(1,1) 
	G_media_jupiter = LoadImage("media/jupiter.png") 

EndFunction
