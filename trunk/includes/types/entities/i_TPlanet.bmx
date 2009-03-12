Type TPlanet Extends TStellarObject
	Field _Population:Float 		' population of this planet in billions
	
	Method setPopulation(b:Float)
		_Population = b
	End Method
	
	Method getPopulation:Float()
		Return _Population
	End Method
	
	Method Destroy() 
		
	End Method

	Function createFromProto:TPlanet(x:Int,y:Int,System:TSystem,name:String,planetType:String)
		Local pl:TPlanet = New TPlanet					' create an instance
		pl._name = name										' give a name
		pl._x = x; pl._y = y									' coordinates
		pl._System = System									' the System
		
		TProtoBody.populateBodyFromName(pl, planetType)		
		
		pl.hasGravity = True
		pl.canCollide = True
		pl.isShownOnMap = True
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast pl											' add the newly created object to the end of the list
		
		System.AddSpaceObject(pl)		' add the body to System's space objects list
		
		Return pl																' return the pointer to this specific object instance
	EndFunction	
	
	' defunct
	Function Create:TPlanet(x:Int,y:Int,System:TSystem,mass:Long,size:Int,name:String)
		Local pl:TPlanet = New TPlanet					' create an instance
		pl._name = name										' give a name
		pl._x = x; pl._y = y									' coordinates
		pl._System = System									' the System
		pl._mass = mass										' mass in kg
		pl._size = size										' size in pixels
		pl.hasGravity = True
		pl.canCollide = True
		pl.isShownOnMap = True
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast pl											' add the newly created object to the end of the list
		
		System.AddSpaceObject(pl)		' add the body to System's space objects list
		
		Return pl																' return the pointer to this specific object instance
	EndFunction
		
EndType
