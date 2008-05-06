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
	System map (extended from TMiniMap)
EndRem

Type TSystemMap Extends TMiniMap
	Field _starColor:TColor ' star color
	Field _planetColor:TColor ' planet color
	Field _shipColor:TColor ' ship color
	Field _selfColor:TColor	' centered object color
	Field _velColor:TColor	' velocity vector color
	Field _miscColor:TColor	' default color
	Field _projColor:TColor ' projectile color
	
	Field _attitudeIndicator:TImage ' attitude indicator image
	
	Method AddSystemMapBlip(o:TSpaceObject)
		Local blip:TMapBlip = AddBlip(viewport.GetCameraPosition_X() - o.GetX(),viewport.GetCameraPosition_Y() - o.GetY(),o.GetSize())
		
		' use casting to find out the type of the object and set the color accordingly
		If TStar(o) Then 
			blip.SetBColor(_starColor) 
		Else If TPlanet(o) Then blip.SetBColor(_planetColor) 
		Else If TShip(o) Then blip.SetBColor(_ShipColor) 
		Else If TProjectile(o) Then blip.SetBColor(_ProjColor) 
		Else 
			blip.SetBColor(_miscColor)  ' none of the above, use default
		EndIf
 	
		' special behaviour for the centered blip
		If o = viewport._centeredObject Then
			blip.SetBColor(_selfColor) 
			If TShip(o) And blip.GetSize() < 3 Then blip.SetSize(0.0)   ' do not draw the blip (set size to 0) when zoomed out "enough". The attitude indicator should do the job.
		EndIf	
	End Method

	Method DrawDetails() 
		super.DrawDetails()	
	
		' use type casting to determine if the centered object is a TMovingObject
		Local obj:TMovingObject = TMovingObject(viewport.GetCenteredObject()) 
		If Not obj Then Return		' return if object is not a moving object
		DrawVelocityVector(obj)  	' draw velocity vector for the centered object
		
		' use type casting to determine if the centered object is a TShip
		Local ship:TShip = TShip(viewport.GetCenteredObject()) 
		If Not ship Then Return		' return if the object is not a ship
		DrawAttitudeIndicator(ship)    ' draw the T-shaped attitude indicator to the middle of the map
	End Method	
		
	Method DrawVelocityVector(obj:TMovingObject) 
		TColor.SetTColor(_velColor) 
		SetAlpha(0.3) 
		
		Local vX:Float = obj.GetXVel() / 10
		Local vY:Float = obj.GetYVel() / 10
		
		SetScale(1, 1) 
		SetLineWidth(1) 
		DrawLine(_midX - vX, _midY - vY, _midX, _midY, False) 
	End Method

	Method DrawAttitudeIndicator(obj:TShip) 
		SetScale(0.3, 0.3) 
		SetBlend(ALPHABLEND) 
		SetAlpha(0.5) 
		SetRotation(obj.GetRot() + 90) 
		SetColor(255, 255, 255) 
		DrawImage(_attitudeIndicator, _midX, _midY) 
		SetRotation(0) 
	End Method
	
	
	Function Create:TSystemMap(x:Int, y:Int, h:Int, w:Int) 
		Local map:TSystemMap = New TSystemMap
		map._startX = x
		map._startY = y
		map._height = h
		map._width = w
		
		map.isVisible = TRUE
		
		map._defaultZoom = 0.1
		map._title = "System map"
		
		map._starColor = TColor.FindColor("yellow") 
		map._shipColor = TColor.FindColor("crimson") 
		map._selfColor = TColor.FindColor("lime") 
		map._planetColor = TColor.FindColor("cobalt") 
		
		map._velColor = TColor.FindColor("lime") 
		map._miscColor = TColor.FindColor("cyan") 
		map._projColor = TColor.FindColor("pink")
		map._attitudeIndicator = TImg.LoadImg("attitude.png") 
		
		map.Init() ' calculate the rest of the minimap values
		Return map
	End Function
EndType

