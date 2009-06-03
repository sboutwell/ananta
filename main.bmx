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

' Temporary includes for development
Include "includes/test/f_setupTestEnvironment.bmx"
Include "includes/test/f_showDebugInfo.bmx"

TColor.LoadAll()      				' load all color info from colors.xml (must be loaded before initializing the viewport)
G_viewport.InitViewportVariables() 	' load various viewport-related settings from settings.xml and precalc some other values
TViewport.InitGraphicsMode()		' lets go graphical using the values read from the xml file
TCommodity.LoadAllCommodities()		' load and parse the contents of commodities.xml
TShipModel.LoadAll()  				' load and parse the contents of shipmodels.xml
TProtoBody.LoadAllProtoBodies()		' load all the sun/planet prototypes from the celestialtypes.xml

TStar.GenerateVectorTextures()    	' generate some vector star textures as new image files

G_Universe = TUni.Create()
G_Universe.LoadGalaxy(TMedia.g_mediaPath + "galaxy.png")	' load and parse the galaxy image for universe creation

SetupTestEnvironment()

G_t = MilliSecs() ' fixed rate timer
' Main loop
While Not KeyHit(KEY_ESCAPE) And Not AppTerminate() 
	' calculate the deltatimer (alters global variable G_delta)
	G_delta.Calc() 
	
	' checks for keypresses (or other control inputs) and applies their actions
	G_player.GetInput()

	' Update every AI pilot and apply their control inputs to their controlled ships
	TAIPlayer.UpdateAllAI() 
	
	' fixed update loop
	While G_execution_time >= G_timestep

		' update the positions of every moving object (except ships)
		If Not G_delta.isPaused Then TMovingObject.UpdateAll() 

		' update the positions of every ship
		If Not G_delta.isPaused Then TShip.UpdateAll()

		' update particles 
		If Not G_delta.isPaused Then TParticle.UpdateAll()

		G_execution_time:- G_timestep
	Wend

	' calculate the remainder for tweening
	G_tween = G_execution_time / G_timestep

	' draw the level
	G_viewport.DrawLevel()
	 
	' draw each object in the currently active System
	TSystem.GetActiveSystem().DrawAllInSystem(G_viewport) ' seeing as G_viewport is a global, do we really need to pass it?

	' draw miscellaneous viewport items needed to be on top (HUD, messages etc)
	G_viewport.DrawMisc() 
	
	ShowDebugInfo()
	
	If G_delta._isFrameRateLimited Then
		G_delta.LimitFPS()        ' limit framerate
		Flip(1) 
	Else
		Flip(0) 
	EndIf
	
	
	' clear the whole viewport backbuffer
	SetViewport(0,0,G_viewport.GetResX(),G_viewport.GetResY())
	Cls
Wend
