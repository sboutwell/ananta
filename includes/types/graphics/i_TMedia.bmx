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
	
	Function LoadImg:TImage(filename:String) 
		AutoImageFlags MASKEDIMAGE | FILTEREDIMAGE | MIPMAPPEDIMAGE	' flags For LoadImage()

		If Not g_L_imageFiles Then g_L_imageFiles = CreateList() 
		
		' if the file has already been loaded, return it instead of reloading it
		For Local img:TImg = EachIn g_L_imageFiles
			If img.GetFileName() = filename Then Return img.GetImage() 
		Next
		
		AutoMidHandle True
		Local image:TImage = LoadImage(g_mediaPath + filename) 
		If Not image Then Return Null
		
		Local img:TImg = New TImg
		img._filename = filename
		img._image = image
		g_L_imageFiles.AddLast(img) 
		
		Return img._image
	End Function
End Type
