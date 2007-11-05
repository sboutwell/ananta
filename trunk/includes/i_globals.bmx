'read the Debug flag state from settings.xml
Global G_debug:Int = XMLGetSingleValue(c_SettingsFile,"settings/debug").ToInt()

'media globals	(get rid of this)
Global G_media_jupiter:TImage

' create the screen and initialize the graphics mode
' Make it global so that viewport:TViewport is accessible everywhere
Global viewport:TViewport = TViewport.Create()

Global G_delta:TDelta = TDelta.Create(XMLGetSingleValue(c_SettingsFile, "settings/graphics/framerate").ToInt()) 
