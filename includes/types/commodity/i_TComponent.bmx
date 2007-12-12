' TComponent is an actual created ship part. It has additional fields for upgrades and damage.
Type TComponent
	Field _ShipPart:TShippart 	' the ship part prototype this Component is based on
	Field _L_Upgrades:TList		' a list holding possible upgrades
	Field _damage:Float			' damage sustained by this component
	Field _slot:TSlot			' the slot the component is installed in (if any)

	Method GetSlot:TSlot() 
		If _slot Then Return _slot
		Return Null
	End Method
	
	Method AssignSlot(slot:TSlot) 
		_slot = slot
	End Method
	
	Method GetShipPartMass:Float()
		Return _ShipPart.GetMass()
	End Method
	
	Method GetThrust:Float() 
		Local engine:TPropulsion = TPropulsion(_ShipPart)  ' use casting to test the type
		If not engine Then Return Null	' component is not of type TPropulsion
		Return engine.GetThrust() 
	End Method
	
	Method getType:String() 
		If TPropulsion(_shipPart) Then Return "engine"
		Return Null
	End Method
	
	Function Create:TComponent(SPart:TShipPart)
		Local c:TComponent = New TComponent
		c._ShipPart = SPart
		c._damage = 0
		Return c
	End Function
End Type

