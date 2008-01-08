rem
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

' TSector represents a star system
Type TSector Final
	Global g_L_Sectors:TList					' a list to hold all sectors
	Field _name:String							' Name of the sector
	Field _x:Int,_y:Int							' Sector's x-y-coordinates in the galaxy map
	Field _L_SpaceObjects:TList					' a list to hold all TSpaceObjects in this sector

	Method DrawAllInSector(vp:TViewport)
		If Not _L_SpaceObjects Return							' Exit if a body list doesn't exist
		For Local obj:TSpaceObject = EachIn _L_SpaceObjects	' Iterate through each drawable object in the sector
			obj.DrawBody(vp)     						' Calls the DrawBody method of each drawable object in the sector
			If vp.GetMiniMap() And obj.showsOnMap() Then	' draw a minimap blip if minimap is defined for the viewport
				vp.GetMiniMap().AddBlip(obj)
			End If
		Next
	EndMethod

	Method AddSpaceObject(obj:TSpaceObject)
		If Not _L_SpaceObjects Then _L_SpaceObjects = CreateList()	' create a list if necessary
		_L_SpaceObjects.AddLast obj
	EndMethod

	
	Function Create:TSector(x:Int,y:Int,name:String)
		Local se:TSector = New TSector								' create an instance of the sector
		se._name = name																			' give a name to the sector
		se._x = x	; se._y = y																' give the coordinates in the galaxy
		If Not g_L_Sectors Then g_L_Sectors = CreateList()	' create a list to hold the sectors (if not already created)
		g_L_Sectors.AddLast se																	' add the newly created sector to the end of the list
		Return se																										' return the pointer to this specific object instance
	EndFunction
EndType
