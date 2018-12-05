extensions [profiler]

;;create two types of turtles
breed [preys prey]
breed [hunts hunt]

;;globals variables
globals 
[
  ;;default-prey-vision-distance
  ;;default-prey-vision-cone
  prey-alarm-distance
  prey-run-speed
  prey-run-energy
  prey-vision-distance
  prey-vision-cone
  prey-look-for-food-utility-pow
  prey-run-away-utility-pow
  hunt-run-speed
  hunt-run-energy
  day-night
  day-night-tick-count
  daytime
  day-night-color-offset
  current-preys-color-offset
  prey-camo-effect
  normalized-camo-value
  ;;default-hunt-vision-distance
  ;;default-hunt-vision-cone
  hunt-vision-distance
  hunt-vision-cone
  prey-killed-without-noticed
  prey-killed-when-being-chase
  prey-killed-when-heading-home
  prey-killed-by-hunger
]

;;preys's own variables
preys-own 
[
  prey-visible-food
  prey-temp-patch
  prey-energy
  prey-feel-stave-energy
  prey-energy-from-grass
  prey-birth-consume-energy
  prey-birth-require-energy  
  prey-max-energy
  prey-speed
  prey-look-for-food-utility
  prey-run-away-utility
  prey-head-home-utility
  prey-stay-home-utility
  prey-max-utility-value
  prey-utility-action
  ]

;;hunts's own variables
hunts-own 
[
  hunt-visible-food
  hunt-energy
  hunt-energy-from-prey
  hunt-birth-consume-energy
  hunt-birth-require-energy
  hunt-max-energy
  hunt-speed
]
 
;;set up patches, turtles and default variables
to setup
  clear-all
  set daytime true
  set day-night true
  set day-night-tick-count 0
  setup-patches
  setup-prey-turtles
  setup-hunt-turtles
  reset-ticks
end

to reset-default
  set hunts-stay-same? false
  set prey-number 30
  set hunt-number 15
  set default-prey-speed-increase-rate 0.05
  set default-hunt-speed-increase-rate 0.05
  set default-prey-energy-consume-multiplier 2
  set default-hunt-energy-consume-multiplier 2
  set prey-default-run-speed 0.5
  set hunt-default-run-speed 0.7
  set default-prey-alarm-distance 5
  set default-prey-alarm-distance-increase-rate 0.5
  set default-prey-vision-distance 15
  set default-prey-vision-cone 120
  set default-hunt-vision-distance 20
  set default-hunt-vision-cone 60
  set default-prey-color 45
  set default-prey-color-increase-rate 0.5
  set default-prey-look-for-food-exponent 3
  set default-prey-run-away-exponent 0.9
  set exponent-increase-rate 1.1
  set exponent-decrease-rate 0.9
  set default-prey-cone-increase-and-decrease-rate 5
  set default-prey-energy 500
  set default-hunt-energy 500
  set default-prey-food-energy 20
  set default-hunt-food-energy 300
  set default-prey-birth-consume-energy 300
  set default-hunt-birth-consume-energy 400
  set default-prey-birth-require-energy 600
  set default-hunt-birth-require-energy 700
end
;;profiler for performance test
to test
profiler:start         ;; start profiling
repeat 1 [ go ]       ;; run something you want to measure
profiler:stop          ;; stop profiling
print profiler:report  ;; view the results
profiler:reset         ;; clear the data
end


;;set up preys's start attributes  
to setup-prey-turtles
  create-preys prey-number 
  ask preys
  [
    set color default-prey-color
    ;;setxy (-0.9 * max-pxcor) (-0.9 * max-pycor)
    set prey-temp-patch one-of patches with [pcolor > grey - 2 and pcolor < grey + 1]
    setxy [pxcor] of prey-temp-patch [pycor] of prey-temp-patch 
    set prey-vision-distance default-prey-vision-distance
    set prey-vision-cone default-prey-vision-cone
    set prey-energy default-prey-energy
    set prey-feel-stave-energy 300
    set prey-energy-from-grass default-prey-food-energy
    set prey-birth-consume-energy default-prey-birth-consume-energy
    set prey-birth-require-energy default-prey-birth-require-energy
    set prey-max-energy 1000
    set prey-run-speed prey-default-run-speed 
    set prey-run-energy (prey-run-speed * default-prey-energy-consume-multiplier)
    set prey-alarm-distance default-prey-alarm-distance
    set prey-look-for-food-utility-pow default-prey-look-for-food-exponent
    set prey-run-away-utility-pow default-prey-run-away-exponent
    set prey-killed-without-noticed 0
    set prey-killed-when-being-chase 0
    set prey-killed-when-heading-home 0
    set prey-killed-by-hunger 0
   ]
end

;;set up hunts's start attributes  
to setup-hunt-turtles
   create-hunts hunt-number
   ask hunts
   [
     set color red
     setxy (0.9 * max-pxcor) (0.9 * max-pycor)
     set hunt-vision-distance default-hunt-vision-distance
     set hunt-vision-cone default-hunt-vision-cone
     set hunt-energy default-hunt-energy
     set hunt-energy-from-prey default-hunt-food-energy
     set hunt-birth-consume-energy default-hunt-birth-consume-energy
     set hunt-birth-require-energy default-hunt-birth-require-energy
     set hunt-max-energy 1000
     set hunt-run-speed hunt-default-run-speed
     set hunt-run-energy (hunt-run-speed * default-hunt-energy-consume-multiplier)
   ] 
end

;;set up different types of patches
to setup-patches
  ask patches
  [
     setup-food 
     setup-savezone  
  ]
end

;;main loop
to go   
  prey-camo-calculate
  prey-decision
  hunt-decision
  change-prey-speed
  move-prey
  move-hunt
  eat-grass
  eat-prey
  prey-birth
  hunt-birth
  regrow-grass
  check-death
  day-night-cycle
  tick
end



;;Calculate prey's behavious based on the use of utility ai
to prey-decision

ask preys
[     

;;calculate utility values 
;;hard code utility value that force the prey to head home when their energy is going to be full
if prey-energy > prey-max-energy * 0.9
  [set prey-head-home-utility 1]
if pcolor > grey - 2 and pcolor < grey + 1  
  [set prey-head-home-utility 0]
  
;;calculate the look for food desire value by using quadratic curves that based on the prey's remaining energy, also affect by the camo value to decide if its suitable to go out  
set prey-look-for-food-utility (((prey-max-energy - prey-energy) / prey-max-energy) ^ prey-look-for-food-utility-pow) + (normalized-camo-value - 0.5)
  
;;calculate the run away desire value when any hunts within prey's vision and certain distance by using rotated quadratic curves that based on the distance between the hunts and the prey itself  
ifelse pcolor < grey - 2 or pcolor > grey + 1
  [
    if any? hunts in-radius (prey-alarm-distance)  
    [
      if any? hunts in-cone prey-vision-distance prey-vision-cone
      [
      ;set prey-run-away-utility 1 - ([distance myself] of min-one-of hunts [distance myself] / prey-alarm-distance)
      set prey-run-away-utility ([distance myself] of min-one-of hunts [distance myself] / prey-alarm-distance) ^ prey-run-away-utility-pow
      ]
    ]
  ]    
[set prey-run-away-utility 0]
    

;;calculate the stay home utility value based on if the prey is current in save zone and any hunts nearby, this is also the default action if none of the prey's desire value is greater than 0
ifelse pcolor > grey - 2 and pcolor < grey + 1 and any? hunts in-radius (10)
   [set prey-stay-home-utility count hunts in-radius (10) / 10]
   [set prey-stay-home-utility 0.01]
 
   
   
    
;;find the action with the highest utility value      
;;because max-one-of does not support list, need to go through a more complex way which use max funtion to find the highest utility in a list first, and then find the action that has the same value as that max value in order to find the correct action
set prey-max-utility-value max (list prey-head-home-utility prey-look-for-food-utility prey-run-away-utility prey-stay-home-utility)

if prey-max-utility-value = prey-head-home-utility
[set prey-utility-action 1]
if prey-max-utility-value = prey-look-for-food-utility
[set prey-utility-action 2]
if prey-max-utility-value = prey-run-away-utility
[set prey-utility-action 3]
if prey-max-utility-value = prey-stay-home-utility
[set prey-utility-action 4]


  
;;perform soemthing based on the chosen action  
;;go toward to the nearest save zone when heading back or being chase action has been choose
  if prey-utility-action = 1 or prey-utility-action = 3
  [
    set heading towards min-one-of patches with [pcolor > grey - 2 and pcolor < grey + 1] [distance myself]
  ]
  
;;look for nearest patches with pcolor above 51 (green) when look for food action has been choose, if no suitable patches found then move around  
  if prey-utility-action = 2 
  [
    set prey-visible-food (patches with [pcolor > 51] in-cone prey-vision-distance prey-vision-cone)
    
    ifelse any? prey-visible-food 
   [set heading towards min-one-of prey-visible-food [distance myself]] 
   [ rt random 20
     lt random 20]
     if not can-move? 1 
     [ rt 180 ]
  ]

;;force the prey to stay still if this action has been choose and they are in safe zone, if not in safe zone then it will be direct to safe zone first
  if prey-utility-action = 4
  [
    ifelse pcolor > grey - 2 and pcolor < grey + 1
    [set prey-speed 0]
    [set prey-speed prey-run-speed
     set heading towards min-one-of patches with [pcolor > grey - 2 and pcolor < grey + 1] [distance myself]]
  ]
  
  ;if prey-look-for-food = false and prey-energy < prey-feel-stave-energy and not any? hunts in-radius (10)
  ;[ 
    ;set prey-look-for-food true
   ;]   
    
]   
   
end


;;decision of hunts
to hunt-decision
  
;;update hunts vision abilites based on the prey's camo value
  set hunt-vision-distance default-hunt-vision-distance - (prey-camo-effect * 2)
  set hunt-vision-cone default-hunt-vision-cone - (prey-camo-effect * 4)
  
 ask hunts
  [
    ;;store preys within thery vision into a variable
   set hunt-visible-food (turtles with [color > 40 and color < 50 ] in-cone hunt-vision-distance hunt-vision-cone) 
    
    ;;give up and turn back when it is near prey's save zone, otherwise head toward if it find any preys within their vision, it nothing found move around
  ifelse any? (patches with [pcolor > grey - 2 and pcolor < grey + 1] in-cone 5 hunt-vision-cone)
   [rt 180] 
   [ifelse any? hunt-visible-food  
   [set heading towards min-one-of hunt-visible-food [distance myself]] 
   [ rt random 20
     lt random 20]
     if not can-move? 1 [ rt 180 ]]
  ]
end


;;change prey's move or idle state during some special situation
to change-prey-speed
 ask preys
 [
  
  ;;prey running when returning cave or not on top of grass
  if (pcolor > 10 and pcolor < 52) or prey-utility-action != 4
  [set prey-speed prey-run-speed]
  
  ;;prey stop and eating grass 
  if pcolor > 52 and prey-utility-action = 2
  [set prey-speed 0]
  
  ;;prey stop in cave
  ;;if (pcolor > grey - 2 and pcolor < grey + 1 and prey-utility-action = 1) or (pcolor > grey - 2 and pcolor < grey + 1 and prey-utility-action = 3)
  ;;[set prey-speed 0]
  
  ]
end


;;consume prey's energy each tick, energy consume reduce by half when stay idle
to move-prey
  ask preys[
   forward prey-speed
   
   ifelse prey-speed = 0
   [set prey-energy prey-energy - (prey-run-energy / 2)]
   [set prey-energy prey-energy - prey-run-energy]
   
  ]
end


;;consume hunt's enery each tick
to move-hunt
  ask hunts
  [
    set hunt-speed hunt-run-speed
    forward hunt-speed
    if not hunts-stay-same?
    [set hunt-energy hunt-energy - hunt-run-energy]
  ]
end


;;prey will eat grass when they are stay on top of green patch and their action is set to look for food, patch color will decrease and prey energy will increase each tick when doing so
to eat-grass
  ask preys
  [
    if prey-utility-action = 2
    [
      if (pcolor > 52)
      [
        set pcolor pcolor - 0.1
        set prey-energy (prey-energy + prey-energy-from-grass)
      ]
    ]        
  ]
end


;;where hunts eat prey and gain energy, also change prey's attributes
to eat-prey
  ask hunts
  [
    ;;gain energy if it get very close to a prey
    if(any? preys in-radius (size / 2))
    [
      if not hunts-stay-same?
      [
      set hunt-energy hunt-energy + hunt-energy-from-prey 
      ]
  
      ;;change prey's attributes based on different situation 
      ask preys in-radius (size / 2) 
      [
        ;;increase alarm distance, vision cone and decrease vision distance when prey get killed when eating grass without notice hunt was coming
        if(pcolor > 52 and prey-utility-action = 2) 
        [
          set prey-killed-without-noticed prey-killed-without-noticed + 1
          set prey-alarm-distance prey-alarm-distance + default-prey-alarm-distance-increase-rate
          if prey-vision-cone < 270
          [set prey-vision-cone prey-vision-cone + default-prey-cone-increase-and-decrease-rate
          set prey-vision-distance ((default-prey-vision-cone / prey-vision-cone) * default-prey-vision-distance)]
        ]
        
        ;;increase speed and energy consumption when get killed while heading home
        if(prey-utility-action = 1) 
        [
          set prey-killed-when-heading-home prey-killed-when-heading-home + 1
          set prey-run-speed prey-run-speed + default-prey-speed-increase-rate
          set prey-run-energy (prey-run-speed * default-prey-energy-consume-multiplier)
        ]
        
        ;;increase speed and energy consumption, also decrease the exponent of run away utility and increase the exponent of look for food utility when get killed while being chase
         if(prey-utility-action = 3) 
        [
          set prey-killed-when-being-chase prey-killed-when-being-chase + 1
          set prey-run-speed prey-run-speed + default-prey-speed-increase-rate
          set prey-run-energy (prey-run-speed * default-prey-energy-consume-multiplier)
          set prey-run-away-utility-pow prey-run-away-utility-pow * exponent-decrease-rate
          set prey-look-for-food-utility-pow prey-look-for-food-utility-pow * exponent-increase-rate
         
        ]
        ;;change preys color depending on the time they get kill for camo effect
         ask preys
          [            
              ifelse daytime = true
              [if color != 49[set color color + default-prey-color-increase-rate]]
              [if color != 41[set color color - default-prey-color-increase-rate]]            
          ]
        die
      ]
    ]
  ]
end


;;very slightly increase the color value of the grass patches when it is within certain range
to regrow-grass
  ask patches[
    if (pcolor > 51 and pcolor < green)
    [set pcolor pcolor + 0.001]
  ]
end 


;;allow prey to hatch when they have enough energy and within safe zone
to prey-birth
  ask preys
  [
    if prey-energy > prey-birth-require-energy and pcolor > grey - 2 and pcolor < grey + 1
    [set prey-energy prey-energy - prey-birth-consume-energy
      hatch 1 ]
  ]
end


;;allow hunts to hatch whenever they have enough energy
to hunt-birth
  ask hunts
  [
    if not hunts-stay-same?
    [
      if hunt-energy > hunt-birth-require-energy
      [set hunt-energy hunt-energy - hunt-birth-consume-energy
        hatch 1 ]
    ]
  ]
end


;;check if turtles have enough energy to stay alive
to check-death
  
  ask preys
  [
    ;;show preys energy label when switch is on
     ifelse show-energy?
    [set label precision prey-energy 1]
    [set label ""]
    
    ;;increase vision distance, the exponent of run away utility and decrease vision cone angle and the exponent of look for food utility when killed by hunger
    if prey-energy <= 0 
    [
      set prey-killed-by-hunger prey-killed-by-hunger + 1
      if prey-vision-distance > 5
      [set prey-vision-cone prey-vision-cone - default-prey-cone-increase-and-decrease-rate
      set prey-vision-distance ((default-prey-vision-cone / prey-vision-cone) * default-prey-vision-distance)]
      set prey-run-away-utility-pow prey-run-away-utility-pow * exponent-increase-rate
      set prey-look-for-food-utility-pow prey-look-for-food-utility-pow * exponent-decrease-rate
      die
    ]
  ]
  
  ask hunts
  [
     ;;show hunts energy label when switch is on
     ifelse show-energy?
    [set label precision hunt-energy 1]
    [set label ""]
    
    ;;increase speed and energy consumption when killed by hunger
    if hunt-energy <= 0 
    [set hunt-run-speed hunt-run-speed + default-hunt-speed-increase-rate
     set hunt-run-energy (hunt-run-speed * default-hunt-energy-consume-multiplier)
     die]
  ]
  
end


;;set up green food patches in specified locations, other location will be set to brown
to setup-food  
  ifelse (distancexy (0.6 * max-pxcor) (0.2 * max-pycor)) < 7 or (distancexy (-0.2 * max-pxcor) (-0.3 * max-pycor)) < 4 or (distancexy (-0.3 * max-pxcor) (0.4 * max-pycor)) < 5
  [ set pcolor green]
  [ set pcolor brown]
  
end


;;set up grey safe zone in specified locations 
to setup-savezone
  if(distancexy (-0.9 * max-pxcor) (-0.9 * max-pycor) < 3 or distancexy (0.3 * max-pxcor) (-0.9 * max-pycor) < 3 or distancexy (-0.9 * max-pxcor) (0.7 * max-pycor) < 3)
  [set pcolor grey]
end


;;set up day night cycle effect
to day-night-cycle

set day-night-tick-count day-night-tick-count + 1

;;switch between day and night every 100 ticks
 if day-night-tick-count >= 100 and day-night = true
[
 set day-night-tick-count 0
 set day-night false
]
if day-night-tick-count >= 100 and day-night = false
[
  set day-night-tick-count 0
 set day-night true
]

;;change patches colors depending on day or night  
  ask patches
[
  ifelse day-night = true
  [set pcolor pcolor - 0.02]
  [set pcolor pcolor + 0.02]  
]

;;use one of the specifed patch as a sample to determine if it is currently day time or night time
 ask patch 0 0
 [
   ifelse pcolor > 34
   [set daytime true]
   [set daytime false]
 ]
end


;;calculate the prey's camo value
to prey-camo-calculate
  
  ;;get the offset of the day night color by using one of the current patch color and subtrack it by the middle color of that patch (max 35, min 33)
  ask patch 0 0
  [
  set day-night-color-offset pcolor - 34
  ]
  ;;get the offset of the prey's color by using the current preys color subtrack it by the middle color of the preys (max 49, min 41)
  ask preys
  [     
  set current-preys-color-offset color - 45
  ]
  ;;get the camo value by multiply the two value above, which will be used to determine the final hunt vision values
  set prey-camo-effect day-night-color-offset * current-preys-color-offset
  ;;a normalized camo value that use by look for desire value 
  set normalized-camo-value (prey-camo-effect - (-4)) / (4 - (-4))
end
@#$#@#$#@
GRAPHICS-WINDOW
672
10
1292
651
30
30
10.0
1
12
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
15
10
78
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
96
10
159
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
12
143
91
188
NIL
count preys
17
1
11

SWITCH
203
54
337
87
show-energy?
show-energy?
0
1
-1000

PLOT
1306
26
1531
212
Remaining Amimals
time
totals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"preys" 1.0 0 -13345367 true "" "plot count preys"
"hunts" 1.0 0 -2674135 true "" "plot count hunts"

SLIDER
10
54
182
87
prey-number
prey-number
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
10
96
182
129
hunt-number
hunt-number
0
100
15
1
1
NIL
HORIZONTAL

MONITOR
109
143
188
188
NIL
count hunts
17
1
11

MONITOR
14
264
250
313
Preys's vision distance
prey-vision-distance
2
1
12

MONITOR
267
264
473
313
Preys's vision cone angle
prey-vision-cone
2
1
12

MONITOR
1114
675
1350
724
Hunts's vision distance
hunt-vision-distance
2
1
12

MONITOR
1367
675
1574
724
Hunts's vision cone angle
hunt-vision-cone
2
1
12

MONITOR
20
404
218
453
Preys's running speed
prey-run-speed
2
1
12

MONITOR
1115
764
1311
813
Hunts's running speed
hunt-run-speed
2
1
12

MONITOR
235
405
462
454
Preys's energy consume per tick
prey-run-energy
2
1
12

MONITOR
1328
766
1555
815
Hunts's energy consum per tick
hunt-run-energy
2
1
12

MONITOR
11
551
287
600
Preys's alarm distance
prey-alarm-distance
2
1
12

MONITOR
614
768
834
817
NIL
prey-look-for-food-utility-pow
17
1
12

MONITOR
856
768
1042
817
NIL
prey-run-away-utility-pow
17
1
12

MONITOR
601
290
663
339
NIL
daytime
17
1
12

MONITOR
11
763
169
812
Preys's current color
mean [color] of preys
2
1
12

MONITOR
174
763
346
812
Day-night offset value 
day-night-color-offset
2
1
12

MONITOR
364
762
557
811
Preys's color offset value
current-preys-color-offset
2
1
12

MONITOR
11
710
149
759
Preys's camo value
prey-camo-effect
2
1
12

MONITOR
293
843
451
892
NIL
normalized-camo-value
17
1
12

TEXTBOX
126
245
424
271
Higher cone angle will result lower distance
12
0.0
1

TEXTBOX
101
386
433
412
Higher speed will result more energy consume
12
0.0
1

TEXTBOX
16
524
274
576
Higher alarm distance will result leaving food source earlier when detect hunts
12
0.0
1

TEXTBOX
175
729
584
767
Represent the offset from their middle color, which used to produce prey's camo value
12
0.0
1

TEXTBOX
7
667
439
719
positive and high value will result the better preys can hid from hunts and preys will look for food more aggressively, negative and low value will result the opposite
12
0.0
1

TEXTBOX
1271
657
1567
683
Affect by preys's camo value
12
0.0
1

TEXTBOX
603
260
676
294
True=day\nFalse=night
12
0.0
1

SWITCH
200
96
369
129
hunts-stay-same?
hunts-stay-same?
1
1
-1000

TEXTBOX
294
814
464
853
Used of calculate the final look for food desire value
12
0.0
1

TEXTBOX
613
727
849
792
Exponent of quadratic equation, default 3.0, the lower the value, the higher the look for food desire value get
12
0.0
1

TEXTBOX
860
725
1119
799
Exponent of rotated quadratic equation, default 0.9, the lower the value, the higher the run away desire value get
12
0.0
1

SLIDER
14
488
395
521
default-prey-speed-increase-rate
default-prey-speed-increase-rate
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
1116
853
1497
886
default-hunt-speed-increase-rate
default-hunt-speed-increase-rate
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
15
453
217
486
prey-default-run-speed
prey-default-run-speed
0
2
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
1114
818
1316
851
hunt-default-run-speed
hunt-default-run-speed
0
2
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
8
312
251
345
default-prey-vision-distance
default-prey-vision-distance
0
50
15
0.1
1
NIL
HORIZONTAL

SLIDER
267
312
483
345
default-prey-vision-cone
default-prey-vision-cone
0
270
120
0.1
1
NIL
HORIZONTAL

SLIDER
1115
728
1358
761
default-hunt-vision-distance
default-hunt-vision-distance
0
50
20
0.1
1
NIL
HORIZONTAL

SLIDER
1363
728
1579
761
default-hunt-vision-cone
default-hunt-vision-cone
0
270
60
0.1
1
NIL
HORIZONTAL

SLIDER
10
598
246
631
default-prey-alarm-distance
default-prey-alarm-distance
0
20
5
0.1
1
NIL
HORIZONTAL

SLIDER
10
631
343
664
default-prey-alarm-distance-increase-rate
default-prey-alarm-distance-increase-rate
0
2
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
6
817
180
850
default-prey-color
default-prey-color
41
49
45
0.1
1
NIL
HORIZONTAL

SLIDER
6
853
277
886
default-prey-color-increase-rate
default-prey-color-increase-rate
0
1
0.5
0.5
1
NIL
HORIZONTAL

SLIDER
224
453
536
486
default-prey-energy-consume-multiplier
default-prey-energy-consume-multiplier
0
5
2
0.1
1
NIL
HORIZONTAL

SLIDER
1318
819
1630
852
default-hunt-energy-consume-multiplier
default-hunt-energy-consume-multiplier
0
5
2
0.1
1
NIL
HORIZONTAL

SLIDER
560
817
852
850
default-prey-look-for-food-exponent
default-prey-look-for-food-exponent
1
10
3
0.1
1
NIL
HORIZONTAL

SLIDER
854
817
1111
850
default-prey-run-away-exponent
default-prey-run-away-exponent
0.1
1
0.9
0.1
1
NIL
HORIZONTAL

BUTTON
175
10
370
44
reset slider values to default
reset-default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
856
854
1058
887
exponent-increase-rate
exponent-increase-rate
1
1.5
1.1
0.1
1
NIL
HORIZONTAL

SLIDER
649
853
851
886
exponent-decrease-rate
exponent-decrease-rate
0.1
1
0.9
0.1
1
NIL
HORIZONTAL

SLIDER
10
346
364
379
default-prey-cone-increase-and-decrease-rate
default-prey-cone-increase-and-decrease-rate
0
20
5
1
1
NIL
HORIZONTAL

SLIDER
6
197
187
230
default-prey-energy
default-prey-energy
100
1000
500
10
1
NIL
HORIZONTAL

SLIDER
196
198
377
231
default-hunt-energy
default-hunt-energy
100
1000
500
10
1
NIL
HORIZONTAL

SLIDER
389
10
605
43
default-prey-food-energy
default-prey-food-energy
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
390
47
606
80
default-hunt-food-energy
default-hunt-food-energy
0
1000
300
10
1
NIL
HORIZONTAL

SLIDER
388
88
666
121
default-prey-birth-consume-energy
default-prey-birth-consume-energy
0
900
300
10
1
NIL
HORIZONTAL

SLIDER
388
127
666
160
default-prey-birth-require-energy
default-prey-birth-require-energy
0
900
600
10
1
NIL
HORIZONTAL

SLIDER
388
169
666
202
default-hunt-birth-consume-energy
default-hunt-birth-consume-energy
0
900
400
10
1
NIL
HORIZONTAL

SLIDER
389
211
667
244
default-hunt-birth-require-energy
default-hunt-birth-require-energy
0
900
700
10
1
NIL
HORIZONTAL

PLOT
1541
232
1741
382
Current Camo Effect
time
camo effect
0.0
10.0
-5.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot prey-camo-effect"

PLOT
1298
395
1712
648
Preys Behaviours
time
totals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"looking" 1.0 0 -13840069 true "" "plot count preys with [prey-utility-action = 2]"
"runnin" 1.0 0 -2674135 true "" "plot count preys with [prey-utility-action = 3]"
"hidding" 1.0 0 -7500403 true "" "plot count preys with [prey-utility-action = 4]"

PLOT
1543
77
1743
227
Running Speed
time
speed
0.0
5.0
0.0
2.0
true
true
"" ""
PENS
"preys" 1.0 0 -13791810 true "" "plot prey-run-speed"
"hunts" 1.0 0 -2674135 true "" "plot hunt-run-speed"

PLOT
1297
214
1535
384
Preys Die Reason
time
numbers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"starve" 1.0 0 -13840069 true "" "plot prey-killed-by-hunger"
"chase" 1.0 0 -2674135 true "" "plot prey-killed-when-being-chase"
"head home" 1.0 0 -7500403 true "" "plot prey-killed-when-heading-home"
"not noticed" 1.0 0 -13791810 true "" "plot prey-killed-without-noticed"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
