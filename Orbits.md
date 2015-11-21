## The problem ##

I've been done some tests to make planets orbit the sun, moons orbit the planets **and** make them maintain their orbits without noticeable degration. Using Euler method in calculating gravitational effects frame-by-frame seems to give very unreliable results when using a variable time step. Circular orbits become elliptical and even closing or opening spirals. Somehow I knew this would be happening when I chose to implement a simple delta-timer in a physics simulation. Live and learn.

The problem persists even in a two-body environment (as opposed to gravity calculations between _every_ stellar object).


### Solutions ###


  * Fixed time step
This would be by far the most elegant solution, but would require a major overhaul of the current physics and rendering engines. [Decoupling rendering from the physics](http://www.blitzbasic.com/codearcs/codearcs.php?code=2039) would probably be the way to go. Squeezing this into the current codebase will need some serious hacking.


  * Fixed orbits
Planetary orbits would follow x and y coordinates returned by a function that calculates orbital position as a function of time. It'd nail the orbits right where we want them. It would take away the real orbital simulation aspect from the game, though.


  * Orbital "checkpoints"
The target orbiting distance would be recorded with each orbiting body, and periodical checks are made against the current distance to the desired distance. If there's a deviation, some kind of a correction would then take place. How to make the correction without making the simulation "jump"? Dynamically adjusting the orbital velocity from time to time would probably do the trick, but this would be a really ugly hack probably resulting in even more bizarre symptoms.


  * Forget about it
The orbit degration is noticeable only after many hours of running the simulation in the same solar system, probably even weeks or months with real-life sized solar systems. The orbital positions will probably be re-calculated upon every re-entry to the system, and so it's very unlikely that any player would ever notice that the planetary bodies follow an eccentric orbit.