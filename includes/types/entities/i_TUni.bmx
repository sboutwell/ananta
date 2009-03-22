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
	' two global base seeds
	Global g_RndSeed_0:Long
	Global g_RndSeed_1:Long

	Field TheMilkyWay:Int[]  ' global array holding pixel values for the entire galaxy image
		
	' ----- some fields that are hardcoded for now... externalize to XML later -----

	' chance array for different star types
	Field StarChance_Type:Int[] = ..
	[0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 6, 7, 8]
	
	' chance array for multi-star systems (0 = single star, 1 = binary system, 2 = trinary system, etc)
	Field StarChance_Multiples:Int[] = ..
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 4, 5]
	
	Field StarSize:Int[] =[300, 300, 350, 400,  ..
    						700, 900, 800, 1100,  ..
    						1400, 600]

	' syllable stuff for star name generator
	Field Syllable1:String[]	' arrays containing first, second and third syllables
	Field Syllable2:String[]
	Field Syllable3:String[]
	Field syllable1Count:Int	' amount of syllables, should beat syllable1.Length in performace
	Field syllable2Count:Int
	Field syllable3Count:Int
							
	' load an image representing the galaxy to the global TheMilkyWay int array
	Method LoadGalaxy(file:String)
		Local pix:TPixmap = LoadPixmap(file)
		
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
				TheMilkyWay[Pos] = 0
			Else
				Local px:Int = ReadPixel(pix,x,y)
				GetCol(px,a,r,g,b)
				TheMilkyWay[Pos] = b
			EndIf
			x:+1
			If x = pix.width+1 Then
				y:+1
				x = 1
			End If
		Next
		pix = Null
	End Method

	' loads syllables.xml and populates the three syllable arrays
	Method LoadSyllables()
		Local syll1:String = XMLGetSingleValue(c_syllablesFile, "syllables/first")
		Local syll2:String = XMLGetSingleValue(c_syllablesFile, "syllables/second")
		Local syll3:String = XMLGetSingleValue(c_syllablesFile, "syllables/third")
		
		syllable1 = ParseSyllables(syll1)
		syllable2 = ParseSyllables(syll2)
		syllable3 = ParseSyllables(syll3)
		syllable1Count = syllable1.Length
		syllable2Count = syllable2.Length
		syllable3Count = syllable3.Length
		
		'DebugLog("Syllables: " + syllable1.Length)
	End Method
	
	' cleans a syllable string and splits it into a string array
	Method ParseSyllables:String[] (s:String)
		s = s.Trim()	' trim leading and trailing non-printable chars
		Local syllArray:String[] = SmartSplit(s, Chr(10)) ' split by LF
		
		' Finally strip single syllables off any unprintables
		For Local i:Int = 0 To syllArray.Length - 1
			syllArray[i] = syllArray[i].Trim()
		Next
		Return syllArray
	End Method
	
	Method GetPlanetName:String()
		' until we make something specific...
		Return GetSystemName()	
	End Method
	
	'Method GetSystemName:String(coordx:Int, coordy:Int, sysnum:Int)
	Method GetSystemName:String()
		Rem
		coordx:+Sysnum
    	coordy:+coordx
    	coordx = rotl (coordx, 3)
    	coordx:+coordy
    	coordy:+rotl (coordy, 5)
    	coordy:+coordx
    	coordy:+rotl (coordy, 4)
    	coordx:+rotl (coordx, Sysnum)
    	coordx:+coordy
		
		'DebugLog((coordx Shr 2) & (syllable1Count - 1))
		Local s1:Int = (coordx Shr 2) & (syllable1Count - 1)
		coordx = rotr (coordx, sysnum)
		Local s2:Int = (coordx Shr 2) & (syllable2Count - 1)
		coordx = rotr (coordx, 5)
		Local s3:Int = (coordx Shr 2) & (syllable3Count - 1)
		endrem
		
		Local s1:Int = Rand(0,syllable1Count -1)
		Local s2:Int = Rand(0,syllable2Count -1)
		Local s3:Int = Rand(0,syllable3Count -1)
		
		Return ProperCase(syllable1[s1] + syllable2[s2] + syllable3[s3])
	End Method

	' function to semi-randomize base seeds using bit shifts
	Function RotateRndSeeds() 
	    Local Tmp1:Long, Tmp2:Long
	
		Tmp1 = (g_RndSeed_0 Shl 3) | (g_RndSeed_0 Shr 29)
		Tmp2 = g_RndSeed_0 + g_RndSeed_1
		Tmp1:+Tmp2
		g_RndSeed_0 = Abs(Tmp1)
		g_RndSeed_1 = Abs((Tmp2 Shl 5) | (Tmp2 Shr 27))
	End Function	

	Function Create:TUni()
		Local u:TUni = New TUni
		u.LoadSyllables()
		Return u
	End Function
	
End Type

' TSector is a star sector in the galaxy, 
Type TSector
	Global _g_sectorSize:Int = $0000FF	
	Field _L_systems:TList	' systems in this sector
	Field _x:Int			' sector's coordinates (0 - 8192)
	Field _y:Int
	Field _isPopulated:Int = False	' flag to indicate if the systems have been created in this sector
	
	Method Forget()
		_L_systems.Clear()
		_isPopulated = False
	End Method

	' populate a star sector with procedurally generated stars
	Method Populate()
		If _isPopulated Then Return		' do not populate this sector if it's already populated
	    
		SeedRnd((_x Shl 16) + _y) 	' seed the Mersenne Twister with the sector coordinates
		
		' create the stars
		If Not _L_systems Then _L_systems = CreateList()
	    For Local i:Int = 0 To _getNrSystems() - 1
	        Local coordsOk:Int = True	' flag to indicate if this star overlaps with another star
			Local y:Int, x:Int, mult:Int, typ:Int
			Local name:String
			Repeat
				' (semi-)randomize the star's in-sector coordinates
				coordsOk = True
				y = _y * _g_sectorSize
				x = _x * _g_sectorSize
				y = y + Rand(0,_g_sectorSize)
				x = x + Rand(0,_g_sectorSize)
				For Local sys:TSystem = EachIn _L_systems	' iterate through the star list to see if this star overlaps with others
					If sys.GetX() = x And sys.GetY() = y Then coordsOk = False		' overlapping coordinates
				Next
			Until coordsOk	' rinse and repeat until the coordinates do not overlap
			
			' (semi-)randomize the rest of the star properties
			mult:Int = G_Universe.StarChance_Multiples[Rand(0, G_Universe.StarChance_Multiples.Length - 1)]
			typ:Int = G_Universe.StarChance_Type[Rand(0, G_Universe.StarChance_Type.Length - 1)]
			name:String = G_Universe.GetSystemName() ' generate system name with the current SFMT seed
			Local system:TSystem = TSystem.Create(_x, _y, x, y, name, typ, mult, i)
			system.SetSize((G_Universe.StarSize[typ] + mult * 100) / 200.0)
			
			
			_L_systems.AddLast(system) 
		Next
		_isPopulated = True	' switch the flag on to indicate this sector is populated
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
		c = G_Universe.TheMilkyWay[pixelval]           		' Current center
	    nc = G_Universe.TheMilkyWay[pixelval + 1]    			' Next column
	    nr = G_Universe.TheMilkyWay[pixelval + 1024] 			' Next Row
	    nrc = G_Universe.TheMilkyWay[pixelval + 1025]  		' Next row, next column
	    
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
		
		c = ecx
	    c = c Shr 10
		
		' add some +- variance to the star count. Redo this with something faster than Rnd (bitmasking?)
		c = c + Rnd(- 2, 1)
	    Return Int(c) 
	End Method

	Method getSystemFromName:TSystem(name:String)
		For Local i:TSystem=EachIn Self.GetSystemList()
			If i.getName().toLower() = name.toLower() Return i
		Next
	End Method

	Method GetSystemList:TList()
		Return _L_Systems
	End Method

	Function GetSectorSize:Int()
		Return _g_sectorSize
	End Function
		
	Function Create:TSector(x:Int,y:Int)
		Local s:TSector = New TSector
		s._x = x
		s._y = y
		Return s
	End Function
End Type