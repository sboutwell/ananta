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


Rem
---------------------------------------------------------------------------------------
	Ship parts are modules that are fit into the ship hull. The values of each part is read from shipparts.xml.
	Ship design is modular: hull is the base of everything, hulls have slots (see i_typeMisc.bmx) for all ship parts
	and ship parts must go into the slots, never directly onto the ship. Slots have maximum 
	volumes and each slot can take more than one piece of equipment provided they can fit there.
	
	Engines and thrusters must occupy the specific engine and thruster slots. All other pieces 
	of equipment can (but do not have to) go into the equipment slots.
---------------------------------------------------------------------------------------
EndRem
Type TShippart Extends TCommodity Abstract
	Function LoadAll(rootnode:TxmlNode)		
		Local searchnode:TxmlNode = xmlGetNode(rootnode, "hulls") 	' find and return the "hulls" node
		If searchnode <> Null Then THullPrototype.LoadAll(searchnode)		' pass the "hulls" node as a parameter to the LoadAll function

		searchnode = xmlGetNode(rootnode, "propulsion") 			' find and return the "propulsion" node
		If searchnode <> Null Then TPropulsion.LoadAll(searchnode)	' pass the "propulsion" node as a parameter to the LoadAll function

		searchnode = xmlGetNode(rootnode, "fueltanks") 				' find and return the "fueltanks" node
		If searchnode <> Null Then TFueltank.LoadAll(searchnode)	' pass the "fueltanks" node as a parameter to the LoadAll function
	EndFunction
EndType


' THull is the "blueprint" of a ship. The hull data is saved as pure XML data.
' The hull data is extracted from within the TShip type when a new ship is created.
Type THull Extends TShippart
	Field L_engineSlots:TList				' a list to hold this hull's engine slots
	Field L_rotThrusterSlots:TList			' a list to hold this hull's rotation thruster slots
	Field L_thrusterSlots:TList				' a list to hold this hull's thruster slots
	Field L_equipmentSlots:TList			' a list to hold this hull's equipment slots

	Field image:TImage						' visual representation of the hull
	Field scale:Float
	Field size:Float

	Field thrusterPos:Float					' rotational thruster position (distance from the centre of mass). More distance gives more "leverage"
	Field maxSpd:Float						' maximum speed for fly-by-wire velocity limiter (read from xml)
	Field maxRotationSpd:Float				' maximum rotation speed (degrees per frame) (calculated by a routine)
	Field reverserRatio:Float				' thrust percentage of main engines that can be directed backward (read from xml)

	' THull.Create creates a new hull and copies its values from the prototype hull
	Function Create:THull(idString:String)
		' get a hull prototype matching the ID we've given as a parameter
		Local proto:THullPrototype = THullPrototype.FindHullPrototype(idString)
		If Not proto Then Return Null ' no prototype matching the ID found --> return
				
		Local hull:THull = New THull		' create an instance
		hull.id = idString					' give an ID for this hull (the same as the prototype ID)

		CopyProtoValues(hull,proto)	 		' copy hull prototype characteristics into this hull instance
		
		Return hull	' return the pointer to this specific object instance
		
		' function-in-a-function: copies all fields and lists of the prototype hull into this newly created hull
		Function CopyProtoValues(hull:THull,proto:THullPrototype)
			hull.mass			= proto.mass
			hull.image 			= proto.image
			hull.scale 			= proto.scale
			hull.size 			= proto.size
			hull.thrusterPos 	= proto.thrusterpos
			hull.maxSpd			= proto.maxSpd
			hull.maxRotationSpd = proto.maxRotationSpd
			hull.reverserRatio	= proto.reverserRatio


			' iterate through prototype slots to create copies of them
			For Local protoslot:TSlot = EachIn proto.L_engineSlots
				Local slot:TSlot = TSlot.Create(protoslot.id)	' create a slot instance
				If Not hull.L_engineSlots Then hull.L_engineSlots = CreateList()		' create a list if necessary
				hull.L_engineSlots.AddLast slot								' add the newly created slot to the end of the list
				CopySlotValues(slot,protoslot)
			Next
			For Local protoslot:TSlot = EachIn proto.L_rotThrusterSlots
				Local slot:TSlot = TSlot.Create(protoslot.id)	' create a slot instance
				If Not hull.L_rotThrusterSlots Then hull.L_rotThrusterSlots = CreateList()		' create a list if necessary
				hull.L_rotThrusterSlots.AddLast slot								' add the newly created slot to the end of the list
				CopySlotValues(slot,protoslot)
			Next
			For Local protoslot:TSlot = EachIn proto.L_thrusterSlots
				Local slot:TSlot = TSlot.Create(protoslot.id)	' create a slot instance
				If Not hull.L_thrusterSlots Then hull.L_thrusterSlots = CreateList()		' create a list if necessary
				hull.L_thrusterSlots.AddLast slot								' add the newly created slot to the end of the list
				CopySlotValues(slot,protoslot)
			Next
			For Local protoslot:TSlot = EachIn proto.L_equipmentSlots
				Local slot:TSlot = TSlot.Create(protoslot.id)	' create a slot instance
				If Not hull.L_equipmentSlots Then hull.L_equipmentSlots = CreateList()		' create a list if necessary
				hull.L_equipmentSlots.AddLast slot								' add the newly created slot to the end of the list
				CopySlotValues(slot,protoslot)
			Next
			
			Function CopySlotValues(slot:TSlot,protoslot:TSlot)
				slot.volume 	= protoslot.volume
				slot.exposedDir	= protoslot.exposedDir
				slot.location 	= protoslot.location
			End Function
		End Function
		
	EndFunction
EndType

Type THullPrototype Extends THull
	Global g_L_HullPrototypes:TList		' a list to hold all ship hull prototypes


	Method LoadSlots(node:TxmlNode)
		Print "    Loading slots for hull '" + ID + "'"

		If Not node.getChildren() Then
			Print "    	No slots for hull '" + ID + "' found!"
			Return
		EndIf
		
		Local children:TList = node.getChildren() 		' get all slot ID's
		For node = EachIn children							' iterate through each slot
			Print "      Slot found: " + node.GetName()

			If Not node.getChildren() Then	' slot with nothing in it!
				Print "      Warning: empty slot definition! Aborting slot loading for '" + ID + "'"
				Return
			EndIf

			Local slot:TSlot = TSlot.Create(node.GetName())			' create a slot instance
			For Local value:TxmlNode = EachIn node.getChildren()	' iterate through hull values
				If value.GetName() = "type" 	Then		' depending on the slot type, add the slot to a specific slot list
					Local slottype:String = value.GetText()
					Select slottype
						Case "rotthruster"
							If Not L_rotThrusterSlots Then L_rotThrusterSlots = CreateList()		' create a list if necessary
							L_rotThrusterSlots.AddLast slot								' add the newly created slot to the end of the list
						Case "thruster" 	
							If Not L_thrusterSlots Then L_thrusterSlots = CreateList()		' create a list if necessary
							L_thrusterSlots.AddLast slot								' add the newly created slot to the end of the list
						Case "engine" 		
							If Not L_engineSlots Then L_engineSlots = CreateList()		' create a list if necessary
							L_engineSlots.AddLast slot								' add the newly created slot to the end of the list
						Case "equipment"	
							If Not L_equipmentSlots Then L_equipmentSlots = CreateList()		' create a list if necessary
							L_equipmentSlots.AddLast slot								' add the newly created slot to the end of the list
						Default Print "No valid slot type detected!"
					End Select
				EndIf

				' assign the rest of the slot characteristics to their corresponding fields
				If value.GetName() = "volume" 	Then slot.volume 		= value.GetText().ToFloat()
				If value.GetName() = "exposure" Then slot.exposedDir 	= value.GetText()
				If value.GetName() = "location"	Then slot.location		= value.GetText()
			Next
		Next

		Print "    All slots for '" + ID + "' successfully initialized"
		Return

	EndMethod

	' FindHullPrototype takes an id as a search string and returns the hull matching the id
	Function FindHullPrototype:THullPrototype(idString:String)
		If Not g_L_HullPrototypes Then Print "FindHullPrototype: no hulls defined" ; Return Null	' return if the hull list is empty
		
		For Local hull:THullPrototype = EachIn g_L_HullPrototypes
			If hull.id = idString Then Return hull
		Next

		Print "FindHullPrototypes: no hull matching the ID '" + idString + " found"
		Return Null
	End Function
	' -------------------------------------------------------
	' Load all hull types from xml doc
	' -------------------------------------------------------
	Function LoadAll(hullnode:TxmlNode)
		Print "    Loading hull protypes..."
		AutoMidHandle True					' set automidhandle for hull image loading

		' ------------------------------------------------------------------------------------
		' Creating instance of each hull type 
		' ------------------------------------------------------------------------------------
		Local children:TList = hullnode.getChildren() 			' get all hull ID's
		For hullnode = EachIn children							' iterate through hulls
			Print "      Hull found: " + hullnode.GetName()
			Local hull:THullPrototype = THullPrototype.Create(hullnode.GetName())	' create a hull prototype instance
			
			Local hullChildren:TList = hullnode.getChildren()
			' search the hull node to find all information specific to hulls and save them into fields
			For Local value:TxmlNode = EachIn hullChildren	' iterate through hull values
				If value.GetName() = "image"		Then hull.image			= LoadImage (c_mediaPath + value.GetText())	' load the image representing this hull
				If value.GetName() = "scale" 		Then hull.scale 		= value.GetText().ToFloat()
				If value.GetName() = "size" 		Then hull.size			= value.GetText().ToFloat()
				If value.GetName() = "thrusterpos" 	Then hull.thrusterpos	= value.GetText().ToFloat()
				If value.GetName() = "maxspd" 		Then hull.maxSpd		= value.GetText().ToFloat()
				If value.GetName() = "maxrotspd" 	Then hull.maxRotationSpd= value.GetText().ToFloat()
				If value.GetName() = "reverser" 	Then hull.reverserRatio	= value.GetText().ToFloat()
				If value.GetName() = "slots" 		Then hull.LoadSlots(value)		' call LoadSlots to initialize all slots for this hull
			Next

			' Load all values common to all commodities and save them to corresponding fields of the object.
			Super.LoadValues(hullChildren, hull) ' Pass the node list "hullChildren" and the newly created hull object as parameters
		Next
		
		Return
	EndFunction

 	Function Create:THullPrototype(idString:String)
		Local h:THullPrototype = New THullPrototype		' create an instance
		h.id = idString					' give an ID

		If Not g_L_HullPrototypes Then g_L_HullPrototypes = CreateList()	' create a list if necessary
		g_L_HullPrototypes.AddLast h	' add the newly created object to the end of the list
		
		Return h	' return the pointer to this specific object instance
	EndFunction

EndType


' -------------------------------------------------------
' SPECIFIC EQUIPMENT NEEDING SPECIALIZED HULL SLOTS
' -------------------------------------------------------

' All propulsion equipment (main engines and thrusters) fall under the TPropulsion type
Type TPropulsion Extends TShippart Final
	Global g_L_Engines:TList			' a list to hold all ship engines and thrusters
	Field thrust:Float					' maximum thrust of the engine/thruster
	Field efficiency:Float				' the portion of fuel's energy that is converted into thrust. Values 0 to 1.
	Field fueltype:String				' the type of fuel this engine can burn

	Function LoadAll(rootnode:TxmlNode)
		Print "    Loading propulsion..."
		
		Local children:TList = rootnode.getChildren() 			' get all engine ID's
		For rootnode = EachIn children							' iterate through engines
			Print "      Engine found: " + rootnode.GetName()
			Local engine:TPropulsion = TPropulsion.Create(rootnode.GetName())	' create an engine prototype instance
			
			Local engineChildren:TList = rootnode.getChildren()
			' search the propulsion node to find all information specific to propulsion and save them into fields
			For Local value:TxmlNode = EachIn engineChildren	' iterate through engine values
				If value.GetName() = "thrust"		Then engine.thrust		= value.GetText().ToFloat()
				If value.GetName() = "fueltype"		Then engine.fueltype	= value.GetText()
				If value.GetName() = "efficiency"	Then engine.efficiency	= value.GetText().ToFloat()
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
			If engine.id = idString Then Return engine
		Next

		Print "FindEngine: no engine matching the ID '" + idString + " found"
		Return Null
	End Function
	
	Function Create:TPropulsion(idString:String)
		Local p:TPropulsion = New TPropulsion	' create an instance
		p.id = idString							' give an ID

		If Not g_L_Engines Then g_L_Engines = CreateList()	' create a list if necessary
		g_L_Engines.AddLast p	' add the newly created object to the end of the list
		
		Return p	' return the pointer to this specific object instance
	EndFunction
EndType

' ------------------------------------------------
' MISC EQUIPMENT FITTING THE EQUIPMENT SLOTS
' ------------------------------------------------
Type TFueltank Extends TShippart Final
	Global g_L_Tanks:TList				' a list to hold all fuel tanks
	
	Function LoadAll(rootnode:TxmlNode)
		Print "    Loading fuel tanks..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			Print "      Fuel tank found: " + rootnode.GetName()
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
		t.id = idString						' give an ID

		If Not g_L_Tanks Then g_L_Tanks = CreateList()	' create a list if necessary
		g_L_Tanks.AddLast t		' add the newly created object to the end of the list
		
		Return t	' return the pointer to this specific object instance
	EndFunction
EndType

