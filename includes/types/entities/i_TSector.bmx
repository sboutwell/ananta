' TSector represents a star system
Type TSector Final
	Global g_L_Sectors:TList					' a list to hold all sectors
	Field _name:String							' Name of the sector
	Field _x:Int,_y:Int							' Sector's x-y-coordinates in the galaxy map
	Field _L_SpaceObjects:TList					' a list to hold all TSpaceObjects in this sector

	Method DrawAllInSector(vp:TViewport)
		If Not _L_SpaceObjects Return													' Exit if a body list doesn't exist
		For Local body:TSpaceObject = EachIn _L_SpaceObjects	' Iterate through each drawable object in the sector
			body.DrawBody(vp)   															' Calls the DrawBody method of each drawable object in the sector
			If vp.GetMiniMap() Then	' draw a minimap blip if minimap is defined for the viewport
				vp.GetMiniMap().AddBlip(body) 
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
