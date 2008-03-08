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

Rem
---------------------------------------------------------------------------------------
	Ship parts are modules that are fit into the ship hull. The values of each part is read from shipparts.xml.
	Ship design is modular: hull is the base of everything, hulls have slots (see i_typeMisc.bmx) for all ship parts
	and ship parts must go into the slots, never directly onto the ship. Slots have maximum 
	volumes and each slot can take more than one piece of equipment provided they can fit there.
---------------------------------------------------------------------------------------
EndRem
Type TShippart Extends TCommodity
	Global g_L_ShipParts:TList
	
	Function FindShipPart:TShippart(idString:String) 
		If Not g_L_ShipParts Then Print "Error: No ship parts defined!" ; Return Null	' return if the list is empty
		
		For Local part:TShippart = EachIn g_L_ShipParts
			If part.getID() = idString Then Return part
		Next

		Print "FindShipPart: no part matching the ID '" + idString + " found"
		Return Null

	End Function
	
	Function LoadAll(RootNode:TxmlNode) 
		Local searchnode:TxmlNode = xmlGetNode(rootnode, "hulls") 	' find and return the "hulls" node
		If searchnode <> Null Then THullPrototype.LoadAll(searchnode) 		' pass the node as a parameter to the LoadAll function

		searchnode = xmlGetNode(rootnode, "propulsion") 			' find and return the "propulsion" node
		If searchnode <> Null Then TPropulsion.LoadAll(searchnode) 	' pass the node as a parameter to the LoadAll function

		searchnode = xmlGetNode(rootnode, "fueltanks")  				' find and return the "fueltanks" node
		If searchnode <> Null Then TFueltank.LoadAll(searchnode)  	' pass the node as a parameter to the LoadAll function
		
		searchnode = xmlGetNode(rootnode, "weapons")   				' find and return the "weapons" node
		If searchnode <> Null Then TWeapon.LoadAll(searchnode)    	' pass the node as a parameter to the LoadAll function	
		
	EndFunction
EndType

' THull is the actual hull instance of a created ship.
' The hull data is extracted from a prototype hull when a new ship is created.
Type THull Extends TShippart
	Field _L_Slots:TList					' equipment slots for the hull (see TSlot)

	Field _image:TImage						' visual representation of the hull
	Field _scale:Float
	Field _size:Float						' size affects rotational physics and radar blip size

	Field _thrusterPos:Float				' rotational thruster position (distance from the centre of mass). More distance gives more "leverage"
	Field _maxSpd:Float						' maximum speed for fly-by-wire velocity limiter (read from xml)
	Field _maxRotationSpd:Float				' maximum rotation speed (degrees per second) (calculated by a routine)
	Field _reverserRatio:Float				' thrust percentage of main engines that can be directed backward (read from xml)

	Method AddComponent(comp:TComponent, slot:TSlot) 
		Local result:Int = slot.AddComponent(comp) 
	End Method

	Method RemoveComponent(comp:TComponent, slot:TSlot) 
		Local result:Int = slot.RemoveComponent(comp) 
	End Method
	
	Method FindSlot:TSlot(slotID:String) 
		For Local slot:TSlot = EachIn _L_Slots
			If slot.getID() = slotID Then Return slot
		Next
		Return Null
	End Method
	
	Method AddSlot(slot:TSlot) 
		If not _L_Slots Then _L_Slots = CreateList() 
		_L_Slots.AddLast slot
	End Method

	Method GetSlotList:TList() 
			If _L_Slots Then Return _L_Slots
			Return Null
	End Method
	
	Method GetImage:TImage()
		Return _image
	End Method

	Method GetScale:Float()
		Return _scale
	End Method

	Method GetSize:Float()
		Return _size
	End Method

	Method GetThrusterPos:Float()
		Return _thrusterPos
	End Method

	Method GetMaxSpd:Float()
		Return _maxSpd
	End Method
	
	Method GetReverserRatio:Float()
		Return _reverserRatio
	End Method
	
	Method GetMaxRotationSpd:Float()
		Return _maxRotationSpd
	End Method
	
	Method SetImage(val:TImage)
		_image = val
	End Method

	Method SetScale(val:Float)
		_scale = val
	End Method

	Method SetSize(val:Float) 
		_size = val
	End Method

	Method SetThrusterPos(val:Float)
		_thrusterPos = val
	End Method
	
	Method SetMaxSpd(val:Float)
		_maxSpd = val
	End Method

	Method SetMaxRotationSpd(val:Float)
		_maxRotationSpd = val
	End Method

	Method SetReverserRatio(val:Float)
		_reverserRatio = val
	End Method
	
	' THull.Create creates a new hull and copies its values from the prototype hull
	Function Create:THull(idString:String)
		' get a hull prototype matching the ID we've given as a parameter
		Local proto:THullPrototype = THullPrototype.FindHullPrototype(idString)
		If Not proto Then Return Null ' no prototype matching the ID found --> return
				
		Local hull:THull = New THull		' create an instance
		hull._id = idString					' give an ID for this hull (the same as the prototype ID)

		CopyProtoValues(hull,proto)	 		' copy hull prototype characteristics into this hull instance
		
		Return hull	' return the pointer to this specific object instance
		
	EndFunction
	
	' copies all fields and lists of the prototype hull into this newly created hull
	Function CopyProtoValues(hull:THull, proto:THullPrototype) 
		hull.SetMass(proto.GetMass())
		hull.SetImage(proto.GetImage())
		hull.SetScale(proto.GetScale())
		hull.SetSize(proto.GetSize())
		hull.SetThrusterPos(proto.GetThrusterPos())
		hull.SetMaxSpd(proto.GetMaxSpd())
		hull.SetMaxRotationSpd(proto.GetMaxRotationSpd())
		hull.SetReverserRatio(proto.GetReverserRatio())

		
		' iterate through prototype slots to create copies of them
		For Local protoslot:TSlot = EachIn proto.GetSlotList() 
			Local slot:TSlot = TSlot.Create(protoslot.GetId())	' create a slot instance
			hull.AddSlot(slot) 	' add the slot to the hull slot list
			CopySlotValues(slot,protoslot)
		Next	
	End Function
	
	Function CopySlotValues(slot:TSlot, protoslot:TSlot) 
		slot.SetVolume(protoslot.GetVolume())
		slot.SetExposedDir(protoslot.GetExposedDir())
		slot.SetLocation(protoslot.GetLocation()) 
		slot.SetSlotType(protoslot.getSlotType()) 
	End Function
EndType

Type THullPrototype Extends THull
	Global g_L_HullPrototypes:TList		' a list to hold all ship hull prototypes
	Field _L_SlotList:TList
	
	Method GetSlotList:TList() 
		If _L_SlotList Then Return _L_SlotList
		Return Null
	End Method
	
	Method AddSlot(slot:TSlot) 
		If not _L_SlotList Then _L_SlotList = New TList
		_L_SlotList.AddLast(slot) 
	End Method
	
	Method LoadSlots(node:TxmlNode)
		If G_Debug Print "    Loading slots for hull '" + _ID + "'"

		If Not node.getChildren() Then
			Print "    	No slots for hull '" + _ID + "' found!"
			Return
		EndIf
		
		Local children:TList = NODE.getChildren()  		' get all slot ID's
		For node = EachIn children							' iterate through each slot
			If G_Debug Print "      Slot found: " + node.GetName()

			If Not node.getChildren() Then	' slot with nothing in it!
				Print "      Warning: empty slot definition! Aborting slot loading for '" + _ID + "'"
				Return
			EndIf

			Local slot:TSlot = TSlot.Create(node.GetName())			' create a slot instance
			For Local value:TxmlNode = EachIn node.getChildren()	' iterate through hull values
				If value.GetName() = "type" Then
					Local slottype:String = value.GetText() 
					slot.SetSlotType(slottype) 
					AddSlot(slot) 
				EndIf

				' assign the rest of the slot characteristics to their corresponding fields
				If value.GetName() = "volume" 	Then slot.SetVolume (value.GetText().ToFloat())
				If value.GetName() = "exposure" Then slot.SetExposedDir (value.GetText())
				If value.GetName() = "location"	Then slot.SetLocation (value.GetText())
			Next
		Next

		If G_Debug Print "    All slots for '" + _ID + "' successfully initialized"
		Return

	EndMethod

	' FindHullPrototype takes an id as a search string and returns the hull matching the id
	Function FindHullPrototype:THullPrototype(idString:String)
		If Not g_L_HullPrototypes Then Print "FindHullPrototype: no hulls defined" ; Return Null	' return if the hull list is empty
		
		For Local hull:THullPrototype = EachIn g_L_HullPrototypes
			If hull.GetId() = idString Then Return hull
		Next

		Print "FindHullPrototypes: no hull matching the ID '" + idString + " found"
		Return Null
	End Function
	' -------------------------------------------------------
	' Load all hull types from xml doc
	' -------------------------------------------------------
	Function LoadAll(hullnode:TxmlNode)
		If G_Debug Print "    Loading hull protypes..."
		AutoMidHandle True					' set automidhandle for hull image loading

		' ------------------------------------------------------------------------------------
		' Creating instance of each hull type 
		' ------------------------------------------------------------------------------------
		Local children:TList = hullnode.getChildren() 			' get all hull ID's
		For hullnode = EachIn children							' iterate through hulls
			If G_Debug Print "      Hull found: " + hullnode.GetName()
			Local hull:THullPrototype = THullPrototype.Create(hullnode.GetName())	' create a hull prototype instance
			
			Local hullChildren:TList = hullnode.getChildren()
			' search the hull node to find all information specific to hulls and save them into fields
			For Local value:TxmlNode = EachIn hullChildren	' iterate through hull values
				If value.GetName() = "image" Then hull.SetImage(TImg.LoadImg(value.GetText()))  	' load the image representing this hull
				If value.GetName() = "scale" 		Then hull.SetScale(value.GetText().ToFloat())
				If value.GetName() = "size" Then hull.SetSize(value.GetText().ToFloat())
				If value.GetName() = "thrusterpos" 	Then hull.SetThrusterPos(value.GetText().ToFloat())
				If value.GetName() = "maxspd" 		Then hull.SetMaxSpd(value.GetText().ToFloat())
				If value.GetName() = "maxrotspd" 	Then hull.SetMaxRotationSpd(value.GetText().ToFloat())
				If value.GetName() = "reverser" 	Then hull.SetReverserRatio(value.GetText().ToFloat())
				If value.GetName() = "slots" 		Then hull.LoadSlots(value)		' call LoadSlots to initialize all slots for this hull
			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(hullChildren, hull) ' Pass the node list "hullChildren" and the newly created hull object as parameters
		Next
		
		Return
	EndFunction

 	Function Create:THullPrototype(idString:String)
		Local h:THullPrototype = New THullPrototype		' create an instance
		h._id = idString					' give an ID

		If Not g_L_HullPrototypes Then g_L_HullPrototypes = CreateList()	' create a list if necessary
		g_L_HullPrototypes.AddLast h	' add the newly created object to the end of the list
		If Not g_L_ShipParts Then g_L_ShipParts = CreateList()
		g_L_ShipParts.AddLast h
		
		Return h	' return the pointer to this specific object instance
	EndFunction

EndType


' All propulsion equipment (main engines and thrusters) fall under the TPropulsion type
Type TPropulsion Extends TShippart Final
	Global g_L_Engines:TList			' a list to hold all ship engines and thrusters
	Field _thrust:Float					' maximum thrust of the engine/thruster
	Field _efficiency:Float				' the portion of fuel's energy that is converted into thrust. Values 0 to 1.
	Field _fueltype:String				' the type of fuel this engine can burn

	Method GetThrust:Float()
		Return _thrust
	End Method
	
	Method GetEfficiency:Float()
		Return _efficiency
	End Method
	
	Method GetFuelTypet:String()
		Return _fueltype
	End Method

	Method SetThrust(val:Float)
		_thrust = val
	End Method
	
	Method SetEfficiency(val:Float)
		_efficiency = val
	End Method
	
	Method SetFuelType(val:String)
		_fueltype = val
	End Method
	
	
	Function LoadAll(rootnode:TxmlNode)
		If G_Debug Print "    Loading propulsion..."
		
		Local children:TList = rootnode.getChildren() 			' get all engine ID's
		For rootnode = EachIn children							' iterate through engines
			If G_Debug Print "      Engine found: " + rootnode.GetName()
			Local engine:TPropulsion = TPropulsion.Create(rootnode.GetName())	' create an engine prototype instance
			
			Local engineChildren:TList = rootnode.getChildren()
			' search the propulsion node to find all information specific to propulsion and save them into fields
			For Local value:TxmlNode = EachIn engineChildren	' iterate through engine values
				If value.GetName() = "thrust"		Then engine.SetThrust(value.GetText().ToFloat())
				If value.GetName() = "fueltype"		Then engine.SetFuelType(value.GetText())
				If value.GetName() = "efficiency"	Then engine.SetEfficiency(value.GetText().ToFloat())
			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(engineChildren, engine) ' Pass the node list and the newly created engine object as parameters
		Next
		
		Return
	EndFunction
	
	'FindEngine finds an engine matching the given id string and returns it
	Function FindEngine:TPropulsion(idString:String)
		 If Not g_L_Engines Then Print "FindEngine: no engines defined" ; Return Null	' return if the list is empty
		
		For Local engine:TPropulsion = EachIn g_L_Engines
			If engine.GetID() = idString Then Return engine
		Next

		Print "FindEngine: no engine matching the ID '" + idString + " found"
		Return Null
	End Function
	
	Function Create:TPropulsion(idString:String)
		Local p:TPropulsion = New TPropulsion	' create an instance
		p._id = idString							' give an ID

		If Not g_L_Engines Then g_L_Engines = CreateList()	' create a list if necessary
		g_L_Engines.AddLast p	' add the newly created object to the end of the list
		If Not g_L_ShipParts Then g_L_ShipParts = CreateList() 
		g_L_ShipParts.AddLast p
		
		Return p	' return the pointer to this specific object instance
	EndFunction
EndType

Type TWeapon Extends TShippart Final
	Global g_L_Weapons:TList				' a list to hold all weapons
	
	Function LoadAll(rootnode:TxmlNode)
		If G_debug Print "    Loading weapons..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			If G_debug Print "      Weapon found: " + rootnode.GetName() 
			Local weap:TWeapon = TWeapon.Create(rootnode.GetName()) 
			
			Local wChildren:TList = rootnode.getChildren() 
'			For Local value:TxmlNode = EachIn wChildren
'				If value.GetName() = "damage"		Then weap.damage = value.GetText().ToInt()
'			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(wChildren, weap)  ' Pass the node list and the newly created object as parameters
		Next
		
		Return
	EndFunction
	
	
	Function Create:TWeapon(idString:String) 
		Local w:TWeapon = New TWeapon	' create an instance
		w._id = idString						' give an ID

		If Not g_L_Weapons Then g_L_Weapons = CreateList() 	' create a list if necessary
		g_L_Weapons.AddLast w		' add the newly created object to the end of the list
		If Not g_L_ShipParts Then g_L_ShipParts = CreateList() 
		g_L_ShipParts.AddLast w
		
		Return w	' return the pointer to this specific object instance
	EndFunction
EndType

' ------------------------------------------------
' MISC EQUIPMENT FITTING THE EQUIPMENT SLOTS
' ------------------------------------------------
Type TFueltank Extends TShippart Final
	Global g_L_Tanks:TList				' a list to hold all fuel tanks
	
	Function LoadAll(rootnode:TxmlNode)
		If G_Debug Print "    Loading fuel tanks..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			If G_Debug Print "      Fuel tank found: " + rootnode.GetName()
			Local tank:TFueltank = TFueltank.Create(rootnode.GetName())	
			
			Local tankChildren:TList = rootnode.getChildren()
'			For Local value:TxmlNode = EachIn tankChildren
'				If value.GetName() = "fueltype"		Then tank.fueltype	= value.GetText()
'			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(tankChildren, tank) ' Pass the node list and the newly created engine object as parameters
		Next
		
		Return
	EndFunction
	
	
	Function Create:TFueltank(idString:String)
		Local t:TFueltank = New TFueltank	' create an instance
		t._id = idString						' give an ID

		If Not g_L_Tanks Then g_L_Tanks = CreateList()	' create a list if necessary
		g_L_Tanks.AddLast t		' add the newly created object to the end of the list
		If Not g_L_ShipParts Then g_L_ShipParts = CreateList() 
		g_L_ShipParts.AddLast t
		
		Return t	' return the pointer to this specific object instance
	EndFunction
EndType


' types directly related to TShippart
Include "i_TSlot.bmx"
Include "i_TComponent.bmx"
