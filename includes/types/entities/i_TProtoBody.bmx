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
EndRem

' ---------------------------------------------------------------------------------------
Rem

	TProtoBody.populateBodyFromName(target:TStellarObject, name:String)
	TProtoBody.findProtoBodyFromName:TProtoBody(name:String)
	TProtoBody.LoadAllProtoBodies()
	TProtoBody.LoadAll(rootnode:TxmlNode)
	TProtoBody.Create:TProtoBody(name:String)
	TprotoBody.LoadValues(nodelist:TList,p:TProtoBody)

	Example:
	
		local l:TPlanet=new TPlanet
			TProtoBody.populateBodyFromName(l, "rocky1")

	TODO:
		x Add Colour for stars?


EndRem
' ---------------------------------------------------------------------------------------
Type TProtoBody
	Global g_L_ProtoBodies:TList	' a list to hold all prototypes

	Global g_NumberOfStarTypes:Int = 0
	Global g_NumberOfPlanetTypes:Int = 0

	Field _Name:String		' the prototypes name. Stars will be 'Type 'F' white star', planets, "molten rock"
	Field _ImageFile:String
	Field _Description:String
	Field _MinMass:Long
	Field _MaxMass:Long
	Field _MinScale:Float
	Field _MaxScale:Float
	Field _comfortZone:String
	Field _planetChance:String
	Field _populationChance:String

	' getters/setters
	Method getMinMass:Long() Return _MinMass End Method
	Method getMaxMass:Long() Return _MaxMass End Method
	Method getMinScale:Float() Return _MinScale End Method
	Method getMaxScale:Float() Return _MaxScale End Method
	Method getImageFile:String() Return _ImageFile End Method
	Method getName:String() Return _Name End Method
	Method getDescription:String() Return _Description End Method
	Method getPlanetChance:String() Return _planetChance End Method
	Method getComfortZone:String() Return _comfortZone End Method
	Method getPopulationChance:String() Return _populationChance End Method
		
	Method getNumberOfStarTypes:Int() Return g_NumberOfStarTypes End Method
	Method getNumberOfPlanetTypes:Int() Return g_NumberOfPlanetTypes End Method
		
	Method setMinMass(m:Long) _MinMass = m End Method
	Method setMaxMass(m:Long) _MaxMass = m End Method	
	Method setMinScale(m:Float) _MinScale = m End Method
	Method setMaxScale(m:Float) _MaxScale = m End Method
	Method setImageFile(m:String) _ImageFile = m End Method
	Method setName(m:String) _Name = m End Method
	Method setDescription(m:String) _Description = m End Method
	Method setPlanetChance(m:String) _PlanetChance = m End Method
	Method setComfortZone(m:String) _comfortZone = m End Method
	Method setPopulationChance(m:String) _populationChance = m End Method
			
	' this function will find the prototype body and use it
	' to populate the target stellar object, be it planet or sun.
	
	Function populateBodyFromName(target:TStellarObject, name:String)
		Local found:TProtoBody=TProtoBody.findProtoBodyFromName(name)
		If Not found 
			If G_Debug Print "Could not prototype from "+name+". Please check "+c_celestialTypes
			Return
		EndIf
	
		target.setMass(Rand(found.getMinMass(),found.getMaxMass()))
		target.setScaleX(Rnd(found.getMinScale(),found.getMaxScale()))
		target.setScaleY(target.getScaleX())
		target.setImage(found.getImageFile())
		target.setDescription(found.getDescription())
		
		target.setSize(CalcImageSize(target._image, False) * target.GetScaleX())
		
		If G_Debug Print "Body '"+target.getName()+"' has been populated from prototype "+found.getName()
	End Function
	
		
	Function findProtoBodyFromName:TProtoBody(name:String) 
		If TProtoBody.g_L_ProtoBodies=Null Return Null		
		For Local i:TProtoBody=EachIn TProtoBody.g_L_ProtoBodies
			If i.getName().toLower() = name.toLower() Return i
		Next
	End Function

	Function LoadAllProtoBodies()	
		Local node:TxmlNode = LoadXMLFile(c_celestialTypes)
		Local searchnode:TxmlNode 
		
		' find and return the "stars" node
		searchnode = xmlGetNode(node, "stars") 
		If searchnode <> Null Then TProtoBody.LoadAll(searchnode, TProtoBody.g_NumberOfStarTypes)

		 ' find and return the "planets" node
		searchnode = xmlGetNode(node, "planets")
		If searchnode <> Null Then TProtoBody.LoadAll(searchnode, TProtoBody.g_NumberOfPlanetTypes)			

		If G_Debug 
			Print "Finished reading and parsing Prototype Bodies from " + c_celestialTypes
			Print ""
			Print "Loaded "+TProtoBody.g_NumberOfStarTypes+" star types"
			Print "Loaded "+TProtoBody.g_NumberOfPlanetTypes+" planet types"
		EndIf
	EndFunction
	
	' loads and parses all prototypes from the xml file
	Function LoadAll(rootnode:TxmlNode, count:Int Var)
		If G_Debug Print "    Loading prototype bodies..."
		
		Local children:TList = rootnode.getChildren() 			
		For rootnode = EachIn children							
			If G_Debug Print "      prototype found: " + rootnode.GetName()
			
			Local p:TProtoBody = TProtoBody.Create(rootnode.GetName())			
			Local pChildren:TList = rootnode.getChildren()
			TProtoBody.LoadValues(pChildren, p) ' Pass the node list and the newly created engine object as parameters
			count:+1 ' count and increment the count vriable
		Next
		
		Return
	EndFunction

	' loads TProtoBody properties from xml nodes
	Function LoadValues(nodelist:TList,p:TProtoBody)
		For Local value:TxmlNode = EachIn nodelist	' iterate through node values
			
			If value.GetName() = "image"		Then p.setImageFile(value.GetText())	
			If value.GetName() = "description" 	Then p.setDescription(value.GetText())
			If value.GetName() = "minscale" 	Then p.setMinScale(value.GetText().ToFloat())
			If value.GetName() = "maxscale" 	Then p.setMaxScale(value.GetText().ToFloat())
			
			If value.GetName() = "minmass" 	Then p.setMinMass(value.GetText().ToLong())
			If value.GetName() = "maxmass" 	Then p.setMaxMass(value.GetText().ToLong())
			
			If value.getName() = "planetchance" Then p.setPlanetChance(value.getText())
			If value.getName() = "comfortzone" Then p.setComfortZone(value.getText())
			If value.getName() = "populationchance" Then p.setPopulationChance(value.getText())
		Next
	End Function

	Function Create:TProtoBody(name:String)
		Local p:TProtoBody = New TProtoBody		' create an instance
		p.setName(name)
		
		If Not g_L_ProtoBodies Then g_L_ProtoBodies= CreateList()	' create a list if necessary
		g_L_ProtoBodies.AddLast p		' add the newly created object to the end of the list
		
		Return p	' return the pointer to this specific object instance
	EndFunction
	
EndType

