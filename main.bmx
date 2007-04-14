SuperStrict
Import BaH.Libxml		' the open-source XML parser library

Include "includes\i_constants.bmx"					'Global constants. All constants must begin with C_
Include "includes\i_globals.bmx"					'Global variables. All globals must begin with G_
Include "includes\functions\f_parseXMLDoc.bmx"		'Function that loads, parses an returns and XML file for processing
Include "includes\functions\f_xmlGetNode.bmx"		'Function that searches and returns a specified child under a specified node
Include "includes\functions\f_xmlFindValues.bmx"	'Functions that do XML file searching using X-Path standard
Include "includes\functions\f_mathfunctions.bmx"	'General math related functions

' Type definitions
Include "includes\types\i_typeSpaceObjects.bmx"			'All spaceborne objects
Include "includes\types\i_typePilot.bmx"				'Pilot entities and methods for AI routines
Include "includes\types\i_typeViewport.bmx"				'Draw-to-screen related stuff
Include "includes\types\i_typeCommodity.bmx"			'Tradeable/usable commodities (contents read from an xml file)
Include "includes\types\i_typeMisc.bmx"					'Miscellaneous type definitions

AutoImageFlags MASKEDIMAGE|FILTEREDIMAGE|MIPMAPPEDIMAGE	' flags for LoadImage()

TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml

'End

' create the screen and initialize the graphics mode
Local viewport:TViewport = TViewport.Create()
viewport.InitViewportVariables()
TViewport.InitGraphicsMode()

LoadMedia()

' generate a sector
Local sector1:TSector = TSector.Create(0,0,"Sol")
Local activeSector:TSector = sector1 ' set the newly created sector as the "active sector"

'Function Create:TPlanet(x:Int,y:Int,sector:TSector,mass:Long,size:Int,name:String)
Local pl2:TPlanet = TPlanet.Create(-600,-100,sector1,100,10,"Jupiter")
pl2.image=G_media_jupiter
pl2.rotation=-90
pl2.scaleX = 2
pl2.scaleY = 2
pl2.size = 100

' generate the player and player's ship
Local p1:TPlayer = TPlayer.Create("Da Playah")
Local s1:TShip = TShip.Create(500,0,"samplehull1",sector1,"Da Ship")

's1.mass = s1.hull.mass
's1.engineThrust = 25000

' ******** test to load up some equipment into slots ******
For Local eSlot:TSlot = EachIn s1.hull.L_engineSlots
	Local engine:TPropulsion = TPropulsion.FindEngine("trilliumengine1")
	Local component:TComponent = TComponent.Create(engine)
	
	If Not eSlot.L_parts Then eSlot.L_parts = CreateList()
	eSlot.L_parts.AddLast component
Next
' ********************************************************

s1.rotThrust = 4500
s1.PreCalcPhysics()

' assign the ship for the player to control
s1.AssignPilot(p1)

Rem 
Local ai1:TAIPlayer = TAIPlayer.Create("Da AI Playah")
Local s2:TShip = TShip.Create(1000,50,"samplehull2",sector1,"AI ship")
s2.rotation=180
' assign the ship for the AI player to control
s2.AssignPilot(ai1)
' make the player ship as the target ship for the AI
ai1.targetObject = s1
s2.mass = s2.hull.mass
s2.engineThrust = 25000
s2.rotThrust = 45000
s2.PreCalcPhysics()
EndRem

' Main loop
While Not KeyHit(KEY_ESCAPE)
	' checks for keypresses (or other control inputs) and applies them to the player's controlled ship
	p1.GetInput()
	
	If TAIPlayer.g_L_AIPilots Then
		For Local ai:TAIPlayer = EachIn TAIPlayer.g_L_AIPilots
			ai.Think()  ' the main AI routine
		Next
	EndIf

	' update the positions of every moving object (except ships), including the ones in other sectors
	TMovingObject.UpdateAll()

	' update the positions of every ship and calculate fuel and oxygen consumption
	TShip.UpdateAll()

	' draw the level centered to the player's controlled ship
	viewport.DrawLevel(p1.ControlledShip)
	
	' draw each object in the currently active sector
	activeSector.DrawAllInSector(viewport)

	Flip;Cls
	'	GCCollect() ' Garbage collection
	
Wend

' LoadMedia is a temporary function. Will be replaced by a type function reading all ship part values from an XML files
Function LoadMedia()
	AutoMidHandle True
	SetRotation 0  
	SetScale(1,1) 
	G_media_jupiter 	= LoadImage("media/jupiter.png")

EndFunction
