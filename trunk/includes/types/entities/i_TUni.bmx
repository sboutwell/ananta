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

Type TUni
	Global TheMilkyWay:Int[] 
	Global SystemDensity:Int[] = [ ..
    $BF78, $5B2F, $DF85, $3C14, $DADD, $38DF, $E08F, $88D7,  ..
    $B3AB, $EA86, $1200, $8DB3, $FF0D, $A593, $EC66, $1988,  ..
    $8500, $C1E7, $9281, $D7EB, $5F77, $D6A5, $310B, $2C98,  ..
    $906E, $2CB6, $F137, $8ADC, $0FC7, $76B8, $B587, $2D1B,  ..
    $AD4C, $1AEB, $B749, $C60D, $B914, $1B3A, $AA5E, $3764,  ..
    $D7A0, $650E, $DB8D, $3E98, $1DDD, $D3BB, $54A4, $66BA,  ..
    $164F, $F3B8, $7460, $BF9A, $7AA7, $459C, $61EC, $F706,  ..
    $958C, $8B54, $86E8, $C653, $5D7C, $6AC9, $AD35, $8B1F,  ..
    $30C6, $7EF7, $4E4F, $D1F3, $D042, $4AAC, $6F5A, $15C4,  ..
    $4DC3, $923C, $04E2, $2C8B, $AB14, $9689, $5553, $92F7,  ..
    $3BC6, $7C86, $5E8D, $FF7F, $8F5C, $0450, $0BD3, $B01F,  ..
    $2744, $DF20, $E40E, $932C, $8B90, $CF40, $6E2B, $81BE,  ..
    $200B, $A64F, $2BA4, $DCB8, $EA35, $ACC4, $1421, $9025,  ..
    $9A98, $4993, $99EF, $B4FD, $0BCF, $7434, $7287, $C67F,  ..
    $1967, $F486, $12AD, $DF33, $DF74, $2913, $2FF4, $D76B,  ..
    $5A2A, $8B80, $CB01, $742B, $09B4, $C203, $56AF, $DAD6,  ..
    $8000, $5555, $4000, $3333, $2AAA, $2492, $1FF0, $1C71,  ..
    $1999, $1745, $1555, $13B1, $1249, $1111, $0FF0, $0F0F ..
	] 

	' chance array for different star types
	Global StarChance_Type:Int[] = ..
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 6, 7, 8]
	
	' chance array for multi-star systems
	Global StarChance_Multiples:Int[] = ..
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 4, 5]
	
	' two global base seeds
	Global RndSeed_0:Long
	Global RndSeed_1:Long
	
	' function to semi-randomize base seeds using bit shifts
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
	Global _g_L_ActiveSectors:TList		' list holding all sectors that have been created
	Field _L_systems:TList
	Field _x:Int
	Field _y:Int
	Field _isPopulated:Int = False
	
	Method Forget()
		_L_systems.Clear()
		_isPopulated = False
		_g_L_ActiveSectors.Remove(self)
	End Method
		
	Method Populate()
		If _isPopulated Then Return
	    
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
			Local system:TSystem = TSystem.Create(x,y,"noname",typ,mult)
			_L_systems.AddLast(system)
		Next
		_isPopulated = True
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
	    
		Local tempx:Int = (_x * 4096) & $7e00
	    Local tempy:Int = (_y * 4096) & $7e00
	    ebx = (nc - c) * _x + (nr - c) * tempy
	    esi = (tempx * tempy) Shr 15
	    edi = nrc - nr - nc + c
	    esi:*edi
	    ebx:+esi
	    ebx:+ebx
	    c = c Shl 16
	    ebx:+c
	    ecx = ebx Shr 8
        
		' galaxyscale if
		ebx = tempx + ecx
        eax = tempx * tempy
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

	Method GetSystemList:TList()
		Return _L_Systems
	End Method
	
	Function Create:TSector(x:Int,y:Int)
		If not _g_L_ActiveSectors Then _g_L_ActiveSectors = CreateList()
		' if the sector matching the coordinates has already been created, return it
		For Local sect:TSector = EachIn _g_L_ActiveSectors
			if sect._x = x AND sect._y = y Then 
				Return sect
			EndIf
		Next
		
		Local s:TSector = New TSector
		s._x = x
		s._y = y
		_g_L_ActiveSectors.AddLast(s)
		Return s
	End Function
End Type