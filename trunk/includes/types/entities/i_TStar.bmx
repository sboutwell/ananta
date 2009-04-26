Type TStar Extends TStellarObject
	
	Method Destroy() 
		Print "Star " + _name + " GC'd"
	End Method

	' uses Cairo vector graphics library to generate a star image of a radius supplied by a parameter
	' Star color is supplier by "inner" and "outer" RGB double values (0..1) to produce a stepless radial gradient
	Function GenerateStarTexture:TImage(r:Int, i_r:Double, i_g:Double, i_b:Double, o_r:Double, o_g:Double, o_b:Double)
		Local cairo:TCairo = TCairo.Create(TCairoImageSurface.CreateForPixmap(r * 2, r * 2)) 
	
		Local normalizeMat:TCairoMatrix = TCairoMatrix.CreateScale(r * 2, r * 2) 
		cairo.SetMatrix(normalizeMat) 
		
		Local pat:TCairoPattern = TCairoPattern.CreateRadial (0.5, 0.5, 6, 0.5, 0.5, 30) 
		' outer gradient color
		pat.AddColorStopRGBA(1, o_r, o_g, o_b, 1)
		' inner gradient color
		pat.AddColorStopRGBA(0, i_r, i_g, i_b, 1) 
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
	
	Function GenerateVectorTextures() 
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.95, 0.95, 0, 1, 1, 0.5) , "star_gen_yellow")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.45, 0.05, 0.05, 0.8, 0.3, 0.3) , "star_gen_red")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.5, 0.5, 0.5, 0.7, 0.7, 0.7) , "star_gen_silver")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.95, 0.95, 0.95, 0.7, 0.7, 0.8) , "star_gen_white")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.9, 0.6, 0.1, 0.45, 0.35, 0.05) , "star_gen_orange")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.7, 0.4, 0.15, 0.3, 0.3, 0.03) , "star_gen_brown")
		TImg.StoreImg(TStar.GenerateStarTexture(1024, 0.3, 0.01, 0.01, 0.15, 0.01, 0.0) , "star_gen_faintred")
	End Function
	
	Function createFromProto:TStar(x:Int,y:Int, System:TSystem, name:String)
		Local st:TStar = New Tstar				' create an instance
		st._name = name							' give a name
		st._x = x; st._y = y					' coordinates
		st._System = System						' the System
		
		' now use the system's "_type" field to generate its main star
		' there are 9 types of star, sun0, sun1, sun2, etc..
		
		TProtoBody.populateBodyFromName(st, "sun"+system.GetCentralStarType())
				
		st.hasGravity = True
		st.canCollide = True
		st.isShownOnMap = True

		'If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		'g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

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
		st.hasGravity = True
		st.canCollide = True
		st.ResetCollisionLevels()
		st.isShownOnMap = True

		'If Not g_L_StellarObjects Then g_L_StellarObjects = CreateList()	' create a list if necessary
		'g_L_StellarObjects.AddLast st									' add the newly created object to the end of the list

		System.AddSpaceObject(st)		' add the body to System's space objects list
		
		Return st																' Return the pointer To this specific Object instance
	EndFunction
EndType
