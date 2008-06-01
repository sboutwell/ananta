Type TStar Extends TStellarObject
	
	Method Destroy() 
		
	End Method

	' uses Cairo vector graphics library to generate a star image of a radius supplied by a parameter
	Function GenerateStarTexture:TImage(r:Int) 
		Local cairo:TCairo = TCairo.Create(TCairoImageSurface.CreateForPixmap(r * 2, r * 2)) 
	
		Local normalizeMat:TCairoMatrix = TCairoMatrix.CreateScale(r * 2, r * 2) 
		cairo.SetMatrix(normalizeMat) 
		
		Local pat:TCairoPattern = TCairoPattern.CreateRadial (0.5, 0.5, 6, 0.5, 0.5, 30) 
		pat.AddColorStopRGBA(1, 1, 1, 0.5, 1) 
		pat.AddColorStopRGBA(0, 0.95, 0.95, 0, 1) 
		cairo.SetSource(pat) 
		cairo.Arc(0.5, 0.5, 0.5, 0, 360) 
		cairo.Fill() 
			
		' fix fill color to current
		cairo.Fill() 
		
		' Retrieve the image data from the pixmap
		Local image:TImage = LoadImage(TCairoImageSurface(cairo.getTarget()).pixmap()) 
		
		' destroy context and resources
		cairo.Destroy() 
	
		Return image
	End Function
	
	Function createFromProto:TStar(x:Int,y:Int, System:TSystem, name:String)
		Local st:TStar = New Tstar				' create an instance
		st._name = name							' give a name
		st._x = x; st._y = y					' coordinates
		st._System = System						' the System
		
		' now use the system's "_type" field to generate its main star
		' there are 9 types of star, sun0, sun1, sun2, etc..
		
		TProtoBody.populateBodyFromName(st, "sun"+system.GetCentralStarType())
				
		st._hasGravity = True
		st._canCollide = True
		st._isShownOnMap = True

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

		System.AddSpaceObject(st)		' add the body to System's space objects list		
		Return st		
	End Function
	
	' outdated.	
	Function Create:TStar(x:Int=0,y:Int=0,System:TSystem,mass:Long,size:Int,name:String)
		Local st:TStar = New Tstar				' create an instance
		st._name = name								' give a name
		st._x = x; st._y = y							' coordinates
		st._System = System							' the System
		st._mass = mass								' mass in kg
		st._size = size								' size in pixels
		st._hasGravity = True
		st._canCollide = True
		st._isShownOnMap = True

		If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

		System.AddSpaceObject(st)		' add the body to System's space objects list
		
		Return st																' Return the pointer To this specific Object instance
	EndFunction
EndType
