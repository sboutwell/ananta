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
vilumax (_a t_) gmail (_d o t_) com


Credits:
Bruce A. Henderson for libxml, Cairo and fontconfig wrappers
Darren A. Sexton for BSG ship sprites
Jim Stevenson for B5 ship sprites (shipschematics.net)




Ananta pre-alpha preview version
================================

Unzip all files to a folder of your choosing and run main.exe.
XML files in "conf" folder should be self explanatory.
If you wish to run the game in full screen, change <bitdepth> 
setting to 16 or 32 in settings.xml or hit alt+enter ingame. 
You may also want to adjust <resolution> to a more comfortable setting.


In this randomly generated scenario you start in the orbit of a planet. 
The orbit is all but stable because of the close proximity 
of other planets and the central star.

Zoom out (shift+x) in sector map to view the rest of the 
sector in the minimap. Kill enemy ships (red dots in the minimap) 
and collect more shield power by destroying asteroids (cyan dots). 
The drifting enemy ships won't change their course, 
but they will fire at you if you come close enough. 
The goal is to survive and rid the sector of all baddies.

Play around with the various gravity wells and push asteroids 
around to alter their trajectories.
For practice, try to achieve a circular orbit around any planet.
If you're having trouble, google for "two-burn Hohmann transfer" ;)

Controls:
	Left arrow      - rotate ship left
	Right arrow     - rotate ship right
	Up arrow        - forward thrust
	Down arrow      - reverse thrust
	Ctrl            - fire weapon
	
	z               - viewport zoom in
	x               - viewport zoom out
	shift+z         - minimap zoom in
	shift+x         - minimap zoom out
	alt+z          	- reset viewport zoom
	alt+x          	- reset minimap zoom
	alt+enter       - toggle fullscreen mode
	ESC             - exit game
	F1              - show the control help

Sector map legend:
	Blue            - planet
	Red             - ship
	Cyan            - asteroid
	Yellow          - star
	Green line      - velocity vector
