Type TAsteroid Extends TMovingObject
	Global g_L_Asteroids:TList
	Global g_nrAsteroids:Int
	
	Method Destroy() 
		' remove the asteroid from all lists so that GC can delete the object
		g_L_Asteroids.Remove(Self) 
		Self._System.RemoveSpaceObject(Self) 
		g_L_MovingObjects.Remove(Self) 
		g_nrAsteroids:-1
	End Method
	
	' destructor, called automatically by GC
	Method Delete() 
		DebugLog "Asteroid deleted by GC"
	End Method
	
	Function Create:TAsteroid(img:String, System:TSystem, x:Float, y:Float, mass:Long) 
		Local a:TAsteroid = New TAsteroid
		a._image = TImg.LoadImg(img) 
		a._mass = mass
		a._System = System
		a._x = x
		a._y = y
		a._isShownOnMap = True
		a._canCollide = True
		a._affectedByGravity = True
		a._integrity = mass
		
		If Not g_L_Asteroids Then g_L_Asteroids = CreateList() 
		g_L_Asteroids.AddLast(a) 
		g_nrAsteroids:+1
		
		If Not g_L_MovingObjects Then g_L_MovingObjects = CreateList() 
		g_L_MovingObjects.AddLast(a) 
		
		System.AddSpaceObject(a) 
		
		Return a
	End Function
EndType
