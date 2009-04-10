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

Rem
	*************************************************************************************************
	***************************************** SPACEOBJECTS ******************************************
	*************************************************************************************************
	Description: All drawable objects that can exist in a star System

	TSpaceObject				/Includes/types/Entities/i_TSpaceObject.bmx
		TJumpPoint				/Includes/types/Entities/i_TJumpPoint.bmx
		TStellarObject			/Includes/types/Entities/i_TStellarObject.bmx
			TStar				/Includes/types/Entities/i_TStar.bmx
			TPlanet				/Includes/types/Entities/i_TPlanet.bmx
			TSpaceStation		/Includes/types/Entities/i_TSpaceStation.bmx
		TMovingObject			/Includes/types/Entities/i_TMovingObject.bmx
			TShip				/Includes/types/Entities/i_TShip.bmx
			TAsteroid			/Includes/types/Entities/i_TAsteroid.bmx
			TParticle			/Includes/types/Entities/i_TParticle.bmx
				TProjectile		""
			 
EndRem

' types directly related to TSpaceObjects
Include "i_TAttachment.bmx"
Include "i_TParticle.bmx"
Include "i_TMovingObject.bmx"	'All spaceborne moving objects
Include "i_TStellarObject.bmx"	'TStellarObject
Include "i_TShip.bmx"			'TShip Object
Include "i_TPlanet.bmx"			'TPlanet type
Include "i_TStar.bmx"			'TStar type
Include "i_TAsteroid.bmx"		'TAsteroid type

Type TSpaceObject Abstract
	Field _image:TImage					' The image to represent the object
	Field _alpha:Float = 1				' Alpha channel value of the image
	Field _x:Double, _y:Double			' x-y coordinates of the object
	Field _system:TSystem				' the system the object is in
	Field _rotation:Float				' rotation in degrees
	Field _mass:Long					' The mass of the object in kg
	Field _size:Int						' The visual diameter of the object, to display the object in correct scale in the minimap
	Field _scaleX:Float = 1				' The scale of the drawn image (1 being full resolution, 2 = double size, 0.5 = half size)
	Field _scaleY:Float = 1				
	Field _name:String = "Nameless"		' The name of the object
	Field isShownOnMap:Int = False		' flag to indicate minimap visibility
	Field hasGravity:Int	= False			' a true-false flag to indicate gravitational pull
	Field _xVel:Double						' velocity vector x-component
	Field _yVel:Double						' velocity vector y-component
	Field _rotationSpd:Float				' rotation speed in degrees per second
	Field isAffectedByGravity:Int = True		' does gravity affect the object?
	Field canCollide:Int = False			' flag to indicate if this object can collide with any other object
	Field isUpdated:Int = False			' a flag to indicate if this object has been updated during the frame
	Field _integrity:Float = -1			' the amount of damage the object can handle, -1 for indestructible
	Field _description:String			' a description of the body (planet with high winds, asteroidal body, etc)
	
	' used for TSystem.drawSystemQuickly()
	Field _parent:TStellarObject
	Field _tempX:Int,_tempY:Int			' store drawn position for children planets to be drawn around. speed fix.
	' -----------------------------------|
	
	' used for random effects
	Field _minScale:Float,_maxScale:Float
		
	' attachment-related fields
	Field _L_TopAttachments:TList		' top attachments to the object	(visually above this object)
	Field _L_BottomAttachments:TList	' bottom attachments to the object (visually below this object)
	Field _parentObject:TSpaceObject	' the parent object this object is attached to, if applicable
	Field _xOffset:Float = 0			' x-position of the attachment compared to the x of the parent
	Field _yOffset:Float = 0			' y-position of the attachment compared to the y of the parent
	Field _rotationOffset:Float 		' rotation compared to the parent rotation
	
	' these fields would probably be more appropriate in TMovingObject, but they're here for optimization purposes (to get rid of the need for type casting)
	Field _strongestGravSource:TSpaceObject	' strongest gravity source is updated for warp drive purposes
	Field _strongestGravity:Double = 0		' the gravitational acceleration exerted by the strongest gravsource

	Field _collisionLevels:Int[] ' array of integers showing the object levels this object can collide with
	
	Method Destroy() Abstract
	
	' make the object take some damage
	Method SustainDamage(dam:Float) 
		If _integrity = -1 Then Return		' indestructible	
		_integrity = _integrity - dam		' She can't take much more o' this, cap'n!
		If _integrity <= 0 Then Explode()   ' My god, cap'n, she's gonna blow!
	End Method
	
	Method Explode() 
		' a makeshift "explosion" effect for testing. Redo this with some pretty particle fireworks.
		Local expScale:Float = CalcImageSize(_image) / 128.0 * _scaleX * 1.5
		Local part:TParticle = TParticle.Create(TImg.LoadImg("smoke.png"), _x, _y, 2, expScale, 1, _System) 
		part.SetXVel(_xVel) 
		part.SetYVel(_yVel) 
		part.SetRot(Rand(0, 360)) 
		part.SetRotationSpd(Self.GetRotSpd() + Rnd(- 10, 10)) 
		part.isAffectedByGravity = True
		 
		Destroy() 
		
	End Method
		
	' draws the body of the spaceobject
	Method DrawBody(vp:TViewport, drawAsAttachment:Int = False)
		If Not _image Then Return	' don't draw if no image is defined
		
		' don't draw the object if it's an attachment 
		' to another object but the method was NOT called with the drawAsAttachment flag on
		If Not drawAsAttachment And _parentObject Then Return
		
		' draw bottom attachments if any
		If _L_BottomAttachments Then
			For Local a:TSpaceObject = EachIn _L_BottomAttachments
				a.Update() 
				a.DrawBody(vp, True) 
			Next
		EndIf
		
		' ********* preload values that are used more than once
		Local startX:Int = vp.GetStartX() 
		Local startY:Int = vp.GetStartY()
		Local midX:Int = vp.GetMidX()
		Local midY:Int = vp.GetMidY()
		' *********
		Local x:Double = (vp.GetCameraPosition_X() - _x) * G_viewport.GetZoomFactor() + midX + startX
		Local y:Double = (vp.GetCameraPosition_Y() - _y) * G_viewport.GetZoomFactor() + midY + startY
		
		' This commented code block is trying to define if the object will be visible on the screen to avoid
		' drawing non-visible objects. Not working. So, in the meantime we'll suffer from a performance hit.
		
		'Local zoom:Float = viewport.GetZoomFactor()
		'If x + (_size * (_scaleX * zoom) / 2) < startX Then Return
		'If x - (_size * (_scaleX * zoom) / 2) > startX + vp.GetWidth() Then Return
				
		SetViewport(startX, startY, vp.GetWidth(), vp.GetHeight()) 
		'SetViewport(0, 0, 800, 600) 
		SetAlpha _alpha
		SetRotation _rotation + 90
		SetBlend ALPHABLEND
		SetColor 255,255,255
		SetScale _scaleX * G_viewport.GetZoomFactor(), _scaleY * G_viewport.GetZoomFactor()
		
		DrawImage _image, x, y
		
		' draw top attachments if any
		If _L_TopAttachments Then
			For Local a:TSpaceObject = EachIn _L_TopAttachments
				a.Update() 
				a.DrawBody(vp, True) 
			Next
		EndIf
		
		
		' ***** temp for AI test
		If TShip(self) And ..
			TAIPlayer(Tship(self).GetPilot()) Then ..
			TAIPlayer(TShip(self).GetPilot()).DrawAIVectors()
		' *****
	EndMethod

	' this update method is currently mainly for attachment positioning purposes...
	Method Update() 
		If _parentObject Then	' is attached to another object...
			_system = _parentObject.GetSystem() ' update TSystem in case the ship with attachements has hyperspaced
			Local pRot:Float = _parentObject.GetRot() 
			Local pX:Double = _parentObject.GetX() 
			Local pY:Double = _parentObject.GetY() 
			_x = pX + _xOffset * Cos(pRot) + _yOffset * Sin(pRot)
			_y = pY + _xOffset * Sin(pRot) - _yOffset * Cos(pRot) 
			_rotation = pRot + _rotationOffset
		EndIf
		isUpdated = True
	End Method
	
	' attach another object. Attached objects cannot move themselves.
	Method AddAttachment(obj:TSpaceObject, xo:Float = 0, yo:Float = 0, roto:Float = 0, onTop:Int = True) 
		obj.setParentObject(Self)
		obj._xOffset = xo
		obj._yOffset = yo
		obj._rotationOffset = roto
		
		If Not _L_TopAttachments Then _L_TopAttachments = CreateList() 
		If Not _L_BottomAttachments Then _L_BottomAttachments = CreateList() 
		If onTop Then _L_TopAttachments.AddLast(obj) 
		If Not onTop Then _L_BottomAttachments.AddLast(obj) 
		
		' add the mass to this object's total mass
		_mass:+obj.GetMass() 
		
		' if the parent object is a ship, update ship's performance values
		If TShip(Self) Then	' type-casting
			Local ship:TShip = TShip(Self) 
			ship.UpdatePerformance() 
		End If
	End Method
	
	' this method will populate this types from an XML file
	' eg: newPlanet.getInfoFromXML(c_celestialTypes, "stars", "sun1")
	' eg: newPlanet.getInfoFromXML(c_celestialTypes, "planets", "rocky1")
	Rem
	
	Method getInfoFromXML(Conf:String, node:String, value:String)
		Local sourceNode:TxmlNode = LoadXMLFile(conf)
		
		Local searchnode:TxmlNode = xmlGetNode(sourceNode, node)
		
		Local children:TList = searchnode.getChildren() 		
	
		For Local value1:TxmlNode = EachIn children	' iterate through node values
			If value1.GetName() = value
				If value.GetName() = "image"	Then c._image	= TImg.LoadImg(value.GetText()) ' Should be self.setImage(file$)	
				If value.GetName() = "description" 	Then c._description		= value.GetText()
				If value.GetName() = "mass" 	Then c._mass	= value.GetText().ToFloat()
				If value.GetName() = "minscale" Then c._minScale= value.GetText().ToFloat()
				If value.GetName() = "maxscale" Then c._maxScale= value.GetText().ToFloat()
				
				Return				
			EndIf
		Next		
		
	End Method	
	
	EndRem

	Method GetScaleX:Float()
		Return _scaleX
	End Method

	Method GetScaleY:Float()
		Return _scaleY
	End Method
	
	Method GetVel:Double() 
		If (NOT _xVel or NOT _yVel) or (_xVel = 0 and _yVel = 0) Return 0
		Return GetSpeed(_xVel, _yVel) 
	End Method
	
	Method GetXVel:Double() 
		Return _xVel
	End Method
	
	Method GetYVel:Double() 
		Return _yVel
	End Method
	
	Method GetRotSpd:Float()
		Return _rotationSpd
	End Method
	
	Method GetSize:Int()
		Return _size
	End Method
	
	Method GetSystem:TSystem()
		Return _system
	End Method
	
	Method SetXVel(x:Double) 
		_xVel = x
	End Method
	
	Method SetYVel(y:Double) 
		_yVel = y
	End Method
	
	Method SetRotationSpd(r:Float) 
		_rotationSpd = r
	End Method
		
	Method SetRot(r:Float) 
		_rotation = r
	End Method
	
	Method SetSystem(s:TSystem)
		_system = s
	End Method
	
	Method SetOAlpha(a:Float)
		_alpha = a
	End Method
	
	Method GetOAlpha:Float()
		Return _alpha
	End Method
	
	Method GetMass:Long() 
		Return _mass
	End Method
	
	Method GetRot:Float()
		Return _rotation
	End Method

	Method GetX:Double() 
		Return _x
	End Method
	
	Method GetY:Double() 
		Return _y
	End Method

	Method GetIntegrity:Float() 
		Return _integrity
	End Method
	
	Method showsOnMap:Int() 
		Return isShownOnMap
	End Method
	
	Method SetX(coord:Double) 
		_x = coord
	End Method
	
	Method SetY(coord:Double) 
		_y = coord
	End Method
	
	Method SetScaleX(s:Float)
		_scaleX = s
	End Method
	
	Method SetScaleY(s:Float)
		_scaleY = s
	End Method

	Method SetName(s:String) 
		_name = s
	End Method
	
	Method SetMass(m:Long)
		_mass = m
	End Method

	Method SetParentObject(p:TSpaceObject)
		_parentObject = p
	End Method

	Method setParent(p:TStellarObject)
		_parent = p
	End Method
	
	Method GetParent:TStellarObject()
		Return _parent
	End Method	
	
	Method GetParentObject:TSpaceObject()
		Return _parentObject
	End Method
	
	Method LoadImage(file:String)
		If FileSize(file)
			_image = TImg.LoadImg(file)
		Else
			' could not find image, load default
			If G_Debug Print "Could not find image "+file+" for stellar body "+GetName()			
			'TImg.LoadImg("no_image_generated")
		EndIf
	End Method	
	
	Method getImage:TImage()
		Return _image
	End Method
	
	Method setDescription(m:String)
		_description = m
	End Method	
	
	Method getName:String()
		Return _name
	End Method
	
	Method SetSize(s:Int)
		_size=s
	End Method	
EndType

