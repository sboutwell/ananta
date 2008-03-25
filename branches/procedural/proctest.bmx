SuperStrict

Framework brl.d3d7max2d
Import brl.standardio
Import brl.Pixmap
Import brl.pngloader
SetGraphicsDriver D3D7Max2DDriver() 
Graphics(100, 100) 

Include "mway.bmx"

TUni.LoadGalaxy("galaxy.png") 


Local pix:TPixmap = CreatePixmap(1025, 1025, PF_I8) 
Local x:Int = 1
Local y:Int = 1

Local cols:Int[256] 
For Local Pos:Int = 0 To (pix.height - 1) * (pix.width - 1) - 1
	Local a:Int = TUni.TheMilkyWay[Pos] 
	cols[a] = cols[a] + 1
	WritePixel(pix, x, y, MakeCol(255, a, a, a)) 
	x:+1
	If x = 1025 Then
		y:+1
		x = 1
	End If
Next

DisplayDensityMap(80) 

rem
For Local Pos:Int = EachIn cols
	Print Pos
Next
endrem

Local img:TImage = LoadImage(pix) 

SetScale(0.1, 0.1) 
Repeat
	DrawImage(img, 0, 0) 
	Flip;Cls
Until KeyDown(KEY_ESCAPE) Or AppTerminate() 


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


Function DisplayDensityMap(s:Int = 200) 		
	Local str:String = ""
	For Local i:Int = 0 To 8191
		If i mod s <> 0 Then Continue
		str = ""
		For Local k:Int = 0 To 8191
			If k mod s <> 0 Then Continue
			Local sect:TSector = TSector.Create(k,i)
			Local stars:Int = sect.getNrSystems()
			str = str + stars
			If stars > 9 Then str = str + " "
			If stars < 10 Then str = str + "  "
		Next
		Print str
	Next	
End Function

Type TUni
	Global TheMilkyWay:Int[] 
	Global SystemDensity:Int[] 
	Global StarChance_Type:Int[] = ..
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 6, 7, 8]
	Global StarChance_Multiples:Int[] = ..
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 4, 5]
	' two global base seeds
	Global RndSeed_0:Long
	Global RndSeed_1:Long
	
	Function RotateRndSeeds() 
	    Local Tmp1:Long, Tmp2:Long
	
		Tmp1 = (RndSeed_0 Shl 3) | (RndSeed_0 Shr 29) 
		Tmp2 = RndSeed_0 + RndSeed_1
		Tmp1:+Tmp2
		RndSeed_0 = Abs(Tmp1) 
		RndSeed_1 = Abs((Tmp2 Shl 5) | (Tmp2 Shr 27)) 
	End Function	

			
	Function LoadGalaxy(file:String)
		Local pix:TPixmap = LoadPixMap(file)
		
		'TheMilkyWay = [10,50,80,110,140,180,200,230,255]
		
		' add an extra row and column to the array for "edge interpolation"
		TheMilkyWay = TheMilkyWay[..(pix.width + 1) * (pix.height + 1)] 
		
		Local a:Byte
		Local b:Byte
		Local g:Byte
		Local r:Byte
		
		Local x:Int = 1
		Local y:Int = 1
		For Local Pos:Int = 0 To TheMilkyWay.Length - 1
			If y >= pix.height Or x >= pix.width Then
				'if we're at the "extra" row or column, fill with zero
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
	
	    TUni.RndSeed_0 = (_x shl 16)+_y
	    TUni.RndSeed_1 = (_y shl 16)+_x
	
	    TUni.RotateRndSeeds()
	    TUni.RotateRndSeeds()
	    TUni.RotateRndSeeds()
	    TUni.RotateRndSeeds()

		If not _L_systems Then _L_systems = CreateList()
	    for i = 0 To getNrSystems() - 1
	        Local coordsOk:Int = True
			Local y:Int, x:Int, mult:Int, typ:Int
			Repeat
				coordsOk = TRUE
				TUni.RotateRndSeeds()
				y = ((TUni.RndSeed_0 & $0001FE) Shr 1)
		        TUni.RotateRndSeeds()
				x = ((TUni.RndSeed_0 & $0001FE) Shr 1)
				For Local sys:TSystem = EachIn _L_systems
					If sys._x = x And sys._y = y Then coordsOk = FALSE		' overlapping coordinates
				Next
			Until coordsOk
			mult:Int = TUni.StarChance_Multiples[TUni.RndSeed_1 & TUni.StarChance_Multiples.Length - 1]
			typ:Int = TUni.StarChance_Type[(TUni.RndSeed_1 shr 16) & TUni.StarChance_Multiples.Length - 1]
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
		c = TUni.TheMilkyWay[pixelval]           		' Current center
	    nc = TUni.TheMilkyWay[pixelval + 1]    			' Next column
	    nr = TUni.TheMilkyWay[pixelval + 1024] 			' Next Row
	    nrc = TUni.TheMilkyWay[pixelval + 1025]  			' Next row, next column
	    
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



Type TStarMap
	Field _L_blips:TList
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the map in pixels
	Field _width:Int	' width of the map in pixels
	Field _midX:Float	' middle X coordinate
	Field _midY:Float	' middle Y coordinate
	
	Field _scale:Float = 0.01

	Field _defaultZoom:Float = 0.2
	Field _zoomFactor:Float
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	Field _zoomStep:Float = 0.5			' the amount added to the _zoomAmount per each second of zooming
	
	' base value for scale gauge step
	Field _lineStep:Int = 100
	
	Field _alpha:Float
	
	Field _attitudeIndicator:TImage

rem		
	Method AddBlip(o:TSpaceObject) 
		Local midX:Int = _width / 2
		Local midY:Int = _height / 2
		Local x:Int = (viewport.GetCameraPosition_X() - o.GetX()) * _scale * _zoomFactor + midX + _startX
		Local y:Int = (viewport.GetCameraPosition_Y() - o.GetY()) * _scale * _zoomFactor + midY + _startY
		Local size:Int = o.GetSize() * _scale * _zoomFactor
		If size < 2 Then size = 2
		Local blip:TBlip = TBlip.Create(x, y, size) 
		

		If Not _L_blips Then _L_blips = New TList
		If blip.GetSize() > 0 Then _L_blips.AddLast(blip) 
	End Method
endrem
	
	Method draw() 
		If Not _L_Blips Then Return
		SetViewport(_startX, _startY, _width, _height) 
		SetBlend(ALPHABLEND) 
		SetAlpha(_alpha) 
		SetMaskColor(255, 255, 255) 
		SetScale(1, 1) 
		For Local blip:TStarBlip = EachIn _L_Blips
			' If no part of the blip would be visible on the screen, don't bother to draw it
			If blip.isOverBoundaries(_startX, _startY, _width, _height) Then
				Continue
			Else
				blip.Draw() 				
			EndIf
		Next
		
		SetHandle(0, 0) 
		
		' after drawing all blips, clear the list
		If _L_blips Then _L_Blips.Clear() 
		
		' draw miscellaneous map details
		DrawDetails() 
	End Method

	Method DrawDetails() 
		DrawScale() 
	 
		' draw the background tint
		DrawBackGround()
		
		' draw the minimap title
		SetAlpha(1)
		SetColor(255,255,255)
		SetScale(1,1)
		SetRotation(0)
		DrawText("Sector map", Self._midX - 35, Self._StartY) 
	End Method	
		
	Method DrawScale() 
		Local lineStepScaled:Double = _lineStep * _scale * _zoomFactor
		
		Local k:Int = 0
		Repeat
			k:+1
			lineStepScaled:Double = _lineStep * 10 ^ k * _scale * _zoomFactor
		Until lineStepScaled > 7

		Local lines:Int = _width / lineStepScaled
		
		Local yPos:Int = _height - 5
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetAlpha(0.5) 
		SetLineWidth(1) 
		
		' center vertical line
		SetColor(255, 255, 255) 
		DrawLine(_midX, yPos + 6, _midX, yPos - 6, False) 
		
		' horizontal line
		SetColor(128, 128, 128) 
		DrawLine(_startX, yPos, _startX + _width, yPos, False) 
		
		' lines to the left of the center object
		For Local i:Int = 1 To lines / 2
			If i Mod 5 = 0 Then
				SetColor(255, 255, 255) 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX - i * lineStepScaled, yPos + 2,  ..
					_midX - i * lineStepScaled, yPos - 2) 
		Next
		
		' lines to the right of the center object
		For Local i:Int = 1 To lines / 2
			If i Mod 5 = 0 Then
				SetColor(255, 255, 255) 
			Else
				SetColor(128, 128, 128) 
			EndIf
			DrawLine(_midX + i * lineStepScaled, yPos + 2,  ..
					_midX + i * lineStepScaled, yPos - 2) 
		Next
		
		DisplayLineStep(k) 
	End Method
	
	' draws the scale text indicator on top of the scale line
	Method DisplayLineStep(k:Int) 
		Local prefix:String = "k"
		Local divider:Int = 1000 / _lineStep
		Local val:Double = 10.0 ^ k / divider
		
		If k > 3 Then
			prefix = "M"
			val = val / 1000
		EndIf
		
		If k > 6 Then
			prefix = "G"
			val = val / 1000
		EndIf

		If k > 9 Then
			prefix = "T"
			val = val / 1000
		End If
		
		If k > 12 Then
			prefix = "P"
			val = val / 1000
		End If
		
		If k > 15 Then
			prefix = "E"
			val = val / 1000
		End If
		
		SetScale(1, 1) 
		SetRotation(0) 
		SetBlend(ALPHABLEND) 
		SetAlpha(0.6) 
		SetColor(128, 128, 128) 
		DrawText(Int(val) + prefix, _startX + 5, _startY + _height - 20) 
	End Method
	
	Method DrawBackground()
		SetScale(1, 1) 
		SetAlpha(0.15)
		SetColor(64,64,255)
		DrawRect(_startX,_startY,_width,_height)
	End Method
	
	Method SetZoomFactor(z:Float) 
		_zoomfactor = z
	End Method
	
	Method GetDefaultZoom:Float() 
		Return _defaultZoom
	End Method
	
	Method ResetZoomFactor() 
		_zoomfactor = _defaultZoom
	End Method
	
	Method ZoomIn() 
		'_zoomFactor:+_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		'_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta() 
		_zoomFactor:+_zoomFactor * _zoomAmount
		_zoomAmount = _zoomAmount + _zoomStep
	End Method
	
	Method ZoomOut() 
		'_zoomFactor:-_zoomFactor * _zoomAmount * G_delta.GetDelta() 
		'_zoomAmount = _zoomAmount + _zoomStep * G_delta.GetDelta() 
		_zoomFactor:-_zoomFactor * _zoomAmount
		_zoomAmount = _zoomAmount + _zoomStep
	End Method
	
	Method StopZoom() 
		_zoomAmount = _zoomAmountReset
	End Method
	
	Function Create:TStarMap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TStarMap = New TStarMap
		'If x + w > viewport.GetResX() Then x = viewport.GetResX() - w
		'If y + h > viewport.GetResY() Then y = viewport.GetResY() - h
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		map._midX = x + w / 2.0
		map._midY = y + h / 2.0
		
		map._defaultZoom = 3
		map._zoomFactor = map._defaultZoom
		
		map._alpha = 0.8
		
		Return map
	End Function
EndType

Type TStarBlip
	Field _x:Int, _y:Int
	Field _size:Float

	Method GetSize:Float() 
		Return _size
	End Method
	
	Method GetX:Int() 
		Return _x
	End Method
	
	Method GetY:Int() 
		Return _y
	End Method
	
	Method SetSize(sz:Float) 
		_size = sz
	End Method
	
	' isOverBoundaries checks if the blip would show on the minimap
	Method isOverBoundaries:Int(startX:Int, startY:Int, width:Int, height:Int) 
		Return _x + _size / 2 < startX Or ..
			_y + _size / 2 < startY Or ..
			_x - _size / 2 > startX + width Or ..
			_y - _size / 2 > startY + height
	End Method
	
	
	Method Draw() 
		If _size = 0 Then Return		' don't draw 0-sized blips
		SetHandle(_size / 2, _size / 2)     ' oval handle to the middle of the oval
		DrawOval (_x, _y, _size, _size) 
	End Method
	
	Function Create:TStarBlip(x:Int, y:Int, size:Int) 
		Local blip:TStarBlip = New TStarBlip
		blip._x = x
		blip._y = y
		blip._size = size
		Return blip
	End Function
End Type

Function getPrefix(pref:String var, val:Long var) 
	Local prefixes:String[] =["", "", "",  ..
							"k", "k", "k",  ..
							"M", "M", "M",  ..
							"G", "G", "G",  ..
							"T", "T", "T",  ..
							"P", "P", "P",  ..
							"E", "E", "E" ..
							] 
	Local vString:String = String(val) 
	Local zeroes:Int = 0
	For Local char:Int = vString.Length - 1 To 0 Step - 1
		If Chr(vString[char] ) = "0" Then zeroes:+1
	Next
	
	If zeroes > prefixes.Length - 1 Then zeroes = prefixes.Length - 1
	pref = prefixes[zeroes] 
	For Local i:Int = 3 To zeroes Step 3
		val = val / 1000
	Next
	
End Function