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
	Type that handles media files. 
	The main purpose of the type is to load all media files in memory 
	and so preventing loading the same file multiple times.
endrem

Type TMedia Abstract
	Global g_mediaPath:String = "media/"
	Field _filename:String	' filename of the media file in the media directory
	
	Method GetFileName:String() 
		Return _fileName
	End Method
End Type

Type TImg Extends TMedia
	Global g_L_imageFiles:TList
	Field _image:TImage		' container field for the image itself
	
	Method GetImage:TImage() 
		Return _image
	End Method
	
	' StoreImg stores a preloaded/generated TImage to g_L_imageFiles.
	' It takes a unique "id" as a parameter which is saved into the _filename-field.
	' If the id exists in g_L_imageFiles, the previously saved image will be overwritten.
	' An image stored with StoreImg can be retrieved later with LoadImg(id:String).
	Function StoreImg(image:TImage, id:String) 
		If Not g_L_imageFiles Then g_L_imageFiles = CreateList() 
		' if an image with the same ID exists, delete it from the list
		For Local i:TImg = EachIn g_L_imageFiles
			If i.GetFileName() = id Then g_L_imageFiles.Remove(i) 
		Next
		Local img:TImg = TImg.Create(image, id) 
		g_L_imageFiles.AddLast(img) 
	End Function
	
	' finds a previously loaded image and removes it from the image list
	Function UnLoadImg(filename:String)
		If Not g_L_imageFiles Then Return
		For Local img:TImg = EachIn g_L_imageFiles
			If img.GetFileName() = filename Then 
				img._image = Null
				g_L_imageFiles.Remove(img)
			EndIf
		Next	
	EndFunction
	
	' LoadImg returns a TImage matching a filename string. 
	Function LoadImg:TImage(filename:String, automid:Int = True) 
		AutoImageFlags MASKEDIMAGE | FILTEREDIMAGE | MIPMAPPEDIMAGE	' flags For LoadImage()

		If Not g_L_imageFiles Then g_L_imageFiles = CreateList() 
		
		' if the file has already been loaded, return it instead of reloading it
		For Local img:TImg = EachIn g_L_imageFiles
			If img.GetFileName() = filename Then Return img.GetImage() 
		Next
		
		AutoMidHandle automid
		Local image:TImage = LoadImage(g_mediaPath + filename) 
		If Not image Then Return Null
		
		Local img:TImg = TImg.Create(image, filename) 
		Return img._image
	End Function
	
	Function Create:TImg(image:TImage, filename:String) 
		If Not g_L_imageFiles Then g_L_imageFiles = CreateList() 
		Local img:TImg = New TImg
		img._filename = filename
		img._image = image
		g_L_imageFiles.AddLast(img) 
		Return img
	End Function
End Type
