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
	Field _name:String							' Name of the sector
	Field _x:Int,_y:Int							' Sector's x-y-coordinates in the galaxy map
	Field _L_SpaceObjects:TList					' a list to hold all TSpaceObjects in this sector

	Method DrawAllInSector(vp:TViewport)
		If Not _L_SpaceObjects Return													' Exit if a body list doesn't exist
		For Local body:TSpaceObject = EachIn _L_SpaceObjects	' Iterate through each drawable object in the sector
			body.DrawBody(vp) 															' Calls the DrawBody method of each drawable object in the sector
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

' TSlot is a special "container" in a ship hull that holds other ship parts. 
' Slots are created when a new ship (hull) is created.
' See i_typeCommodity_Shippart.bmx
Type TSlot Final
	Field _id:String
	'Field _slottype:String		' type of the slot (rotthruster, thruster, engine, equipment)
	Field _volume:Float			' volume of the slot in m^3
	Field _L_parts:TList			' list to hold all ship parts in this slot
	Field _location:String		' the location of the slot (internal, external). Internal takes less damage.
	Field _exposedDir:String		' NULL if the slot is not exposed to space, otherwise dir = left, right, nose or tail)
								' Thrusters and engines need to have exposure! Also, weapons in the future need exposure.
								' Exposed slots take even more damage than external!
								
	Method GetPartList:TList()
		Return _L_parts
	End Method
	
	Method GetID:String()
		Return _id
	End Method
	
	Method GetVolume:Float()
		Return _volume
	End Method

	Method GetLocation:String()
		Return _location
	End Method

	Method GetExposedDir:String()
		Return _exposedDir
	End Method

	Method SetVolume(fl:float)
		_volume = fl
	End Method

	Method SetLocation(fl:String)
		_location = fl
	End Method

	Method SetExposedDir(fl:String)
		_exposedDir = fl
	End Method
	
	Function Create:TSlot(idString:String)
		Local s:TSlot = New TSlot						' create an instance
		s._id = idString									' give an ID
		Return s										' return the pointer to this specific object instance
	EndFunction									
EndType

' TComponent is an actual created ship part. It has additional fields for upgrades and damage.
Type TComponent
	Field _ShipPart:TShippart 	' the ship part prototype this Component is based on
	Field _L_Upgrades:TList		' a list holding possible upgrades
	Field _damage:Float			' damage sustained by this component
	
	Method GetShipPartMass:Float()
		Return _ShipPart.GetMass()
	End Method
	
	Function Create:TComponent(SPart:TShipPart)
		Local c:TComponent = New TComponent
		c._ShipPart = SPart
		c._damage = 0
		Return c
	End Function
End Type

Type TCompPropulsion Extends TComponent Final

End Type


' TColor is a type handling mapping of named colors (colors.xml) into their equivalent RGB values
Type TColor Final
	Global g_L_Colors:TList ' list containing all colors
	Field _name:String		' name of the color
	Field _red:Int			' red component
	Field _green:Int			' green component
	Field _blue:Int			' blue component

	Method GetRed:Int()
		Return _red
	End Method
	Method GetGreen:Int()
		Return _green
	End Method
	Method GetBlue:Int()
		Return _blue
	End Method
	
	' SetTColor() is a SetColor replacement that uses named colors instead of RGB values
	Function SetTColor(color:TColor)
		SetColor(color._red,color._green,color._blue)
		Return
	End Function

	' FindColor takes the color name as a search string and returns the matching TColor object
	' FindColor is a relatively slow function, so don't call it in the main loop
	Function FindColor:TColor(colorname:String) 
		If Not g_L_Colors Then Print "FindColor: no colors defined" ; Return Null	' return if the list is empty
		
		For Local color:TColor = EachIn g_L_Colors
			If color._name = colorname Then Return color	' Matching color found, return the object
		Next

		Print "FindColor: no color matching the name '" + colorname + "' found"
		Return Null
	End Function

	
	' LoadAll() parses colors.xml and creates a TColor type instance for each color found in the file
	Function LoadAll() 
		If G_Debug Then Print "    Loading color info..."
		Local colornode:TxmlNode = LoadXMLFile(c_colorsFile)
		' ------------------------------------------------------------------------------------
		' Creating instance of each found color
		' ------------------------------------------------------------------------------------
		Local children:TList = colornode.getChildren() 			' get all color names
		For colornode = EachIn children							' iterate through colors
			'Print "      Color found: " + colornode.GetName()
			Local color:TColor = TColor.Create(colornode.GetName())	' create a color prototype instance
			
			Local colorChildren:TList = colornode.getChildren()
			' search the color node to find RGB info and save them into fields
			For Local value:TxmlNode = EachIn colorChildren	' iterate through values
				If value.GetName() = "r" Then color._red	= value.GetText().ToInt()
				If value.GetName() = "g" Then color._green 	= value.GetText().ToInt()
				If value.GetName() = "b" Then color._blue	= value.GetText().ToInt()
			Next
		Next
		If G_Debug Then Print "    Colors loaded."
		Return
	EndFunction

	Function Create:TColor(colorname:String)
		Local c:TColor = New TColor ' create an instance
		c._name = colorname			' give a name

		If Not g_L_Colors Then g_L_Colors = CreateList()	' create a list if necessary
		g_L_Colors.AddLast c	' add the newly created object to the end of the list
		
		Return c	' return the pointer to this specific object instance
	End Function

End Type
