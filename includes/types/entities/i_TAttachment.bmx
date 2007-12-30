rem
	Attachments are visual 'add-ons' attached to a space object's hull: weapons, engines, etc.
endrem

Type TAttachment Extends TSpaceObject
	Field _parent:TSpaceObject	' the parent object the attachment is attached to
	Field _position:Int = 1 	' 1 = on top of the parent object, 0 = below the parent object
	Field _xOffset:Float 		' x-position of the attachment compared to the x of the parent
	Field _yOffset:Float 		' y-position of the attachment compared to the y of the parent
	
	Method GetPosition:Int() 
		Return _position
	End Method
	
	
	Function Create:TAttachment(parent:TSpaceObject, x:Float = 0, y:Float = 0) 
		Local a:TAttachment = New TAttachment
		a._parent = parent
		a._xOffset = x
		a._yOffset = y
		Return a
	End Function
End Type