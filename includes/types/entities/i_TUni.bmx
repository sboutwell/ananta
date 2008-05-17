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
	Ok, here's the true heart of the game: 
	Procedurally generated universe with 500+ million nearly unique stars.

	Credit to the universe creation geniousness goes to - most of all - David Braben,
	and to Jongware, who reverse-engineered the Elite II Frontier Milky Way 
	creation algorithms and published the whole thing on his website www.jongware.com. 

	--- The Galaxy ---
	A grayscale galaxy image (1024x1024 pixels) is parsed and each pixel represents 
	8x8=64 "sectors", making the whole galaxy contain 8192x8192=67 million sectors. 
	Each sector can hold from 0 to 64 stars and the star count is dependent on the 
	general brightness of the pixel. Therefore, totally black (0) areas of the 
	galaxy map contain no stars while white (255) areas contain 64 stars.
	
	The pixel values are also interpolated so that sector transition between two
	different colour pixels will be smoothed out. So, there will be no abrupt changes
	in star counts between a totally black and a totally white pixel.
	
	The star positions within a sector are semi-randomized using Brucey's SIMD-oriented 
	Fast Mersenne Twister (SFMT) wrapper resulting in a consistent hardware-independent
	galaxy.
endrem

Type TUni
	Global TheMilkyWay:Int[]  ' global array holding pixel values for the entire galaxy image
	
	
	' some globals that are hardcoded for now... externalize to XML later
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
	
	'Local Grid[][] = [ [1,1,1,2],[7,7],[5,5,5] ]
	
	' chance array for multi-star systems (0 = single star, 1 = binary system, 2 = trinary system, etc)
	Global StarChance_Multiples:Int[] = ..
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 4, 5]
	
	Global StarSize:Int[] =[300, 300, 350, 400,  ..
    						700, 900, 800, 1100,  ..
    						1400, 600]

	
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

	' load an image representing the galaxy to the global TheMilkyWay int array
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

' TSector is a star sector in the galaxy, 
Type TSector
	Global _g_L_ActiveSectors:TList		' list holding all sectors that have been created
	Global _g_sectorSize:Int = $0000FF	
	Field _L_systems:TList	' systems in this sector
	Field _x:Int			' sector's coordinates (0 - 8192)
	Field _y:Int
	Field _isPopulated:Int = False	' flag to indicate if the systems have been created in this sector
	
	Method Forget()
		_L_systems.Clear()
		_isPopulated = False
		_g_L_ActiveSectors.Remove(self)
	End Method

	' populate a star sector with procedurally generated stars
	Method Populate()
		If _isPopulated Then Return		' do not populate this sector if it's already populated
	    
		SeedRnd((_x Shl 16) + _y) 	' seed the Mersenne Twister with the sector coordinates
		
		' create the stars
		If not _L_systems Then _L_systems = CreateList()
	    for Local i:Int = 0 To _getNrSystems() - 1
	        Local coordsOk:Int = True	' flag to indicate if this star overlaps with another star
			Local y:Int, x:Int, mult:Int, typ:Int
			Local name:String
			Repeat
				' (semi-)randomize the star's in-sector coordinates
				coordsOk = TRUE
				y = _y * _g_sectorSize
				x = _x * _g_sectorSize
				y = y + Rand(0,_g_sectorSize)
				x = x + Rand(0,_g_sectorSize)
				For Local sys:TSystem = EachIn _L_systems	' iterate through the star list to see if this star overlaps with others
					If sys._x = x And sys._y = y Then coordsOk = FALSE		' overlapping coordinates
				Next
			Until coordsOk	' rinse and repeat until the coordinates do not overlap
			
			' (semi-)randomize the rest of the star properties
			mult:Int = TUni.StarChance_Multiples[Rand(0,TUni.StarChance_Multiples.Length - 1)]
			typ:Int = TUni.StarChance_Type[Rand(0, TUni.StarChance_Type.Length - 1)]
			'name:String = TUni
			Local system:TSystem = TSystem.Create(_x, _y, x, y, "noname", typ, mult)
			system._size = (TUni.StarSize[typ] + mult * 100) / 200.0
			_L_systems.AddLast(system) 
		Next
		_isPopulated = True	' switch the flag on to indicate this system is populated
	End Method
	
	' getNrSystems finds out the amount of stars this sector is supposed to generate.
	' It parses through the galaxy bitmap: the brighter the pixel, the more stars in the sector.
	' The pixel values are interpolated so that sector transition between two
	' different colour pixels will be smoothed out. So, there will be no abrupt changes
	' in star counts between a totally black and a totally white pixel.
	' The actual inner workings of this brilliant function is a bit obscure, as it is 
	' reverse-engineered from Elite 2 Frontier by Jongware. Most of it is way over my head.
	Method _getNrSystems:Int() 
	    Local c:Long, nc:Long, nr:Long, nrc:Long
	    Local eax:Long, ebx:Long, ecx:Long, esi:Long, edi:Long
	    Local pixelval:Int
	    If (_x > $1fff Or _y > $1fff) Then Return 0	' if we're over the "edges", return zero
	    If (_x < 0 Or _y < 0) Then Return 0
		
	    pixelval = (_x / 8) + 128 * (_y & $1FF8)  		' calculate the array position calculated from the coordinates
		c = TUni.TheMilkyWay[pixelval]           		' Current center
	    nc = TUni.TheMilkyWay[pixelval + 1]    			' Next column
	    nr = TUni.TheMilkyWay[pixelval + 1024] 			' Next Row
	    nrc = TUni.TheMilkyWay[pixelval + 1025]  		' Next row, next column
	    
		' do the pixel value interpolation with neighbouring pixels
		Local tempx:Int = (_x * 4096) & $7e00
	    Local tempy:Int = (_y * 4096) & $7e00
	    ebx = (nc - c) * tempx + (nr - c) * tempy
	    esi = (tempx * tempy) Shr 15
	    edi = nrc - nr - nc + c
	    esi:*edi
	    ebx:+esi
	    ebx:+ebx
	    c = c Shl 16
	    ebx:+c
	    ecx = ebx Shr 8
        ' Capiche? ;) I don't. It's some kind of an averaging algorithm but the inner workings beat me.
		
		' comment this block to increase the overall number of stars
		'ebx = tempx + ecx
        'eax = TUni.SystemDensity[ebx]
        'eax = tempx * tempy
        'eax = eax shr 15
        'ebx = ebx^eax
        'ebx = ebx shr 5
        'ebx = ebx & $7f
        'ecx = ecx * eax
        'ecx = ecx Shr 16
		' ----		
		
		c = ecx
	    c = c Shr 10
		
		' add +- 1 variance to the star count. Redo this with something faster than Rnd (bitmasking?)
		c = c + Rnd(- 2, 1) 
	    Return Int(c) 
	End Method

	Method GetSystemList:TList()
		Return _L_Systems
	End Method

	Function GetSectorSize:Int()
		Return _g_sectorSize
	End Function
		
	Function Create:TSector(x:Int,y:Int)
		If not _g_L_ActiveSectors Then _g_L_ActiveSectors = CreateList()
		rem
		' if the sector matching the coordinates has already been created, return it
		For Local sect:TSector = EachIn _g_L_ActiveSectors
			if sect._x = x AND sect._y = y Then 
				'Debuglog "Sector at [" + x + "][" + y +"] already created"
				Return sect
			EndIf
		Next
		endrem
		Local s:TSector = New TSector
		s._x = x
		s._y = y
		'_g_L_ActiveSectors.AddLast(s)
		Return s
	End Function
End Type