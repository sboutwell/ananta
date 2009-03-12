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


' ---------------------------------------------------------------------------------------
Rem
	Commodities are common tradeable and transportable items.
	There are sub-types of commodities, some of them having special characteristics, 
	ie. ship parts that can be used to build ships, fuel that can be consumed etc.
EndRem
' ---------------------------------------------------------------------------------------
Type TCommodity
	Global g_L_Commodities:TList	' a list to hold all commodities
	Field _id:String					' ID of the commodity
	Field _name:String				' name of the commodity
	Field _unit:String				' unit of measurement (piece or kg)
	Field _mass:Float  				' mass per unit
	Field _volume:Float				' volume per unit (m^3)
	Field _avgPrice:Float			' average price of the commodity (per unit)
	
	Method GetMass:Float()
		Return _mass
	End Method

	Method GetVol:Float()
		Return _volume
	End Method

	Method GetID:String()
		Return _id
	End Method

	Method GetName:String()
		Return _name
	End Method

	Method GetAvgPrice:Float()
		Return _avgPrice
	End Method

	Method GetUnit:String()
		Return _unit
	End Method
	
	Method SetMass(val:Float)
		_mass = val
	End Method
	
	Method FindCommodity:TCommodity(id:String) 
		
	End Method

	' loads all commodities from the XML file
	Function LoadAllCommodities()
	
		Local node:TxmlNode = LoadXMLFile(c_commoditiesFile)

		Local searchnode:TxmlNode ' define a node used for searching root element's child nodes
		searchnode = xmlGetNode(node, "shipparts") ' find and return the "shipparts" node
		If searchnode <> Null Then TShippart.LoadAll(searchnode)

		searchnode = xmlGetNode(node, "fuels") ' find and return the "fuels" node
		If searchnode <> Null Then TFuel.LoadAll(searchnode)

		searchnode = xmlGetNode(node, "standard") ' find and return the "standard" node
		If searchnode <> Null Then TCommodity.LoadAll(searchnode)


		If G_Debug Print "Finished reading and parsing " + c_commoditiesFile

	EndFunction
	
	' loads and parses all commodities from the xml file
	Function LoadAll(rootnode:TxmlNode)
		If G_Debug Print "    Loading standard commodities..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			If G_Debug Print "      Commodity found: " + rootnode.GetName()
			Local comm:TCommodity = TCommodity.Create(rootnode.GetName())	
			
			Local commChildren:TList = rootnode.getChildren()

			' Load all values common to all commodities and save them to corresponding fields of the object.
			TCommodity.LoadValues(commChildren, comm) ' Pass the node list and the newly created engine object as parameters
		Next
		
		Return
	EndFunction

	' loads commodity properties from xml nodes
	Function LoadValues(nodelist:TList,c:TCommodity)
		For Local value:TxmlNode = EachIn nodelist	' iterate through node values
			If value.GetName() = "name"		Then c._name		= value.GetText()	
			If value.GetName() = "unit" 	Then c._unit		= value.GetText()
			If value.GetName() = "mass" 	Then c._mass		= value.GetText().ToFloat()
			If value.GetName() = "volume" 	Then c._volume	= value.GetText().ToFloat()
			If value.GetName() = "avgprice"	Then c._avgprice = value.GetText().ToFloat()
		Next
	End Function

	Function Create:TCommodity(idString:String)
		Local comm:TCommodity = New TCommodity		' create an instance
		comm._id = idString							' give an ID

		If Not g_L_Commodities Then g_L_Commodities = CreateList()	' create a list if necessary
		g_L_Commodities.AddLast comm		' add the newly created object to the end of the list
		
		Return comm	' return the pointer to this specific object instance
	EndFunction
	
EndType



' TFuel is a special commodity used as engine/thruster fuel
Type TFuel Extends TCommodity
	Global g_L_Fuels:TList		' a list to hold all fuel types
	Field _energy:Float			' energy (megajoules) produced by one kilogram of fuel
	
	Method GetEnergy:Float() Return _energy EndMethod
	Method SetEnergy(e:Float) _energy = e EndMethod
	
	Function ReturnFuel:TFuel(idString:String)
		If Not g_L_Fuels Then Print "ReturnFuel: no fuels defined" ; Return Null	' return if the list is empty
		
		For Local f:TFuel = EachIn g_L_Fuels
			If f.GetID() = idString Then Return f
		Next

		Print "ReturnFuel: no fuel matching the ID '" + idString + " found"
		Return Null
	End Function
	
	' loads all fuel specific commodity properties from xml node
	Function LoadAll(rootnode:TxmlNode)
		If G_Debug Print "    Loading fuels..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			If G_Debug Print "      Fuel type found: " + rootnode.GetName()
			Local fuel:TFuel = TFuel.Create(rootnode.GetName())	
			
			Local fuelChildren:TList = rootnode.getChildren()
			For Local value:TxmlNode = EachIn fuelChildren
				If value.GetName() = "energy"		Then fuel.SetEnergy(value.GetText().ToFloat())
			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(fuelChildren, fuel) ' Pass the node list and the newly created engine object as parameters
		Next
		
		Return
	EndFunction
	
	
	Function Create:TFuel(idString:String)
		Local f:TFuel = New TFuel		' create an instance
		f._id = idString					' give an ID

		If Not g_L_Fuels Then g_L_Fuels = CreateList()	' create a list if necessary
		g_L_Fuels.AddLast f		' add the newly created object to the end of the list
		
		Return f	' return the pointer to this specific object instance
	EndFunction
EndType

' TShippart, a sub-type of TCommodity
Include "i_TCommodity_TShippart.bmx"	
