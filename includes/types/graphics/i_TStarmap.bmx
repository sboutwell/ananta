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

Rem
	Zoomable starmap and the related types and functions
EndRem

Type TStarMap
	Field _L_blips:TList
	Field _startX:Int	' top left X coordinate
	Field _startY:Int	' top left Y coordinate
	Field _height:Int	' height of the minimap in pixels
	Field _width:Int	' width of the minimap in pixels
	Field _midX:Float	' middle X coordinate
	Field _midY:Float	' middle Y coordinate
	
	Field _scale:Float = 0.01

	Field _defaultZoom:Float = 0.2
	Field _zoomFactor:Float
	Field _zoomAmount:Float 			' amount of zoom per keypress
	Field _zoomAmountReset:Float = 0.5	' the value _zoomAmount is reset to when zooming stopped
	Field _zoomStep:Float = 0.5			' the amount added to the _zoomAmount per each second of zooming
	
End Type
