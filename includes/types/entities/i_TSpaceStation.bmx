' not used
Type TSpaceStation Extends TStellarObject
	Method Destroy() 
		
	End Method

	Function Create:TSpaceStation(x:Int,y:Int,System:TSystem,mass:Long,size:Int,name:String)
		Local ss:TSpaceStation = New TSpaceStation	' create an instance
		ss._name = name										' give a name
		ss._x = x; ss._y = y									' coordinates
		ss._System = System									' the System
		ss._mass = mass										' mass in kg
		ss._size = size										' size in pixels
		ss._hasGravity = False
		ss._canCollide = True
		ss._isShownOnMap = True
		
		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()		' create a list if necessary
		g_L_StellarObjects.AddLast ss												' add the newly created object to the end of the list
		
		System.AddSpaceObject(ss)		' add the body to System's space objects list
		
		Return ss																			' return the pointer to this specific object instance
	EndFunction
EndType
