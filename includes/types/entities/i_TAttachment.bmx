rem
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

rem
	Attachments are visual add-ons attached to a space object's hull: weapons, engines, etc.
	Note that TAttachment is used for "visual-only" attachments. All spaceobjects can be attached
	to another spaceobject as such without being declared as actual attachments.
endrem

Type TAttachment Extends TSpaceObject
	Method Destroy() 
			
	End Method

	Function Create:TAttachment(parent:TSpaceObject, image:String, x:Float = 0, y:Float = 0, rot:Float = 0, scaleX:Float = 0, scaleY:Float = 0, onTop:Int = True) 
		Local a:TAttachment = New TAttachment
		parent.AddAttachment(a, x, y, rot, onTop) 
		a._image = TImg.LoadImg(image) 
		a._scaleX = scaleX
		a._scaleY = scaleY
		Return a
	End Function
End Type