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
	Global _g_ViewingSystem:TSystem 		' player can view one system at a time.
	
	Field _name:String	' Name of the System
	Field _sectorX:Int, _sectorY:Int ' coordinates of the sector this system's in (0 - 7192)
	Field _x:Int,_y:Int	' System's x-y-coordinates in the galaxy (0 - ~1.8 million)
	Field _size:Float = 3	 ' size of the central star (for starmap blip size)
	Field _type:Int	' type of the central star
	Field _multiple:Int	' multiple star status for the system
	
	Field _PlanetChance:String	' representation of the likelihood of planets, 0,0,0,2,3,4,5 etc
	Field _Population:Float    ' In Billions
	Field _TechLevel:Float   ' 0.0 - 1.0 (0 = no economy, 1 = super race)
	Field _GovernmentAllegiance:String    ' Government (See below)
	Field _Planets:Int	' number of primary planets, excludes moons
	Field _DangerLevel:Float   ' 0.0 - 1.0 (for pirate spawning / economy factors)
	Field _comfortZone:String	' a string representing a preferred distance from the sun "x-x"
	
	Field _Description:String    ' A Short randomly created description based on the above
	
	Field _systemHasBeenPopulated:Byte = 0
	
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
			' reset strongest gravity source fields, they're no longer needed during this frame
			obj._strongestGravSource = Null
			obj._strongestGravity = 0
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
	' Matt - in progress...
	
	
	Method Populate()	
		
	
		Local ONE_AU:Long = 200000
	
		Local seed:Long = ((Self._sectorX Shl 16) + Self._sectorY) + (Self._x + Self._y)	
		SeedRnd(seed)
		
	
		DebugLog "	> Generating system "+Self.GetName()+" (seed: "+seed+")"
		
		' create a star
		' the createFromProto automatically looks at the current system's central star type
		' and creates the star from that
		' 
		' if you want to specify a specific star you can use:
		' 
		' local mainStar = TStar.Create(x:Int=0,y:Int=0,System:TSystem,mass:Long,size:Int,name:String)
		' 	TProtoBody.populateBodyFromName(mainStar, "sun0")
		' 
		
		DebugLog "	> Main star of type "+Self.GetCentralStarType()
				
		' if it's a lone star, just name it the system name, otherwise, number them.
		Local name:String = ""
		If _multiple=0 name=Self.getName() Else name=Self.GetName()+" I"
		
		Local mainStar:TStar = TStar.createFromProto(0, 0, Self, name)		
		Self.SetMainStar(mainStar)		
	
		DebugLog "	> Mass: "+Self.GetMainStar().GetMass()
	
		Local sunPrototypeBody:TProtoBody = TProtoBody.findProtoBodyFromName("sun"+Self.GetCentralStarType())
	
		' here we're going to use a simple way of generating planets

		Local PlanetDistance:Float = 0.3 ' AUs
		Local SystemPopulation:Float = 0.0 ' Billions
		Local PlanetTypeChance:String[]	
		
		' this will get the sun's.planetChance and convert it into an array of ints
		Local planetChance:Int[] = StringToIntArray(sunPrototypeBody.getPlanetChance(),",")
		
		PlanetDistance = 0.000005 * 700000 ' = 1.4ish
		
		Self.setNumberOfPlanets(PlanetChance[Rand(0,PlanetChance.length-1)])

		' freak occurance, start the planets way out.
		If Rand(1,15)=1 PlanetDistance = Rnd(1.6,5.5) ' AUs	
		
		DebugLog "	> System "+Self.getName()+" has "+Self.getNumberOfPlanets()+" planets"
		
		' load this here so we only have to do it once instead of every loop.
		Local comfortableMoons:TList = Self.compileListOfPlanetsAtThisDistance(0.5) ' only planets that can be moons, we don't want gas giant moons!
		
		' create the planets. Main planets first, moons nested.
		For Local i:Int = 0 To Self.getNumberOfPlanets()-1
			Local angle:Float = Rnd(360.0)
			Local planetName:String = G_Universe.getPlanetName()' get a random name
			Local planetType:String = ""
			Local planetPopulation:Float = 0.0
			Local newPlanet:TPlanet
						
			' as each planet has a comfort zone in AUs, we should compile
			' a list of planets that don't mind living at our current distance from the sun
			' 	
			Local comfortablePlanets:TList = Self.compileListOfPlanetsAtThisDistance(PlanetDistance)

			If comfortablePlanets.count()
				
				' now we randomly choose a planet from the comfy list list
				
				Local pProtoType:TProtoBody = TProtoBody(comfortablePlanets.valueAtIndex(Rand(0,comfortablePlanets.count()-1)))
				
				' now assign the planet the attributes of this prototype
				planetType = pProtoType.getName()							

				Local px:Int = mainStar.getX()+Cos(angle)*(PlanetDistance*ONE_AU)
				Local py:Int = mainStar.getY()+Sin(angle)*(PlanetDistance*ONE_AU)
			
				newPlanet:TPlanet = TPlanet.createFromProto(px,py,Self,planetName,planetType)
				
				newPlanet.setParent(mainStar)
				
				Local populationChance:Int[] = StringToIntArray(pProtoType.getPopulationChance(),",")
				
				' !!
				' population should be affected by the distance from core systems
				' !!
				
				Local planetChoice:Int = Rand(0,populationChance.length-1)			
				planetPopulation = Float(populationChance[planetChoice])				
				planetPopulation:*Rnd(0.7,1.2) ' make it a bit more random...
				
				newPlanet.setPopulation(planetPopulation)
				
				' increase the system's population
				SystemPopulation:+newPlanet.getPopulation()	
				
				DebugLog "		> New planet:"	
				DebugLog "			> Name: "+newPlanet.getName()
				DebugLog "			> Population: "+newPlanet.getPopulation()+" Billion"			
				DebugLog "			> Distance: "+planetDistance+" from main star"
				DebugLog "			> Mass: "+newPlanet.getMass()+" Kg"
				DebugLog "			> Size: "+newPlanet.getSize()
				DebugLog "			> ScaleX/Y: "+newPlanet.getScaleX()
				DebugLog "			> Using proto: "+pProtoType.getName()				
				
				
				Local moonChance:Int[] = [0,0,0,0,0,0,1,2,3,4,5]
				
				Local moonDistance:Float = Rnd(0.4,0.85) ' AUs
				Local numberOfMoons:Int = moonChance[Rand(0,moonChance.length-1)]
								
				DebugLog "			> Number of Moons: "+numberOfMoons
								
				For Local i:Int=0 To numberOfMoons-1					
					Local mProtoType:TProtoBody = TProtoBody(comfortableMoons.valueAtIndex(Rand(0,comfortableMoons.count()-1)))
					
					angle=Rnd(360.0)
					
					' now assign the moon the attributes of this prototype
					Local moonType:String = mProtoType.getName()							
	
					Local px:Int = newPlanet.getX()+Cos(angle)*(moonDistance*ONE_AU)
					Local py:Int = newPlanet.getY()+Sin(angle)*(moonDistance*ONE_AU)
				
					Local newMoon:TPlanet = TPlanet.createFromProto(px,py,Self,planetName+" "+i,moonType) ' name it planet+#
					
					' hack for testing...
					' make it smaller than its parent.
					newMoon.setScaleX(newPlanet.getScaleX()*0.3)
					newMoon.setScaleY(newMoon.getScaleX())
					
					newMoon.setSize(CalcImageSize(newMoon._image, False) * newMoon.GetScaleX())
					
					newMoon.setParent(newPlanet) ' make the moon's parent, the last planet we created
					
					DebugLog "				> New Moon: "+planetName+" "+i
					DebugLog "				> Of Type: "+moonType
					DebugLog "				> At "+moonDistance+" AU from its parent"
					
					moonDistance:+Rnd(0.04,0.3)	' move out!				
				Next			
				
				DebugLog ""
				
			Else
				' either too far or too close to make a planet
			EndIf
					
			Select Rand(1,27)
				Case 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 PlanetDistance:+Rnd(3.4,8.0) ' AUs
				Case 20,21,22,23,24,25,26 PlanetDistance:+Rnd(1.4,16.0) ' AUs
				Case 27 PlanetDistance:+Rnd(19.0, 30.0) ' AUs
			End Select			
		Next
		
		'TAsteroid.createAsteroidBelt(Self,MainStar.getX()+150000, mainStar.getY()+150000, 12000, 100)
		'TAsteroid.createAsteroidsRealistically(Self,MainStar.getX()+150000, mainStar.getY()+150000, 100, 120)
		
		
		' now we calculate the economy, danger level, government and tech level
		' depening on the population		
		Local governmentChance:String[]		
		If SystemPopulation > 40 ' BILLION!				
		ElseIf SystemPopulation > 25		
		ElseIf SystemPopulation > 15		
		ElseIf SystemPopulation > 10		
		ElseIf SystemPopulation > 5		
		ElseIf SystemPopulation > 1		
		ElseIf SystemPopulation > 0.7		
		ElseIf SystemPopulation > 0.1		
		ElseIf SystemPopulation > 0.06		
		ElseIf SystemPopulation > 0.04				
		ElseIf SystemPopulation = 0				
		Else		
		EndIf
		
		_systemHasBeenPopulated = True
  	End Method
	
	Method compileListOfPlanetsAtThisDistance:TList(dis:Float) ' in AUs
		Local l:TList=CreateList()
		For Local i:TProtoBody=EachIn TProtoBody.g_L_ProtoBodies
			If i.getComfortZone().length > 0	' not a sun, suns don't get this assigned by XML			
				Local cz:String = i.getComfortZone()	' should return "0.2-1.4" in AUs
				Local n:String[] = SmartSplit(cz, "-")
				If (dis > n[0].toFloat()) And (dis < n[1].toFloat()) 					
					ListAddLast(l,i)
				EndIf
			EndIf
		Next		
		Return l
	End Method
	
	Method drawSystemQuickly(x:Int, y:Int, width:Int)
		SetColor 0,255,0
		SetAlpha 0.1
		DrawRect x-width/2,y-width/2,width,width
		
		SetColor 255,255,255
		SetAlpha 1
		
		Local d:Double = 0.0
		Local FarthestObject:TStellarObject = getFarthestObjectInSystem(d)
		
		' now squash it down so we can see it all within the width specified
		Local v:Float = d/(width/2)
				
		Local sun:TStar=Self.getMainStar()
		sun._tempX = x
		sun._tempY = y
		
		DrawRect x,y,2,2 ' draw the sun
		
		For Local i:TPlanet = EachIn Self._L_SpaceObjects
			Local d1:Float = Distance(i.GetParent().GetX(), i.GetParent().GetY(), i.GetX(), i.GetY()) / v
			Local a1:Float = DirectionTo(i.GetParent().GetX(), i.GetParent().GetY(), i.GetX(), i.GetY())-180
			Local px:Int = x+Cos(a1)*d1
			Local py:Int = y+Sin(a1)*d1
			
			SetColor 255,255,255
			SetAlpha 0.2
			drawCircle(i.GetParent()._tempX, i.GetParent()._tempY, d1)
			SetAlpha 1			
			SetColor 0,255,0
			DrawRect px-2, py-2, 4, 4
			i._tempX = px
			i._tempY = py								
		Next
		
		For Local i:TShip = EachIn Self._L_SpaceObjects
			Local d1:Float = Distance(sun.GetX(), sun.GetY(), i.GetX(), i.GetY()) / v
			Local a1:Float = DirectionTo(sun.GetX(), sun.GetY(), i.GetX(), i.GetY())-180
			Local px:Int = x+Cos(a1)*d1
			Local py:Int = y+Sin(a1)*d1
			SetAlpha 1			
			SetColor 255,0,0
			DrawRect px-2, py-2, 4, 4
			SetColor 255,255,255								
		Next				
		SetColor 255,255,255
	End Method	
	
	Method getFarthestObjectInSystem:TStellarObject(dis:Double Var)
		' find the farthest planet from the sun
		Local maxDist:Double = 0
		Local sun:TStar=Self.getMainStar()
		Local far:TStellarObject
		
		For Local obj:TStellarObject = EachIn Self._L_SpaceObjects
			If obj<>sun
				Local dist:Double = Distance(sun.GetX(), sun.GetY(), obj.GetX(), obj.GetY())
				If dist > maxDist Then
					far = obj
					maxDist = dist
				EndIf
			EndIf
		Next	
		dis=maxDist
		Return far
	End Method
	
	Method isPopulated:Int()
		Return _systemHasBeenPopulated
	End Method
	
	' set this system as the "active" system (the one the camera is in)
	Method GetName:String()
		Return _Name
	End Method
	
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
	
	Method GetCentralStarType:Int()
		Return _type
	End Method
	
	Method setNumberOfPlanets(m:Int)
		_planets = m
	End Method
	
	Method getNumberOfPlanets:Int()
		Return _planets
	End Method	
	
	' returns the main star of the system
	Method GetMainStar:TStar()
		Return _mainStar
	End Method

	Method SetMainStar(main:TStar)
		_mainStar=main
	End Method

	Method setPlanetChance(m:String)
		_PlanetChance=m
	End Method

	Method getComfortZone:String()
		Return _comfortZone
	End Method

	Method setComfortZone(s:String)
		_comfortZone = s
	End Method

	' returns the system that is currently "active"
	Function GetActiveSystem:TSystem()
		Return _g_ActiveSystem
	End Function
	
	Method Forget()
		' remove all the objects from this system
		For Local i:TSpaceObject = EachIn Self._L_SpaceObjects
			RemoveSpaceObject(i)
		Next
		Self._L_SpaceObjects.clear()		
		_systemHasBeenPopulated=0
	End Method
	
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
