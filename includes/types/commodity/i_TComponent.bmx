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

' Notice that TShippart itself is never instantiated when a ship component is created. 
' It is only a prototype which is referenced through TComponent
Type TComponent Extends TMovingObject
	Global g_nrComponents:Int
	Field _ShipPart:TShippart 	' the ship part prototype this Component is based on
	Field _L_Upgrades:TList		' a list holding possible upgrades (not used yet)
	Field _damage:Float			' damage sustained by this component
	Field _slot:TSlot			' the slot the component is installed in (if any)
	Field _particleGenerator:TParticleGenerator ' possible attached particle generator for this component (eg. engines)

	Method New()
		g_nrComponents:+1
	End Method
	
	Method Delete()
		g_nrComponents:-1
	End Method
	
	Method Destroy()
		_ShipPart = Null
		If GetSlot() Then GetSlot().Destroy()
		_slot = Null
		If _L_Upgrades Then _L_Upgrades.Clear()
		If _particleGenerator Then _particlegenerator.Destroy()
		_particleGenerator = Null
		Super.Destroy()
	End Method
	
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
		If TFueltank(_shipPart) Then Return "equipment"
		If TWarpdrive(_shipPart) Then Return "equipment"
		Return Null
	End Method
	
	Function Create:TComponent(SPart:TShipPart)
		Local c:TComponent = New TComponent
		c._ShipPart = SPart
		c._damage = 0
		Return c
	End Function
End Type

