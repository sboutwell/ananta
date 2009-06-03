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

' timing and FPS calculation/limiting
Type TGameTimer
	' timing stuff
	Field _timestep:Double = 1000 / 60 ' 60 fps in millisecs
	Field _t:Double = 0	' current time
	Field _dt:Double = 0 ' elapsed frame time
	Field _accumulator:Double = 0
	Field _tween:Double = 0
	Field _newTime:Double = 0 ' time in the beginning of the frame
	Field _maxdt:Float

	' FPS stuff
	Field _FrameCounter:Int
	Field _isFrameRateLimited:Int
	Field _TargetFPS:Int
	Field _TargetDelta:Double
	Field _CurrentFPS:Int
	Field _FPSTime:Double
	Field _timeCompression:Double = 1
	Field isPaused:Int = False
	
	Method GetFPS:Int() Return _currentFPS End Method
	Method GetTimeCompression:Double() Return _timeCompression EndMethod
	Method SetTimeCompression(t:Double) _timeCompression = t EndMethod
	
	' If compression = False, the returned timestep is not affected by time compression.
	' Useful for GUI related timing (zooming, scrolling etc)
	Method GetTimeStep:Double(compression:Int = True) 
		If compression = True Then Return (_timestep * _timeCompression) / 1000:Double
		Return _timestep / 1000:Double ' return in seconds
	EndMethod
	
	Method TogglePause()
		ToggleBoolean(isPaused)
	End Method
	
	Method HasEnoughAccumulatedTime:Int()
		 Return _accumulator >= _timestep
	End Method
	
	Method Decrement()
		_accumulator :- _timestep
	End Method
	
	Method CalcTween()
		_tween = _accumulator / _timestep
	End Method
	
	' calculates the new delta value based on the timestamp recorded on the previous frame
	Method Calc() 
		_newTime = MilliSecs()
		_dt = _newTime - _t
		_t = _newTime
		If _dt > _maxdt Then _dt = _maxdt ' cap to 250ms
	
		_accumulator:+ _dt ' store remaining time in accumulator
		
		CalcFPS()
		
		If isPaused Then 
			_t = MilliSecs()
		End If						
	End Method
	
	Method CalcFPS()
		_FrameCounter:+1
		If _FPSTime < _t
			_CurrentFPS = _FrameCounter' <- Frames/Sec
			_FrameCounter = 0
			_FPSTime = _t + 1000	'Update once per second
		EndIf
	End Method
	
	Method LimitFPS() 
		If Not _isFrameRateLimited Then Return
		Delay(_targetDelta * 1000.0 - (MilliSecs() - _t)) 
	End Method
	
	Method isFrameRateLimited:Int() 
		Return _isFrameRateLimited
	End Method
	
	Function Create:TGameTimer(target:Int, isLimited:Int = True, maxi:Float = 500) 
		Local timer:TGameTimer = New TGameTimer
		timer._t = MilliSecs() 
		timer._maxdt = maxi
		timer._TargetFPS = target
		timer._TargetDelta = 1.0 / timer._TargetFPS
		timer._CurrentFPS = timer._TargetFPS
		timer._FPSTime = timer._t + 1000
		timer._FrameCounter = timer._TargetFPS
		timer._isFrameRateLimited = isLimited
		Return timer
	End Function
End Type
