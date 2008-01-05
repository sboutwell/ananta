
Type TParticle Extends TMovingObject
	Global g_L_Particles:TList	' list holding all particles
	Field _life:Float			' life of the particle in seconds
	Field _alphaDelta:Float		' alpha change per second
	
	Method Update() 
		_life:-1 * G_delta.GetDelta()      			 ' decrement life by 1 frame worth of seconds
		_alpha:-_alphaDelta * G_delta.GetDelta()     ' decrement alpha by alphaDelta
		If _life <= 0 Then Destroy() 
		Super.Update()   ' call Update() of TMovingObject
	End Method
	
	Method Destroy() 
		If g_L_Particles Then g_L_Particles.Remove(Self) 
	End Method
	
	Function DestroyAll() 
		If g_L_Particles Then g_L_Particles.Clear() 
	End Function
		
	Function UpdateAndDrawAll() 
		If Not g_L_Particles Then Return
		For Local p:TParticle = EachIn g_L_Particles
			p.Update() 
			p.DrawBody(viewport) 
		Next
	End Function
	
	Function Create:TParticle(img:TImage, x:Float, y:Float, life:Float, scale:Float, alpha:Float = 0.8) 
		Local part:TParticle = New TParticle
		part._x = x
		part._y = y
		part._life = life
		part._scaleX = scale
		part._scaleY = scale
		part._alpha = alpha
		part._alphaDelta = alpha / life
		part._affectedByGravity = False
		part._isShownOnMap = False
		part._image = img
	
		If Not g_L_Particles Then g_L_Particles = CreateList() 
		g_L_particles.AddLast(part) 
		
		Return part
	EndFunction
EndType

Type TParticleGenerator Extends TMovingObject
	Field _life:Float			' life of the particle in seconds
	Field _meanVel:Float 		' velocity of an emitted particle
	Field _randomDir:Float = 0	' amount of randomness to the direction of the particle
	Field _randomVel:Float = 0	' amount of randomness to the velocity of the particle
	Field _particleImg:TImage
	
	Method Emit(vel:Float = Null) 
		If Not vel Then vel = _meanVel
		
		Local part:TParticle = TParticle.Create(_particleImg, _x, _y, _life, _scaleX, _alpha) 
		Local randDir:Float = Rand(- _randomDir, _randomDir) 
		Local randVel:Float = Rand(- _randomVel, _randomVel) 
		part.SetXVel(_xVel - (vel + randVel) * Cos(_rotation + randDir)) 
		part.SetYVel(_yVel - (vel + randVel) * Sin(_rotation + randDir)) 
		part._rotation = _rotation
	End Method
	
	Method SetRandomDir(dir:Float) 
		_randomDir = dir
	End Method
	
	Method SetRandomVel(vel:Float) 
		_randomVel = vel
	End Method
	
	Function Create:TParticleGenerator(img:String, x:Float, y:Float, sector:TSector, life:Float = 0.5, alpha:Float = 0.8, vel:Float = 4, scale:Float = 1, rot:Float = 90) 
		Local pg:TParticleGenerator = New TParticleGenerator
		pg._particleImg = TImg.LoadImg(img) 
		pg._x = x
		pg._y = y
		pg._sector = sector
		pg._meanVel = vel
		pg._life = life
		pg._alpha = alpha
		pg._scaleX = scale
		pg._scaleY = scale
		pg._rotation = rot
		If Not TMovingObject.g_L_MovingObjects Then TMovingObject.g_L_MovingObjects = CreateList() 
		TMovingObject.g_L_MovingObjects.AddLast(pg) 
		Return pg
	End Function
EndType
