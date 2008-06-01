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

' TileImage2 courtesy of Joe Lesko, modified by Jussi Pakkanen
' Similar to standard TileImage, but uses Double precision and is affected by
' scale and rotation
Function TileImage2 (image:TImage, x:Double=0:Double, y:Double=0:Double, frame:Int=0)
    Local scale_x#, scale_y#
    Local viewport_x%, viewport_y%, viewport_w%, viewport_h%
    Local origin_x#, origin_y#
    Local handle_X#, handle_y#
	Local image_h:Double, image_w:Double
	Local w:Double, h:Double
	Local ox:Double, oy:Double
	Local px:Double, py:Double
	Local fx:Double, fy:Double
	Local tx:Double, ty:Double
	Local vr:Double, vb:Double
	Local iy:Double
	
	GetScale(scale_x#, scale_y#)
    GetViewport(viewport_x, viewport_y, viewport_w, viewport_h)

    GetOrigin(origin_x, origin_y)

    GetHandle(handle_X, handle_y)

    image_h:Double = ImageHeight(image)
    image_w:Double = ImageWidth(image)

    w:Double=image_w * Abs(scale_x#)
    h:Double=image_h * Abs(scale_y#)

    ox:Double=viewport_x-w+1
    oy:Double=viewport_y-h+1

    origin_X = origin_X Mod w
    origin_Y = origin_Y Mod h

    px:Double=x+origin_x - handle_x
    py:Double=y+origin_y - handle_y

    fx:Double=px-Floor(px)
    fy:Double=py-Floor(py)
    tx:Double=Floor(px)-ox
    ty:Double=Floor(py)-oy

    If tx>=0 tx=tx Mod w + ox Else tx = w - -tx Mod w + ox
    If ty>=0 ty=ty Mod h + oy Else ty = h - -ty Mod h + oy

    vr:Double = viewport_x + viewport_w
	vb:Double = viewport_y + viewport_h

    SetOrigin 0,0
    iy:Double=ty
    While iy<vb + h ' add image height to fill lower gap
        Local ix:Double=tx
        While ix<vr + w ' add image width to fill right gap
            DrawImage(image, ix+fx,iy+fy, frame)
            ix=ix+w
        Wend
        iy=iy+h
    Wend
    SetOrigin origin_x, origin_y

End Function

' Function to draw a non-filled rectangle. 
' Might be faster to draw 4 rectangles instead of lines. Benchmark.
Function DrawOblong( x#, y#, w#, h# )
	DrawLine( x , y , x + w , y)
	DrawLine( x+w , y , x + w , y+h)
	DrawLine( x+w , y+h , x , y+h)
	DrawLine( x , y+h , x , y)
End Function

' converts an RGB pixel to grayscale using one common formula
Function RGBtoGrayscale:Int(r:Int, g:Int, b:Int)
	Return (0.3 * r + 0.59 * g + 0.11 * b)
End Function

Function drawCircle(x:Float,y:Float,radius:Int)
	Local d:Float=360.0/10.0
	Local fx:Float=0,fy:Float=0
	Local ox:Float,oy:Float
	Local x1:Float,y1:Float
	
	SetRotation(0)
	SetBlend ALPHABLEND
	SetScale 1,1	
		
	For Local i:Int=0 To 360 Step 10
		x1=x+Cos(i)*radius
		y1=y+Sin(i)*radius
		
		If ox<>0 And oy <>0
			DrawLine x1,y1,ox,oy,0
		EndIf
		
		ox=x1;oy=y1
		
		If fx=0 And fy=0		
			fx=x1;fy=y1
		EndIf
	Next
	
	DrawLine fx,fy,x1,y1,0 ' last line
End Function