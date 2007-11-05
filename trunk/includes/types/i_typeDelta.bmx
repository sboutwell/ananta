' deltatimer and FPS calculation/limiting
Type TDelta
	Field _time:Float
	Field _maxdt:Float
	Field _FrameCounter:Int
	Field _TargetFPS:Int
	Field _TargetDelta:Float
	Field _CurrentFPS:Int
	Field _FPSTime:Float
	Field _currentDelta:Float
	Field _isFirstRound:Int = True
	
	Method GetFPS:Int() 
		Return _currentFPS
	End Method
	
	Method GetDelta:Float() 
		Return _currentDelta
	EndMethod
	
	Method Calc() 
		Local newTime:Float = MilliSecs() 
		If newTime - _time > _maxdt Then _time = _maxdt
		_currentDelta = (newTime - _time) / 1000
		
		' cap the delta to 0.25s to avoid time skipping when alt-tabbing etc
		If _currentDelta > 0.25 Then _currentDelta = 0.25
		
		_time = newTime
		
		' calc FPS
		_FrameCounter:+1
		If _FPSTime < _time
			_CurrentFPS = _FrameCounter' <- Frames/Sec
			_FrameCounter = 0
			_FPSTime = _time + 1000	'Update once per second
		EndIf
						
	End Method
	
	Method LimitFPS() 
		Delay(_targetDelta * 1000.0 - (MilliSecs() - _time)) 
	End Method
	
	Function Create:TDelta(target:Int, maxi:Float = 500) 
		Local delta:TDelta = New TDelta
		delta._time = MilliSecs() 
		delta._maxdt = maxi
		delta._TargetFPS = target
		delta._TargetDelta = 1.0 / delta._TargetFPS
		delta._CurrentFPS = delta._TargetFPS
		delta._FPSTime = delta._time + 1000
		delta._FrameCounter = delta._TargetFPS
		Return delta
	End Function
End Type
