rem
	Attachments are visual add-ons attached to a space object's hull: weapons, engines, etc.
	Note that TAttachment is used for "visual-only" attachments. All spaceobjects can be attached
	to another spaceobject
endrem

Type TAttachment Extends TSpaceObject
	
	Function Create:TAttachment(parent:TSpaceObject, image:String, x:Float = 0, y:Float = 0, rot:Float = 0, scaleX:Float = 0, scaleY:Float = 0, onTop:Int = True) 
		Local a:TAttachment = New TAttachment
		parent.AddAttachment(a, x, y, rot, onTop) 
		a._image = TImg.LoadImg(image) 
		a._scaleX = scaleX
		a._scaleY = scaleY		
		Return a
	End Function
End Type