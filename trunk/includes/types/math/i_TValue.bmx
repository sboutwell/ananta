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

rem
	TValue is a type that handles different scalars and conversions between their units
endRem


Type TValue
	Global g_L_Values:TList	' all values
	Field _baseUnit:TUnit	' the base unit
	Field _L_Units:TList 	' units configured for this value
	Field _name:String   	' value name (distance, mass, force, energy etc)
	
	Method AddUnit(unitName:String, factor:Double = Null, symbol:String = Null)
		Local u:TUnit = TUnit.Create(unitName, factor, symbol)
		u.name = unitName
		u.factor = factor
		u.symbol = symbol
		
		If factor = Null Then _baseUnit = u
		If Not _L_Units Then _L_Units = CreateList()
		_L_Units.AddLast(u)
	End Method

	' convert calculates how many "from" units fits in "to" unit
	Method Convert:Double(_from:TUnit, _to:TUnit)
		Return _from.factor / _to.factor
	End Method
	
	Method FindUnit:TUnit(unitName:String)
		If not _L_Units Then Return Null
		
		For Local u:TUnit = EachIn _L_Units
			If u.name = unitName Or u.symbol = unitName Then Return u
		Next
		
		Return Null
	End Method
	
	' presents long integers with prefix multipliers (kilo, mega, giga, etc)
	Function getLongPrefix(pref:String Var, val:Long Var) 
		Local prefixes:String[] =["", "", "",  ..
								"k", "k", "k",  ..
								"M", "M", "M",  ..
								"G", "G", "G",  ..
								"T", "T", "T",  ..
								"P", "P", "P",  ..
								"E", "E", "E" ..
								] 
		Local vString:String = String(val) 
		Local zeroes:Int = 0
		For Local char:Int = vString.Length - 1 To 0 Step - 1
			If Chr(vString[char] ) = "0" Then zeroes:+1
		Next
		
		If zeroes > prefixes.Length - 1 Then zeroes = prefixes.Length - 1
		pref = prefixes[zeroes] 
		For Local i:Int = 3 To zeroes Step 3
			val = val / 1000
		Next
		
	End Function
	
	Function Create:TValue(name:String)
		Local v:TValue = New TValue
		v._name = name
		If not g_L_values Then g_L_Values = CreateList()
		g_L_values.AddLast(v)
		Return v
	End Function
End Type

Type TUnit
	Field name:String  ' unit name (gram, metre, Newton, joule etc)
	Field symbol:String ' unit symbol (g, m, N, J etc)
	Field factor:Double ' the factor to the base unit (the unit is this many base units)
	 					 ' Note: if this unit is the base unit, the factor is Null

						 					
	Function Create:TUnit(nm:String, fc:Double, sm:String = Null)
		Local u:TUnit = New TUnit
		u.name = nm
		u.symbol = sm
		u.factor = fc
		Return u
	End Function
End Type

