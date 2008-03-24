SuperStrict

Framework brl.d3d7max2d
Import brl.standardio
Import brl.Pixmap
Import brl.pngloader
SetGraphicsDriver D3D7Max2DDriver() 
Graphics(1024, 1024) 

Include "mway.bmx"

TUni.LoadGalaxy("galaxy.png") 


Local pix:TPixmap = CreatePixmap(1025, 1025, PF_I8) 
Local x:Int = 1
Local y:Int = 1


For Local Pos:Int = 0 To TUni.TheMilkyWay.Length - 1
	Local a:Int = TUni.TheMilkyWay[Pos] 
	WritePixel(pix, x, y, MakeCol(255, a, a, a)) 
	x:+1
	If x = 1025 Then
		y:+1
		x = 1
	End If
Next
Local img:TImage = LoadImage(pix) 

SetScale(1,1)
Repeat
	DrawImage(img, 0, 0) 
	Flip;Cls
Until KeyDown(KEY_ESCAPE) Or AppTerminate() 

Local str:String = ""
For Local i:Int = 0 To 8191 Step 200
	str = ""
	For Local k:Int = 0 To 8191 Step 200
		Local sect:TSector = TSector.Create(k,i)
		Local stars:Int = sect.getNrSystems()
		str = str + stars
		If stars > 9 Then str = str + " "
		If stars < 10 Then str = str + "  "
	Next
	Print str
Next

Local sect:TSector = TSector.Create(3000,6000)
sect.Populate()
For local sys:TSystem = EachIn sect._L_systems
	Print "x: " + sys._x + "~ty: " + sys._y + "~tm: " + sys._multiple + "~tt: " + sys._type
Next
Print sect._L_systems.Count()


Function MakeCol:Int(a:Byte, r:Byte, g:Byte, b:Byte) 
	Local n:Int
	Local m:Byte ptr = VarPtr n
	m[0] = b
	m[1] = g
	m[2] = r
	m[3] = a
	Return n
EndFunction

Function GetCol(px:Int,a:Byte var, r:Byte var, g:Byte var, b:Byte var)
	a = px Shr 24
	b = px Shr 16
	g = px Shr 8
	r = px	
End Function


Type TUni
	Global TheMilkyWay:Int[] 
	Global SystemDensity:Int[] 
	Global StarChance_Type:Int[] = ..
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 6, 7, 8]
	Global StarChance_Multiples:Int[] = ..
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 4, 5]
	' two global base seeds
	Global SystemParam_0:Long
	Global SystemParam_1:Long
	
	Function RotateSome() 
	    Local Tmp1:Long, Tmp2:Long
	
		Tmp1 = (SystemParam_0 Shl 3) | (SystemParam_0 Shr 29) 
		Tmp2 = SystemParam_0 + SystemParam_1
		Tmp1:+Tmp2
		SystemParam_0 = Abs(Tmp1) 
		SystemParam_1 = Abs((Tmp2 Shl 5) | (Tmp2 Shr 27)) 
	End Function	

			
	Function LoadGalaxy(file:String)
		Local pix:TPixmap = LoadPixMap(file)
		
		'TheMilkyWay = [10,50,80,110,140,180,200,230,255]
		
		
		TheMilkyWay = TheMilkyWay[..(pix.width) * (pix.height-1)]
		
		Local a:Byte
		Local b:Byte
		Local g:Byte
		Local r:Byte
		
		Local x:Int = 1
		Local y:Int = 1
		For Local pos:Int = 0 To TheMilkyWay.Length - 1
			If y > pix.height-1 Or x > pix.width-1 Then 
				TUni.TheMilkyWay[Pos] = 0
			Else
				Local px:Int = ReadPixel(pix,x,y)
				GetCol(px,a,r,g,b)
				TUni.TheMilkyWay[Pos] = b
			EndIf
			x:+1
			If x = pix.width+1 Then
				y:+1
				x = 1
			End If
		Next
		pix = Null
	End Function	
End Type

Type TSector
	Field _L_systems:TList
	Field _x:Int
	Field _y:Int
	
	Method Forget()
		_L_systems.Clear()
	End Method
	
	Method Populate()
	    Local i:int
	
	    TUni.SystemParam_0 = (_x shl 16)+_y
	    TUni.SystemParam_1 = (_y shl 16)+_x
	
	    TUni.rotatesome()
	    TUni.rotatesome()
	    TUni.rotatesome()
	    TUni.rotatesome()

		If not _L_systems Then _L_systems = CreateList()
	    for i = 0 To getNrSystems() - 1
	        Local coordsOk:Int = True
			Local y:Int, x:Int, mult:Int, typ:Int
			Repeat
				coordsOk = TRUE
				TUni.rotatesome()
				y = ((TUni.SystemParam_0 & $0001FE) Shr 1)
		        TUni.rotatesome()
				x = ((TUni.SystemParam_0 & $0001FE) Shr 1)
				For Local sys:TSystem = EachIn _L_systems
					If sys._x = x And sys._y = y Then coordsOk = FALSE		' overlapping coordinates
				Next
			Until coordsOk
			mult:Int = TUni.StarChance_Multiples[TUni.SystemParam_1 & TUni.StarChance_Multiples.Length - 1]
			typ:Int = TUni.StarChance_Type[(TUni.SystemParam_1 shr 16) & TUni.StarChance_Multiples.Length - 1]
			Local system:TSystem = TSystem.Create(x,y,typ,mult)
			_L_systems.AddLast(system)
		Next
			
	End Method
	
	Method getNrSystems:Int() 
	    Local c:Long, nc:Long, nr:Long, nrc:Long
	    Local eax:Long, ebx:Long, ecx:Long, edx:Long, esi:Long, edi:Long
	    Local pixelval:Int
	    If (_x > $1fff Or _y > $1fff) Then Return 0
	    pixelval = (_x / 8) + 128 * (_y & $1FF8)
		c = TUni.TheMilkyWay[pixelval]          		' Current center
	    nc = TUni.TheMilkyWay[pixelval + 1]  			' Next column
	    nr = TUni.TheMilkyWay[pixelval + 1024] 			' Next Row
	    nrc = TUni.TheMilkyWay[pixelval + 1025] 			' Next row, next column
	    _x = (_x * 4096) & $7e00
	    _y = (_y * 4096) & $7e00
	    ebx = (nc - c) * _x + (nr - c) * _y
	    esi = (_x * _y) Shr 15
	    edi = nrc - nr - nc + c
	    esi:*edi
	    ebx:+esi
	    ebx:+ebx
	    c = c Shl 16
	    ebx:+c
	    ecx = ebx Shr 8
        
		' galaxyscale if
		ebx = _x + ecx
        eax = _x * _y
        eax = eax shr 15
        ebx = ebx^eax
        ebx = ebx shr 5
        ebx = ebx & $7f
        eax = TUni.SystemDensity[ebx]
        ecx = ecx * eax
        ecx = ecx shr 16
		' ----
		
		
	    c = ecx
	    c = c Shr 10
	    Return Int(c) 
	End Method


	Function Create:TSector(x:Int,y:Int)
		Local s:TSector = New TSector
		s._x = x
		s._y = y
		Return s
	End Function
End Type

Type TSystem
	Field _x:Int
	Field _y:Int
	Field _type:Int
	Field _multiple:Int
	
	Function Create:TSystem(x:Int,y:Int,typ:Int,mult:Int)
		Local s:TSystem = New TSystem
		s._x = x
		s._y = y
		s._type = typ
		s._multiple = mult
		Return s
	End Function
End Type