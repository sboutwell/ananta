# Introduction #

Here's an outline of a proposed way of generating a system

```
TSystem->Method.Populate()

seedrnd()

create main sun
   position

local planetdistance# =0
local startingTemperature = 0
local systemPopulation# =0

local planetChance[]

select star type
  case 0
      ' M flare star
      planetChance = [0,0,0,0,1,3]
      startingTemperature = 10000
  case ..
    ...
end select

for local i=0 to number of planets
  create new planet
  load its attributes from an XML file
  assign its random factors from this info
  
  position in the system (using planetDistance + random angle)

  depending on position (habitable) assign population, government, techlevel, danger level

  if habitable or random equivelant, create moons + stations
    place stations and moons in orbit

  inc new planetDistance for next planet
next

for local i=0 to random
  place asteroid belt randomly
next

End Method
```

Star------> 0 ----> 0 --------------> 0 ---> 0