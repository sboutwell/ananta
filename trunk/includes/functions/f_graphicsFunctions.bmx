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

' TileImage2 courtesy of Joe Lesko, modified by Jussi Pakkanen
Function TileImage2 (image:TImage, x:Double=0:Double, y:Double=0:Double, frame:Int=0)

    Local scale_x#, scale_y#
    GetScale(scale_x#, scale_y#)

    Local viewport_x%, viewport_y%, viewport_w%, viewport_h%
    GetViewport(viewport_x, viewport_y, viewport_w, viewport_h)

    Local origin_x#, origin_y#
    GetOrigin(origin_x, origin_y)

    Local handle_X#, handle_y#
    GetHandle(handle_X, handle_y)

    Local image_h:Double = ImageHeight(image)
    Local image_w:Double = ImageWidth(image)

    Local w:Double=image_w * Abs(scale_x#)
    Local h:Double=image_h * Abs(scale_y#)

    Local ox:DOuble=viewport_x-w+1
    Local oy:Double=viewport_y-h+1

    origin_X = origin_X Mod w
    origin_Y = origin_Y Mod h

    Local px:Double=x+origin_x - handle_x
    Local py:Double=y+origin_y - handle_y

    Local fx:Double=px-Floor(px)
    Local fy:Double=py-Floor(py)
    Local tx:Double=Floor(px)-ox
    Local ty:Double=Floor(py)-oy

    If tx>=0 tx=tx Mod w + ox Else tx = w - -tx Mod w + ox
    If ty>=0 ty=ty Mod h + oy Else ty = h - -ty Mod h + oy

    Local vr:Double= viewport_x + viewport_w, vb# = viewport_y + viewport_h

    SetOrigin 0,0
    Local iy:DOuble=ty
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