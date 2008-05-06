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

' deltatimer and FPS calculation/limiting
Type TDelta
	Field _time:Double
	Field _maxdt:Float
	Field _FrameCounter:Int
	Field _isFrameRateLimited:Int
	Field _TargetFPS:Int
	Field _TargetDelta:Double
	Field _CurrentFPS:Int
	Field _FPSTime:Double
	Field _currentDelta:Double
	Field _isFirstRound:Int = True
	Field _timeCompression:Float = 1
	
	Method GetFPS:Int() 
		Return _currentFPS
	End Method
	
	' If compression = False, the returned delta is not affected by time compression.
	' Useful for GUI related timing (zooming, scrolling etc)
	Method GetDelta:Double(compression:Int = True) 
		If compression = True Then Return _currentDelta * _timeCompression
		Return _currentDelta
	EndMethod
	
	' calculates the new delta value based on the timestamp recorded on the previous frame
	Method Calc() 
		Local newTime:Double = MilliSecs() 
		If newTime - _time > _maxdt Then _time = _maxdt
		_currentDelta = (newTime - _time) / 1000.0
		
		' cap the delta to maxdt milliseconds to avoid time skipping when alt-tabbing etc
		If _currentDelta > _maxdt / 1000.0 Then _currentDelta = _maxdt / 1000.0
		
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
		If Not _isFrameRateLimited Then Return
		Delay(_targetDelta * 1000.0 - (MilliSecs() - _time)) 
	End Method
	
	Method isFrameRateLimited:Int() 
		Return _isFrameRateLimited
	End Method
	
	Function Create:TDelta(target:Int, isLimited:Int = True, maxi:Float = 500) 
		Local delta:TDelta = New TDelta
		delta._time = MilliSecs() 
		delta._maxdt = maxi
		delta._TargetFPS = target
		delta._TargetDelta = 1.0 / delta._TargetFPS
		delta._CurrentFPS = delta._TargetFPS
		delta._FPSTime = delta._time + 1000
		delta._FrameCounter = delta._TargetFPS
		delta._isFrameRateLimited = isLimited
		Return delta
	End Function
End Type
