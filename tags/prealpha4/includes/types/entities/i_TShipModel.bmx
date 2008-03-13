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

Type TShipModel
	Global g_L_ShipModels:TList 	' global list holding all ship models
	Field _id:String
	Field _name:String
	Field _description:String
	Field _hullID:String				' the ID of the ship hull this model is built from
	Field _L_parts:TList				' all part/slot combos of this model (TShipModelPart)
	
	Method SetDescription(val:String) 
		_description = val
	End Method
	
	Method SetName(val:String) 
		_name = val
	End Method
	
	Method SetHullID(val:String) 
		_hullID = val
	End Method
	
	Method GetParts:TList() 
		Return _L_parts
	End Method
	
	Method GetName:String() 
		Return _name
	End Method
	
	Method GetHullID:String() 
		Return _hullID
	End Method
	
	Method GetDescription:String() 
		Return _description
	End Method
	
	Method getID:String() 
		Return _ID
	End Method
	
	' BuildShipFromModel takes a ship model ID as a parameter. 
	' Returns ready-built ship with all the parts defined in the ship model
	Function BuildShipFromModel:TShip(smID:String) 
		Local model:TShipModel = TShipModel.FindShipModel(smID) 
		If Not model Then Return Null		' no matching ship model found 
		
		Local ship:TShip = TShip.Create(model.GetHullID())  	' build the basic hull
		
		For Local modelpart:TShipModelPart = EachIn model.GetParts()  	' find and create each part
			Local part:TShippart = TShippart.FindShipPart(modelpart._partID) 
			If part Then												' if part matching the id is found
				Local component:TComponent = TComponent.Create(part)  	' create a component based on the part
				ship.AddComponentToSlotID(component, modelpart._slotID)  ' and add the part to the correct slot 
			EndIf
		Next
		Return ship
	End Function
	
	Function FindShipModel:TShipModel(smID:String) 
		If Not g_L_ShipModels Then Return Null
		For Local model:TShipModel = EachIn g_L_ShipModels
			If model.getID() = smID Then Return model
		Next
		Print "FindShipModel ERROR: No model '" + smID + "' found!"
		Return Null
	End Function
	
	Method AddPart:Int(slotID:String, partID:String) 
		If Not _L_parts Then Return Null
		Local smp:TShipModelPart = TShipModelPart.Create(slotID, partID) 
		_L_parts.AddLast(smp) 
		Return True		' success
	End Method
	
	Function LoadAll() 
		Local root:TxmlNode = loadXMLFile(c_shipModelsFile)  	' load the root node of shipmodels.xml

		Local children:TList = root.getChildren()      		' get all ship models
		For Local modelnode:TxmlNode = EachIn children		' iterate through models
			If G_debug Then Print "TShipModel.LoadAll(): Found model " + modelnode.GetName() 
			Local modelChildren:TList = modelnode.getChildren() 
			If Not modelChildren Then
				Print "Shipmodel definition empty! Skipping."
				Continue
			EndIf
			Local model:TShipModel = TShipModel.Create(modelnode.GetName())  	' create a model prototype instance
			' find the model's values to save them into fields
			For Local value:TxmlNode = EachIn modelChildren	' iterate through values
				If value.GetName() = "hull" Then model.SetHullID (value.GetText().toString()) 
				If value.GetName() = "name" Then model.SetName (value.GetText().toString()) 
				If value.GetName() = "description" Then model.SetDescription (value.GetText().toString()) 
				If value.GetName() = "components" Then
					For Local component:TxmlNode = EachIn value.getChildren()  ' iterate through components
						Local slotID:String = component.GetName() 
						For Local part:TxmlNode = EachIn component.getChildren()  ' iterate through parts in a slot
							Local partID:String = part.GetText().toString() 
							model.AddPart(slotID, partID)    ' add the slot/part combo
						Next
					Next
				End If
			Next
			If G_debug Then Print "  Model " + modelnode.GetName() + " successfully loaded."
		Next	
	End Function
	
	Function Create:TShipModel(idStr:String) 
		If Not g_L_ShipModels Then g_L_ShipModels = New TList
		Local sm:TShipModel = New TShipModel
		sm._L_parts = New TList
		sm._id = idStr
		g_L_ShipModels.AddLast(sm) 
		Return sm
	End Function
End Type

Type TShipModelPart
	Field _slotID:String		' the slot ID this part goes to
	Field _partID:String		' the part ID of the part
	
	Function Create:TShipModelPart(sID:String, pID:String) 
		Local smp:TShipModelPart = New TShipModelPart
		smp._slotID = sID
		smp._partID = pID
		Return smp
	End Function
End Type