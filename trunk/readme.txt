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
vilumax (_at_) gmail (_dot_) com


Credits:
Bruce A. Henderson for libxml, Cairo and fontconfig wrappers
Darren A. Sexton for BSG ship sprites
Jim Stevenson for B5 ship sprites (shipschematics.net)




Ananta pre-alpha preview version
=========================

Unzip all files to a folder of your choosing and run main.exe.
XML files in "conf" folder should be self explanatory.
If you wish to run the game in full screen, change <bitdepth> 
setting to 16 or 32 in settings.xml. You may also want to
adjust <resolution> to a more comfortable setting.


Controls:
	Left arrow      - rotate ship left
	Right arrow     - rotate ship right
	Up arrow        - fire main engines
	Down arrow      - fire reverse engines
	
	z               - zoom in
	x               - zoom out
	shift+z         - minimap zoom in
	shift+x         - minimap zoom out
	ctrl+z          - reset zoom
	ctrl+x          - reset minimap zoom
	alt+enter       - toggle fullscreen mode
	ESC             - exit game
	F1              - display the control help

Sector map legend:
	Blue            - planet
	Red             - ship
	Cyan            - asteroid
	Yellow          - star
	Green line      - velocity vector

In this randomly generated scenario you are starting around 
the orbit of a planet. 
Zoom out (shift+x) in sector map to view the rest of the 
sector in the minimap. There is really not much to do other 
than explore the sector, play around with the various 
gravity wells and push asteroids to alter their trajectories.
For practice, try to achieve a circular orbit around any planet.
If you're having trouble, google for "Hohmann transfer" ;)

Known issues:
Collision detection between two fast-moving objects can be a bit "jittery".