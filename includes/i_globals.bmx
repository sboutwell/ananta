'read the Debug flag state from settings.xml
Global G_debug:Int = XMLGetSingleValue(c_SettingsFile,"settings/debug").ToInt()

'media globals
Global G_media_jupiter:TImage

'globals for calculating the frame rate
Global CalcFrameTimer:Float
Global CalcFrameRate:Int
Global FrameCounter:Int

' create the screen and initialize the graphics mode
' Make it global so that viewport:TViewport is accessible everywhere
Global viewport:TViewport = TViewport.Create()
