Rem
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

' TSystem represents a solar system
Type TSystem Final
	Global _g_ActiveSystem:TSystem				' the System the player is in
	Field _name:String	' Name of the System
	Field _sectorX:Int, _sectorY:Int ' coordinates of the sector this system's in (0 - 7192)
	Field _x:Int,_y:Int	' System's x-y-coordinates in the galaxy (0 - ~1.8 million)
	Field _size:Float = 3	 ' size of the central star (for starmap blip size)
	Field _type:Int	' type of the central star
	Field _multiple:Int	' multiple star status for the system
	
	Field _Population:Float    ' In Billions
	Field _TechLevel:Float   ' 0.0 - 1.0 (0 = no economy, 1 = super race)
	Field _GovernmentAllegiance:String    ' Government (See below)
	Field _Planets:Int	' number of primary planets, excludes moons
	Field _DangerLevel:Float   ' 0.0 - 1.0 (for pirate spawning / economy factors)
	
	Field _Description:String    ' A Short randomly created description based on the above
	
	Field _mainStar:TStar
	Field _L_SpaceObjects:TList	' a list to hold all TSpaceObjects in this System

	' draw every space object in this system
	Method DrawAllInSystem(vp:TViewport)
		If Not _L_SpaceObjects Return							' Exit if a body list doesn't exist
		For Local obj:TSpaceObject = EachIn _L_SpaceObjects	' Iterate through each drawable object in the System
			obj.DrawBody(vp)     							' Calls the DrawBody method of each drawable object in the System
			If vp.GetSystemMap() And obj.showsOnMap() Then	' draw a minimap blip if minimap is defined for the viewport
				vp.GetSystemMap().AddSystemMapBlip(obj)
			End If
			obj._updated = False	' optimization to clear updated status during the drawing cycle
		Next
	EndMethod

	' add a space object to this system
	Method AddSpaceObject(obj:TSpaceObject)
		If Not _L_SpaceObjects Then _L_SpaceObjects = CreateList()	' create a list if necessary
		'obj.SetSystem(self)  ' crash with abstract objects!
		obj._system = Self
		_L_SpaceObjects.AddLast obj
	EndMethod

	' remove a space object from this system
	Method RemoveSpaceObject(obj:TSpaceObject) 
		If Not _L_SpaceObjects Then Return
		obj._system = Null
		_L_SpaceObjects.Remove(obj) 
	EndMethod

	' placeholder method for procedural planet generation
	Method Populate()
	
		' Matt - in progress...
	
		Rem
	
		SeedRnd(((Self._sectorX Shl 16) + Self._sectorY) + (Self._x + Self._y))
	
		Local sSize:Long = 500000:Long ' for testing...
	
		' create a star
		Local st1:TStar = TStar.Create(0, 0, Self, 1000000, 5, Name+" I") 
		st1._image = TImg.LoadImg("star_generated") 
		st1._rotation = -90
		st1._scaleX = 20
		st1._scaleY = st1._scaleX
		st1._size = CalcImageSize(st1._image, False) * st1._scaleX
		st1._mass = (st1._scaleX ^ 2) * 2000000000
		
		Self.SetMainStar(st1)
		
		' _Population 'gets set after....
		' _DangerLevel ' so does this
		' _GovernmentAllegiance ' and this
		' _TechLevel ' and this
		
		' here we're going to use a simple way of generating planets

		Local PlanetDistance:Float = 0.3 ' AUs
		Local StartingTemperature:Float = 0 ' an arbitary figure
		Local SystemPopulation:Float = 0.0 ' Billions
				
		Local planetChance:Byte[]
		Select Self._type
			Case 0 
				PlanetChance:Byte = New Byte[0,0,0,0,0,1,3] ' Type 'M' flare star
				StartingTemperature = 100000 ' Kelvin
			Case 1 
				PlanetChance:Byte = New Byte[0,0,1,1,1,2,3,3,4,5] ' Faint type 'M' red star
				StartingTemperature = 80000 ' Kelvin
			Case 2 
				PlanetChance:Byte = New Byte[0,1,1,2,2,3,4,4,4,5,6] ' Type 'M' red star
				StartingTemperature = 200000 ' Kelvin
			Case 3 
				PlanetChance:Byte = New Byte[2,2,2,3,4,4,4,5,6,7,8,8] ' Type 'K' orange star
				StartingTemperature = 300000 ' Kelvin
			Case 4 
				PlanetChance:Byte = New Byte[3,3,4,4,4,5,5,6,7,7,8,9,9,10,10,11,11] ' Type 'G' yellow star
				StartingTemperature = 300000 ' Kelvin
			Case 5 
				PlanetChance:Byte = New Byte[0,1,1,2,3,4,5,6,7,8,9,10] ' Type 'F' white star 
				StartingTemperature = 500000 ' Kelvin
			Case 6 
				PlanetChance:Byte = New Byte[0,0,1,1,2,3,3,3,4,4,4] ' Type 'A' hot white star
				StartingTemperature = 700000 ' Kelvin
			Case 7 
				PlanetChance:Byte = New Byte[0,0,1,1,2,3,6,3] ' White dwarf star
				StartingTemperature = 60000 ' Kelvin
			Case 8 
				PlanetChance:Byte = New Byte[0,0,0,1,4,5,6,6,6,7] ' Red giant star
				StartingTemperature = 70000 ' Kelvin
		End Select
		
		PlanetDistance = 0.000005 * 700000 ' = 1.4ish
		
		Self._Planets = PlanetChance[Rand(0,PlanetChance.length-1)]

		' freak occurance, start the planets way out.
		If Rand(1,15)=1 PlanetDistance = Rnd(1.6,5.5) ' AUs

		For Local i:Int = 0 To Self._Planets-1
			
			' position at nothing for the moment. we'll reposition later.
			Local newPlanet:TPlanet = TPlanet.Create(0, 0, Self, 100000, 10, "planet " + i) 
			
			newPlanet.getInfoFromXML(c_celestialTypes, "planets", "rocky1")
			
			pl2.SetX()
			pl2.SetY()
			pl2._image = TImg.LoadImg("jupiter.png") 
			pl2._rotation=-90
			pl2._scaleX = Rnd(0.5, 2) 
			pl2._scaleY = pl2._scaleX
			pl2._size = CalcImageSize(pl2._image, False) * pl2._scaleX
			pl2._mass = (pl2._scaleX ^ 2) * Rand(200000000, 400000000) 
			pl2._hasGravity = True			
			
			If PlanetDistance > 50.0 ' AUs
				'barren planet			
			ElseIf PlanetDistance > 40
				'gas planet
			ElseIf PlanetDistance > 35
				'gas ringed planet
			ElseIf PlanetDistance > 20
				'gas planet
			ElseIf PlanetDistance > 12
				'barren rock
			ElseIf PlanetDistance > 5
				'marsy type planet
			ElseIf PlanetDistance > 2.3
				'marsy
			ElseIf PlanetDistance > 0.9
				'earth habitable
			ElseIf PlanetDistance > 0.3
				'venus like
			ElseIf PlanetDistance > 0.1
				'mercury like
			Else
				' too damn close. move out.
			EndIf
			
			' now that we have the planet distance (orbit distance from the sun)
			' we should randomly set an orbital angle
						
						
						
			
			' now move out from the star ready for the next planet position
			
			Select Rand(1,12)
				Case 1,2,3,4,5,6,7,8 PlanetDistance:+Rnd(1.4,8.0) ' AUs
				Case 9,10,11 PlanetDistance:+Rnd(1.4,16.0) ' AUs
				Case 12 PlanetDistance:+Rnd(1.4,30.0) ' AUs
			End Select
		Next
	
		EndRem
	
  	End Method

	
	' set this system as the "active" system (the one the camera is in)
	Method SetAsActive()
		_g_ActiveSystem = Self
	End Method
	
	Method GetX:Int()
		Return _x
	End Method
	
	Method GetY:Int()
		Return _y
	End Method
	
	Method GetSectorX:Int()
		Return _sectorX
	End Method
	
	Method GetSectorY:Int()
		Return _sectorY		
	End Method
	
	Method GetSize:Int()
		Return _size
	End Method
	
	' returns the main star of the system
	Method GetMainStar:TStar()
		Return Self._mainStar
	End Method

	Method SetMainStar(main:TStar)
		Self._mainStar=main
	End Method

	' returns the system that is currently "active"
	Function GetActiveSystem:TSystem()
		Return _g_ActiveSystem
	End Function
	
	Function Create:TSystem(sectX:Int, sectY:Int,x:Int,y:Int,name:String,typ:Int,mult:Int)
		Local se:TSystem = New TSystem								' create an instance of the System
		se._name = name	
		se._sectorX = sectX
		se._sectorY = sectY
		se._x = x	; se._y = y	
		se._type = typ
		se._multiple = mult
		Return se										' return the pointer to this specific object instance
	EndFunction
EndType
