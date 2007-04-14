Rem
	Naming convention:
	-	All types are named with a T in front (example: TTypeName)
	-	All lists and fields that are global inside a type must begin with g (example: Global g_variableName)
		Note a lower case g as opposed to the capital G for program globals.
	-	All lists are named with L in front of them (example L_ListName)
	
	You can capitalize fields, types and lists as needed for good readability. Use your own judgement.
	
	Thoroughly comment all type definitions, explain their usage and their methods and fields.
	
	Have fun.
EndRem

' -----------------------------------------------------------------
' MISCELLANEOUS TYPE DEFINITIONS
' -----------------------------------------------------------------

' TSector represents a star system
Type TSector Final
	Global g_L_Sectors:TList					' a list to hold all sectors
	Field name:String							' Name of the sector
	Field x:Int,y:Int							' Sector's x-y-coordinates in the galaxy map
	Field L_SpaceObjects:TList					' a list to hold all TSpaceObjects in this sector

	Method DrawAllInSector(viewport:TViewport)
		If Not L_SpaceObjects Return													' Exit if a body list doesn't exist
		For Local body:TSpaceObject = EachIn L_SpaceObjects	' Iterate through each drawable object in the sector
			body.DrawBody(viewport) 															' Calls the DrawBody method of each drawable object in the sector
		Next
	EndMethod

	Function Create:TSector(x:Int,y:Int,name:String)
		Local se:TSector = New TSector								' create an instance of the sector
		se.name = name																			' give a name to the sector
		se.x = x	; se.y = y																' give the coordinates in the galaxy
		If Not g_L_Sectors Then g_L_Sectors = CreateList()	' create a list to hold the sectors (if not already created)
		g_L_Sectors.AddLast se																	' add the newly created sector to the end of the list
		Return se																										' return the pointer to this specific object instance
	EndFunction
EndType

' TSlot is a special "container" in a ship hull that holds other ship parts. 
' Slots are created when a new ship (hull) is created.
' See i_typeCommodity_Shippart.bmx
Type TSlot Final
	Field id:String
	'Field slottype:String		' type of the slot (rotthruster, thruster, engine, equipment)
	Field volume:Float			' volume of the slot in m^3
	Field L_parts:TList			' list to hold all ship parts in this slot
	Field location:String		' the location of the slot (internal, external). Internal takes less damage.
	Field exposedDir:String		' NULL if the slot is not exposed to space, otherwise dir = left, right, nose or tail)
								' Thrusters and engines need to have exposure! Also, weapons in the future need exposure.
								' Exposed slots take even more damage than external!
	Function Create:TSlot(idString:String)
		Local s:TSlot = New TSlot						' create an instance
		s.id = idString									' give an ID
		Return s										' return the pointer to this specific object instance
	EndFunction									
EndType

' TComponent is an actual created ship part. It has additional fields for upgrades and damage.
Type TComponent Final
	Field ShipPart:TShippart 	' the ship part prototype this Component is based on
	Field L_Upgrades:TList		' a list holding possible upgrades
	Field damage:Float			' damage sustained by this component
	
	Function Create:TComponent(SPart:TShipPart)
		Local c:TComponent = New TComponent
		c.ShipPart = SPart
		c.damage = 0
	End Function
End Type
