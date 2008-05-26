' Not used
Type TJumpPoint Extends TSpaceObject
	Global g_L_JumpPoints:TList		' a list to hold all JumpPoints
	Field _destinationJp:TJumpPoint	' the connected JumpPoint
	
	Method Destroy() 
		
	End Method
	
	Function Create:TJumpPoint(x:Int,y:Int,System:TSystem,destination:TJumpPoint)
		Local jp:TJumpPoint = New TJumpPoint		' create an instance
		jp._x = x; jp._y = y						' coordinates
		jp._System = System									' the System
		jp._destinationJp = destination					' the destination JumpPoint
		jp._isShownOnMap = True
		
		If Not g_L_JumpPoints Then g_L_JumpPoints = CreateList()	' create a list if necessary
		g_L_JumpPoints.AddLast jp											' add the newly created object to the end of the list

		System.AddSpaceObject(jp) 		' add the jumppoint to the System's space object list

		Return jp																		' return the pointer to this specific object instance
	EndFunction
EndType
