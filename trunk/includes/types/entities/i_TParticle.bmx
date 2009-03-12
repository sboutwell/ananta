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


Type TParticle Extends TMovingObject
	Global g_L_Particles:TList	' list holding all particles
	Field _life:Float			' life of the particle in seconds
	Field _alphaDelta:Float		' alpha change per second
	
	Method SetLife(l:Float) _life = l End Method
	
	Method Update() 
		_life:-1 * G_delta.GetDelta()      			 ' decrement life by 1 frame worth of seconds
		_alpha:-_alphaDelta * G_delta.GetDelta()     ' decrement alpha by alphaDelta
		Super.Update()   ' call Update() of TMovingObject
		If _life <= 0 Then Destroy() 
	End Method
	
	Method Destroy() 
		If _System Then _System.RemoveSpaceObject(Self) 
		If g_L_Particles Then g_L_Particles.Remove(Self) 
	End Method
			
	Function UpdateAndDrawAll() 
		If Not g_L_Particles Then Return
		For Local p:TParticle = EachIn g_L_Particles
			p.Update() 
			'p.DrawBody(viewport) 
		Next
	End Function
	
	Function Create:TParticle(img:TImage, x:Double, y:Double, life:Float, scale:Float, alpha:Float = 0.8, System:TSystem) 
		Local part:TParticle = New TParticle
		part.SetX(x)
		part.SetY(y)
		part.SetLife(life)
		part.SetScaleX(scale)
		part.SetScaleY(scale)
		part.SetOAlpha(alpha)
		part._alphaDelta = alpha / life
		part.isAffectedByGravity = False
		part.isShownOnMap = False
		part._image = img
		part._System = System
		
		If Not g_L_Particles Then g_L_Particles = CreateList() 
		g_L_particles.AddLast(part) 
		
		If System Then System.AddSpaceObject(part) 
		
		Return part
	EndFunction
EndType

Type TParticleGenerator Extends TMovingObject
	Field _life:Float			' life of the particle in seconds
	Field _meanVel:Float 		' base velocity of an emitted particle
	Field _randomDir:Float = 0	' amount of randomness to the direction of the particle
	Field _randomVel:Float = 0	' amount of randomness to the velocity of the particle
	Field _particleImg:TImage	' the image that is drawn in place of this particle
	Field _interval:Int			' particles emitting interval in ms
	Field _lastEmit:Int			' last emit in MilliSecs()
	
	Method Emit(vel:Float = Null) 
		If Not vel Then vel = _meanVel
		
		Local part:TParticle = TParticle.Create(_particleImg, _x, _y, _life, _scaleX, _alpha, _System) 
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
	
	Method Destroy() 
		
	End Method
	
	Function Create:TParticleGenerator(img:String, x:Float, y:Float, System:TSystem, life:Float = 0.5, alpha:Float = 0.8, vel:Float = 4, scale:Float = 1, rot:Float = 90) 
		Local pg:TParticleGenerator = New TParticleGenerator
		pg._particleImg = TImg.LoadImg(img) 
		pg._x = x
		pg._y = y
		pg._System = System		' the solar system this generator is in
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

Type TProjectile Extends TParticle	' projectile is a special type of particle
	Field _damage:Float = 500	' damage this particle will do on impact
	Field _shotBy:TShip = Null	' the ship that shot this projectile
	
	Method GetDamage:Float() Return _damage * _alpha End Method
	Method GetShooter:TShip() Return _shotBy EndMethod
	Method SetShooter(sh:TShip) _shotBy = sh End Method
	
	Method Destroy() 
		_shotBy = Null
		Super.Destroy()  ' call destroy() of TParticle
	End Method
	
	
	Method Explode() 
		' a makeshift "explosion" effect for testing
		If Not _system Then Return
		Local expScale:Float = CalcImageSize(_image) / 128.0 * _scaleX * 2
		Local part:TParticle = TParticle.Create(TImg.LoadImg("smoke.png"), _x, _y, 0.5, expScale, 1, _System) 
		part.SetXVel(_xVel) 
		part.SetYVel(_yVel) 
		part.SetRot(Rand(0, 360)) 
		part.SetRotationSpd(Self.GetRotSpd() + Rnd(- 100, 100)) 
		 
		Destroy() 
	End Method

	Function Create:TProjectile(img:TImage, x:Double, y:Double, life:Float, scale:Float, alpha:Float = 1, System:TSystem) 
		Local part:TProjectile = New TProjectile
		part._x = x
		part._y = y
		part._life = life
		part._scaleX = scale
		part._scaleY = scale
		part._alpha = alpha
		part._alphaDelta = alpha / life
		part.isAffectedByGravity = False
		part.isShownOnMap = True
		part._image = img
		part._System = System
		part._size = 2
		part._mass = 500
		
		If Not g_L_Particles Then g_L_Particles = CreateList() 
		g_L_particles.AddLast(part) 
		
		System.AddSpaceObject(part) 
		
		Return part
	End Function
EndType
