Type TAsteroid Extends TMovingObject
	Global g_L_Asteroids:TList
	Global g_nrAsteroids:Int
	
	
	Method Destroy() 
		' remove the asteroid from all lists so that GC can delete the object
		g_L_Asteroids.Remove(Self) 
		_System.RemoveSpaceObject(Self) 
		g_L_MovingObjects.Remove(Self) 
		g_nrAsteroids:-1
	End Method
	
	' destructor, called automatically by GC
	Method Delete() 
		DebugLog "Asteroid deleted by GC"
	End Method
	
	
	Function createAsteroidsRealistically(system:TSystem,x:Int, y:Int, radius:Int, number:Int)
		
		Local asteroidImage:TImage=TImg.LoadImg("asteroid.png")
		
		Local positionImage:String = "media/asteroid placement/"+Rand(1,15)+".png"
		
		Local pix:TPixmap = LoadPixmap(positionImage)
		Local w:Int = PixmapWidth(pix)
		Local map:Int[w,w]
		
		Local none:Int = (255 Shl 24) | (0 Shl 16) | (0 Shl 8) | 255
		Local sparse:Int = (255 Shl 24) | (128 Shl 16) | (255 Shl 8) | 0
		Local normal:Int = (255 Shl 24) | (0 Shl 16) | (255 Shl 8) | 0
		Local high:Int = (255 Shl 24) | (136 Shl 16) | (136 Shl 8) | 136
		Local dense:Int = (255 Shl 24) | (170 Shl 16) | (170 Shl 8) | 170
		Local most:Int = (255 Shl 24) | (255 Shl 16) | (255 Shl 8) | 255
			
		For Local vx:Int=0 To w-1
			For Local vy:Int=0 To w-1
				map[vx,vy]=ReadPixel(pix,vx,vy)
			Next
		Next
		
		For Local i:Int = 1 To number
			While True
				' choose a random position in the image
				Local rx:Int = Rand(0,w-1)
				Local ry:Int = Rand(0,w-1)
				
				Local rgba:Int = map[rx,ry]
			
				If rgba <> none
					Local go:Int = False
				
					Local scale:Float = Rnd(0.2, 4)
				
					Select rgba
						Case sparse 	If Rand(1,80)=1 go=True;scale= Rnd(0.9, 1.1)
						Case normal 	If Rand(1,60)=1 go=True;scale= Rnd(0.6, 1.0)
						Case high 		If Rand(1,30)=1 go=True;scale= Rnd(0.2, 0.5)
						Case dense 		If Rand(1,17)=1 go=True;scale= Rnd(0.1, 0.5)
						Case most 		If Rand(1,5)=1 go=True;	scale= Rnd(0.07, 0.1)
					End Select
				
					If go
						' create the asteroid and place it here.					
						 
						If Rand(1,20)=1 scale=Rnd(0.8,1.8) ' big ones!					
						Local size:Int = CalcImageSize(asteroidImage, False) * scale
						Local mass:Long = (scale ^ 2) * Rand(3000, 10000) 					
											
						Local px:Int = x + (radius * rx) + Rand(-120,120)
						Local py:Int = y + (radius * ry) + Rand(-120,120)
											
						Local ast:TAsteroid = TAsteroid.Create("asteroid.png", System, px, py, mass) 
						ast._scaleX = scale
						ast._scaleY = scale
						ast._size = size
						ast.SetRotationSpd(Rand(- 20, 20)) 	
						
						If Rand(1,12)=1 ast.SetRotationSpd(Rand(- 800, 800)) 				
						Exit
					EndIf
				EndIf			
			Wend		
		Next
		
		map=Null
		pix=Null
		'image=Null		
	End Function
	
	Function createAsteroidBelt(system:TSystem,x:Int, y:Int, radius:Int, number:Int)
	
		Local asteroidImage:TImage=TImg.LoadImg("asteroid.png")
	
		For Local i:Int = 1 To number
			Local scale:Float = Rnd(0.2, 4) 
			If Rand(1,8)=1 scale=Rnd(4,8) ' big ones!
			
			Local size:Int = CalcImageSize(asteroidImage, False) * scale
			Local mass:Long = (scale ^ 2) * Rand(3000, 10000) 
			
			Local angle:Float = Rnd(360)
			Local dis:Float = Rnd(1,radius*2)
			
			Local px:Int = x+Cos(angle)*dis
			Local py:Int = y+Sin(angle)*dis
			
			Local ast:TAsteroid = TAsteroid.Create("asteroid.png", System, px, py, mass) 
			ast._scaleX = scale
			ast._scaleY = scale
			ast._size = size
			ast.SetRotationSpd(Rand(- 20, 20)) 	
			
			If Rand(1,12)=1 ast.SetRotationSpd(Rand(- 800, 800)) 
		Next		
	End Function
	
	
	Function Create:TAsteroid(img:String, System:TSystem, x:Float, y:Float, mass:Long) 
		Local a:TAsteroid = New TAsteroid
		a._image = TImg.LoadImg(img) 
		a._mass = mass
		a._System = System
		a._x = x
		a._y = y
		a.isShownOnMap = True
		a.canCollide = True
		a.isAffectedByGravity = True
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
