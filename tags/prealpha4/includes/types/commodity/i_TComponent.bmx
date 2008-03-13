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
	
	Method GetShipPart:TShippart() 
		Return _ShipPart
	End Method
	
	Method getType:String() 
		If TPropulsion(_shipPart) Then Return "engine"
		If TWeapon(_shipPart) Then Return "weapon"
		Return Null
	End Method
	
	Function Create:TComponent(SPart:TShipPart)
		Local c:TComponent = New TComponent
		c._ShipPart = SPart
		c._damage = 0
		Return c
	End Function
End Type

