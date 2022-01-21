__includes [ "archive.nls" "env.nls" "groups.nls" "people.nls" "results.nls" ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed [ groups group ]
breed [ families family ]
breed [ people person ]

globals [

  ;Counters and statistics for person-to-person conversations (internal influence)
  contacts                ;; number of contacts made with other individuals
  old-contacts            ;; previous total
  contacts-per-time       ;; how many contacts made this time period
  conversation-starts     ;; total number of conversations
  old-conversation-starts ;; previous total
  starts-per-time         ;; how many conversations made this time period - number ended
  conversation-ends       ;; total number ended
  old-conversation-ends   ;; previous total
  ends-per-time           ;; how many conversations made this time period - number ended
  active-conversations    ;; total number of conversations currently active
  friend-total            ;; keep track of conversations - strangers, acquaintences, buddies

  ;External influence counters and statistics
  externals               ;; total number of external mass media contacts

  ;Color
  tech0-color
  tech1-color
  tech2-color

]

;Attributes for patches (other than Netlogo-defined attributes)
patches-own [
 intensity               ;; used to create degrees of influence (rather than a static background)
 original-color          ;; used in conjunction with external influence
]

;People have attributes
people-own [
  acceptance             ;; acceptance of shared idea
  end-time               ;; when current conversation will end
  initiator?             ;; keep track of who initiates the conversation
  media?                 ;; Keep track of whether individual is listening to mass media presentation, such as billboard or magazine ad
  memory                 ;; list of partners that can be used for altering rules of interaction in a future model
  myfamily               ;; group membership
  mygroup                ;; group membership
  mytype                 ;; some charateristic of person
  num-conversations      ;; cumulative number of conversations
  num-externals          ;; cumulative number of interactions with external media
  partner                ;; The person that is our current partner in a conversation
  status                 ;; 0 for a potential, 1 for type 1 innovation (adoption), 2 for type 2 innovation (disruption)
  start-time             ;; when current conversation starts
  total-external-time    ;; cumulative time spent with external media
  total-interact-time    ;; cumulative time spent in conversation
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  ;;Check inputs
  let total-prob prob-innovator + prob-early-adopter + prob-early-majority + prob-late-majority + prob-laggard
  if (total-prob != 100 )
  [
      print (word "Adoption types must sum to 100, but instead sum to " total-prob)
      stop
  ]

  setup-globals       ;initialize to 0
  setup-env           ;patches
  setup-people        ;individuals
  setup-histo1        ;initialize graph needed at time 0
  setup-histo2        ;initialize graph needed at time 0

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-globals

  ;set random seed to user number unless 0 chosen
  let my-seed select-seed           ;set once at beginning of model
  if random-seed-switch? [ set my-seed new-seed ]
  random-seed my-seed
  output-print my-seed

  ;internal influence globals
  set contacts 0
  set old-contacts 0
  set contacts-per-time 0.0
  set conversation-starts 0
  set old-conversation-starts 0
  set starts-per-time 0
  set conversation-ends 0
  set old-conversation-ends 0
  set ends-per-time 0
  set active-conversations 0
  set friend-total 0

  ;external influence globals
  set externals 0

  ;color
  set tech0-color black
  set tech1-color magenta
  set tech2-color violet
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RUNTIME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go

  if (simlength > 0) [
    if (ticks >= simlength) [ stop ]
  ]


  ;People who are not currently in a conversation will:
  ; (a) think about their current adoption status, possibly changing their mind about an adoption or disruption.  They may
  ;     return to a potential, whereby they are subject to the influences of internal or external factors.
  ;     If they are already a "technologist," they may adopt the disruption if they are already an tech1 or adopt
  ;     the adoption if already a tech2. Note that this latter case is based on "personal reflection" rather than
  ;     due to external or internal influences.
  ; (b) move a little
  ; (c) check to see if they are on a "media center" patch, in which case they may adopt after hearing the message
  ; (d) they check to see if someone is around to talk to about technologies
  ;If already paired, they update their type.
  ;
  ;In latest versions of Netlogo, "without interruption" directive no longer needed
  ask people
  [
        ;external influence is only for those whose kind is not the same as the media center.
        if MASS-MARKET-1? and [pcolor] of patch-here > tech1-color - 5 and [pcolor] of patch-here < tech1-color + 5 [
          check-external-adoption
        ]
        if MASS-MARKET-2? and [pcolor] of patch-here > tech2-color - 5 and [pcolor] of patch-here < tech2-color + 5 [
          check-external-disruption
        ]

        ;internal influence - if partner = self, mass media is in effect, so internal influence is ignored in
        ;areas of mass media.  May need to reconsider this assumption.
        ifelse partner = nobody [
            if mytype = 1 [rethink-adoption]
            if mytype = 0 [rethink-disruption]
            move
            if [pcolor] of patch-here = black [ initiate ]
        ][
            if partner != self [
              interact
            ]
        ]
   ]

  ;plots are controlled by specific routines, not by update-plots primitive (which is run by tick now)
  update-plot-pop
  update-plot-type
  update-plot-type-current
  update-plot-mem
  update-monitors

  ;clock update
  tick

end
@#$#@#$#@
GRAPHICS-WINDOW
854
16
1366
529
-1
-1
14.4
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
14
42
89
112
NIL
Setup
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
238
43
316
112
On/Off
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
307
381
340
total-population
total-population
0
1000
100.0
1
1
people
HORIZONTAL

SLIDER
11
675
374
708
prob-conversation
prob-conversation
0
100
57.8
0.1
1
percent
HORIZONTAL

SLIDER
11
712
374
745
conversation-length
conversation-length
0
100
4.0
1
1
time units
HORIZONTAL

PLOT
856
561
1369
779
Populations
Simulated Time
Number of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Potentials" 1.0 0 -7500403 true "" ""
"Adopters" 1.0 0 -2674135 true "" ""
"Disruptors" 1.0 0 -955883 true "" ""
"Total" 1.0 0 -16777216 true "" ""

SLIDER
12
401
194
434
prob-innovator
prob-innovator
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
11
178
374
211
select-seed
select-seed
-2147483648
2147483647
-4.5369373E8
1
1
NIL
HORIZONTAL

SLIDER
409
84
654
117
tech1-coefficient-acceptance
tech1-coefficient-acceptance
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
411
240
659
273
tech2-coefficient-acceptance
tech2-coefficient-acceptance
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
10
639
374
672
movement
movement
0
10
2.0
1
1
patches per move
HORIZONTAL

SLIDER
410
161
656
194
prob-tech1-to-tech2
prob-tech1-to-tech2
0
5
0.0
0.1
1
percent
HORIZONTAL

SLIDER
410
123
655
156
prob-tech1-to-potential
prob-tech1-to-potential
0
5
0.1
0.1
1
percent
HORIZONTAL

SWITCH
409
47
651
80
Internal-Tech1?
Internal-Tech1?
0
1
-1000

SWITCH
410
202
661
235
Internal-Tech2?
Internal-Tech2?
1
1
-1000

SLIDER
410
277
660
310
prob-tech2-to-potential
prob-tech2-to-potential
0
5
0.0
0.1
1
percent
HORIZONTAL

SLIDER
409
312
661
345
prob-tech2-to-tech1
prob-tech2-to-tech1
0
5
0.2
0.1
1
percent
HORIZONTAL

TEXTBOX
550
488
690
529
External Influence
16
15.0
0

SLIDER
409
355
663
388
change-agent
change-agent
0
100
53.0
1
1
percent
HORIZONTAL

SLIDER
406
602
529
635
x-disrupt
x-disrupt
-100
100
21.0
1
1
NIL
HORIZONTAL

SLIDER
406
566
527
599
x-adopt
x-adopt
-100
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
532
602
651
635
y-disrupt
y-disrupt
-100
100
-53.0
1
1
NIL
HORIZONTAL

SLIDER
531
566
650
599
y-adopt
y-adopt
-100
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
406
714
837
747
prob-to-adopt-mass-market-1
prob-to-adopt-mass-market-1
0
100
97.0
1
1
%
HORIZONTAL

SLIDER
407
750
837
783
prob-to-adopt-mass-market-2
prob-to-adopt-mass-market-2
0
100
94.0
1
1
%
HORIZONTAL

SLIDER
654
566
833
599
s-adopt
s-adopt
0
100
23.0
1
1
NIL
HORIZONTAL

SLIDER
654
602
835
635
s-disrupt
s-disrupt
0
100
19.0
1
1
NIL
HORIZONTAL

SWITCH
407
528
622
561
MASS-MARKET-1?
MASS-MARKET-1?
1
1
-1000

SWITCH
625
527
833
560
MASS-MARKET-2?
MASS-MARKET-2?
1
1
-1000

SLIDER
406
676
836
709
listening-time
listening-time
0
50
1.0
1
1
time units
HORIZONTAL

PLOT
1385
38
1775
171
Initial Adoption Type
Innovators    EarlyAdopt    EarlyMaj    LateMaj    Laggard
Frequency
0.0
6.0
0.0
50.0
true
false
"" ""
PENS
"mytype" 1.0 1 -13345367 true "" ""

SLIDER
12
440
194
473
prob-early-adopter
prob-early-adopter
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
10
479
194
512
prob-early-majority
prob-early-majority
0
100
36.0
1
1
%
HORIZONTAL

SLIDER
9
517
194
550
prob-late-majority
prob-late-majority
0
100
34.0
1
1
%
HORIZONTAL

SLIDER
9
554
195
587
prob-laggard
prob-laggard
0
100
5.0
1
1
%
HORIZONTAL

SLIDER
406
640
836
673
Smoothness
Smoothness
0
50
18.0
1
1
repeitions
HORIZONTAL

TEXTBOX
565
15
720
38
Internal Influence
16
15.0
1

SLIDER
196
440
382
473
earlyadopter
earlyadopter
6
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
198
479
381
512
earlymajority
earlymajority
11
15
11.0
1
1
NIL
HORIZONTAL

SLIDER
201
517
382
550
latemajority
latemajority
16
20
16.0
1
1
NIL
HORIZONTAL

SLIDER
200
554
383
587
laggard
laggard
21
25
21.0
1
1
NIL
HORIZONTAL

TEXTBOX
94
285
286
312
Demographic Parameters
16
15.0
1

SLIDER
12
140
375
173
simlength
simlength
0
10000
3000.0
10
1
NIL
HORIZONTAL

BUTTON
166
42
237
112
Step 50
let knt 0\nloop [\n   if knt = 50 [ stop ]\n   set knt knt + 1\n   go\n]\n
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
90
41
165
112
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1385
176
1774
308
Category of Adopters
Innovators    EarlyAdopt     EarlyMaj    LateMaj   Laggard
Frequency
0.0
6.0
0.0
50.0
true
false
"" ""
PENS
"adopted" 1.0 1 -13345367 false "" ""

SWITCH
12
750
374
783
link-switch
link-switch
0
1
-1000

TEXTBOX
14
344
106
391
Set Population Distribution (sum to 100%)
12
0.0
1

TEXTBOX
201
347
391
395
Set Acceptance Factor\n(1 for Geeks, others have\nnon-overlapping ranges)
12
0.0
1

SLIDER
195
401
381
434
innovator
innovator
1
1
1.0
1
1
cannot be reset
HORIZONTAL

TEXTBOX
142
611
292
632
Conversations
16
15.0
1

MONITOR
111
348
185
393
Sum
prob-innovator + prob-early-adopter + prob-early-majority + prob-late-majority + prob-laggard
0
1
11

OUTPUT
192
217
373
250
12

TEXTBOX
666
133
721
151
Renege
12
0.0
1

TEXTBOX
672
293
822
311
Renege
12
0.0
1

TEXTBOX
667
170
817
188
Switch technology
12
0.0
1

TEXTBOX
664
87
799
135
Accept Tech 1 (divided by Acceptance Factor)
12
0.0
1

TEXTBOX
671
246
805
278
Accept Tech 2 (divided by Acceptance Factor)
12
0.0
1

TEXTBOX
671
327
821
345
Switch Technology
12
0.0
1

PLOT
1385
310
1776
482
Groups
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Innovators" 1.0 0 -2674135 true "" ""
"EarlyAdopter" 1.0 0 -13840069 true "" ""
"EarlyMajority" 1.0 0 -11221820 true "" ""
"LateMajority" 1.0 0 -13345367 true "" ""
"Laggard" 1.0 0 -7858858 true "" ""

PLOT
1387
489
1777
683
Memory
NIL
NIL
0.0
100.0
0.0
20.0
false
false
"" ""
PENS
"mem" 1.0 1 -16777216 true "" ""

TEXTBOX
663
58
822
90
On/Off Technology 1
13
0.0
1

TEXTBOX
672
212
806
234
On/Off Technology 2
13
0.0
1

TEXTBOX
1555
16
1705
36
Results
16
15.0
1

TEXTBOX
670
354
839
434
If both technologies turned on, percentage of Innovators set to Tech1.  Tech2 is 1 - this value.
13
0.0
1

SWITCH
12
216
189
249
random-seed-switch?
random-seed-switch?
0
1
-1000

TEXTBOX
115
10
265
30
Runtime Parameters
16
15.0
1

MONITOR
1389
688
1577
741
Mean No. in Memory
mean [length memory] of people
2
1
13

MONITOR
1390
743
1482
796
Contacts
contacts-per-time
0
1
13

MONITOR
1486
744
1577
797
Starts
starts-per-time
0
1
13

MONITOR
1579
744
1671
797
Ends
ends-per-time
0
1
13

MONITOR
1674
744
1774
797
Ongoing
active-conversations
0
1
13

MONITOR
1579
688
1776
741
Familiarlity
friend-total / conversation-starts
2
1
13

@#$#@#$#@
# INTERACTIONS

  A model of "individual and Group Interactions". The original model, described below, focused on the diffusion of innovations.  It is being generalized to broader sets of interactions, so this file will be updated when progress in that direction is made.

# WHAT IS IT? 

This model focuses on the diffusion and adoption of new ideas or technologies based on 

(1) Internal influences (e.g., word-of-mouth)
(2) External influences (e.g., mass media)

This has been the traditional focus of research into the "diffusion of innovations" (see references below).  The LOGISTIC curve is often used to describe internal influences (e.g., the "Bass Model"). In this model, there are a small group of "innovators," or "geeks," who must have everything as soon as it is introduced.  They spread the word, which may take some time because other potential users need to be convinced of the efficacy of the new idea or technology.  This slow rise in the number of adopters reaches a "tipping point" in which a lot of "potentials" accept the new idea or technology.  After a while, the rate of new adoption decreases and slow reduces to a trickle.  The logistic curve is a good representation of this phenomenon.

On the other hand, advertisements through mass media hit the market all at once and are said to lead to more rapid acceptance.  A NEGATIVE EXPONENTIAL curve is often used to represent this behavior.  Think of the "Super Bowl" phenomenon, where companies spend millions to reach a huge audience.

In addition, the model examines the influences of two new technologies or ideas.  This is the case of VHS vs BETA, the MAC vs the PC, or perhaps cultural ideas that compete for the same population.  The latter problem is more complex than represented since "memes" are a gross oversimplification of how culture works. 

# MODEL OVERVIEW

In the model, individuals are divided into five groups: "Innovators" who MUST have the latest technology at all costs; "Early Adopters" who need a little prompting; "Early Majority" who may need further prompting; "Late Majority" who don't like change; and "Laggards" who will rarely, if ever, adopt anything new.  The percentages of each type are set by sliders (see left side of model interface).  If the sum of these percentages does not equal 100, the model will stop during the Setup procedure and indicate the error in the "Observer" panel at the bottom of the interface.

Each of these five types of people has an "Acceptance" factor - how easily they will adopt the technology on a scale from 1 - 25, with 1 being reserved for the definite acceptance of an innovator; 6 - 10 for "Early Adopters; 11 - 15 for "Early Majority";
16 - 20 for "Late Majority"; and 21 - 25 for "Laggards." These ranges can be altered by editing the sliders. Innovators have already adopted one of the two technologies at the beginning of the model.  Again, sliders are used to set these values.  Note that these values are multiplied by a coefficient of acceptance, so that

    1.0/acceptance_factor * acceptance_coefficient 

determines whether a technology is adopted. These parameters are described below.

Individuals move through the state space, where they meet and interact with other individuals who may have adopted a new technology, adopted an even newer "disruptive" technology, or are "potential" adopters like themselves. If a "potential" interacts with an "adopter," he or she MAY become an "adopter" based on the acceptance probabilities and the category of user to which they belong (e.g., "Early Majority").  The same holds true for "potentials" interacting with "disrupters." "Adopters" and "disruptors" may interact as well, either with their own "kind" or the competing "kind."

There are also parameters for "adopters" to "renege" and return to "potentials" or to "defect" to the even newer "disrupter" technology and discard their "adopter" innovation. Analogous parameters are available for "disrupters."  Switches are available to restrict the model to a single technology or idea competing with the status quo, or to examine two new innovations hitting a population simultaneously or after some lag period.

External influence impacts may also be studied. The impact of mass media is based on the length of time a user spends in a particular region (using different shades of a color to represent "strength" of the influence, as well as different colors to represent two different innovations - "adopter" technologies and "disrupter" technologies.

Future versions of this model will look at intermediate approaches to the spread of technologies or ideas - i.e., "targeted broadcasts," where specific individuals in the population will receive the message simulataneously.  In the current model, interactions are either one-on-one or broadcast to a group within a specified area. The area can be a subset of the population, but it is designated by geographical space, not individuals with particular attributes.


# MODEL SETUP

The model interface is divided into eight parts. 

## Runtime Parameters

  (a) SETUP button to initial the run, 3 STEP buttons, and an ON/OFF button. The 3 STEP buttons move the model the designated number of "ticks" forward. The ON/OFF button is the usual "GO FOREVER" control.

  (b) Slider to stop the simulation after a certain number of "ticks."

  (c) If the random seed switch is on, a new seed is chosen for each run.  If it is off, the slider value is used for the seed. This latter case is used to replicated the results exactly from one run to another (as long as other parameters are not changed). If the slider is changed during a run, it has no effect until SETUP is pressed again. 
  
  (d) Ability to create a movie out of the simulation.  Press the MOVIE button, choose a name for the movie, and the simulation executes for the number of frames set in the slider. Use a ".mov" extension.  It works with Quicktime.

## Demographic Parameters

  (a) Population size - In this version of the model, the population size remains constant.

  (b) This population must be divided into five categories. The output display labeled "Sum" indicates the percentage of the total that has been set by the 5 sliders below it.  This must equal 100% before pressing SETUP.  People who have already adopted the technology or idea at the beginning of the model are "Innovators."  "Early Adopters" are interested in new technologies or ideas but need some prompting.  "Early Majority" and "Late Majority" are somewhat more reluctant to change.  "Laggards" will rarely, if ever, adopt anything new.

  (c) Acceptance Factor - each group will adopt technologies or ideas based on an adoption factor (discussed below) multiplied by an "Acceptance Factor" set here.  Higher numbers mean less chance of adopting.  The categories are non-overlapping. "Innovators" have already adopted the technology or idea at the beginning of the model; their value is fixed at 1, the "Adoption Factor."

## CONVERSATIONS
 
  (a) The model is based on the movement of people, and so their movement per "tick" is adjustable by the modeler.

  (b) If they meet another person, there is a probability of interacting, based on the "prob-conversation" parameter.

  (c) The conversation will last a certain amount of time, meaning that the two people will not move for that length of time.  A square object surrounds the pair during this length of time.  If a person adopts the innovation based on the various modeling parameters set for the conversation, and the link switch has been turned on, there will be a link drawn between the two people that remains during the remainder of the simulation.  This is an indicator of "friendship" or "acquaintanceship."  If the population size is high, this will result in an output display resembling a Jackson Pollack painting, so only use it for small population sizes.  The intent of this link is to eventually expand the model to look at the formation of social networks, including fading of the link over time...

  (d) If the population is not too high, it is useful to observe connections between individuals who have met AND led to acceptance of an innovation/idea.  The links do not "fade" over time in the current model. Note that there is a "memory" attribute for each 	individual, but that records all meetings, whereas the link is only drawn if a successful "transaction" has occurred.

## INTERNAL DIFFUSION PARAMETERS
	
  (a) Link-switch: A switch to turn links between people on or off.  If on, a link is drawn between two people who have met, conversed, and an "adoption" of a technology or idea has occurred.

  (b) For each technology, there is one switch and three sliders:

    - Internal-Tech switch - turn on internal disffusion for this technology.
	
    - Acceptance Coefficient - Multiplier for that technology. This value divided
      by the Accpetance Factor for each category of user determines the probability of
      adopting the technology in question.  
	
    - Renege Factor - Giving up on the new technology and returing to "Potential"
      status.  
	
    - Switch Factor - Probability of changing between the two technologies.

  (c) Change-agent - display showing percent of Innovators for each of the two technologies at the start of the run. If only one technology is on, all of the change agents have adopted that technology at time 0.
  	
  
## EXTERNAL INFLUENCE
	
  (a) Switch to turn on one, none or both external diffusion models.

  (b) Rectangular areas are set with the x-, y- and s- sliders. x- and y- set the center of the area for external diffusion. The s- parameter is the size of the rectange.  So a (0,0) position is the center of the display, while an "s" parameter 	= 100 will cover the entire display.  There is a "triplet" for each technology; they should not overlap.  

  (c) "Smoothness" is an idea borrowed from a Community model on the "Fitness Landscape."  The reference is provided below. This varies the degree to which a user adopts the new technology or idea - with colors varying from dark to light to         indicate more influence.  Technology 1 uses purple; brown is used for technology 2.  Netlogo's color palette ranges from black through dark shades of the chosen color to light shades and then white.

  (d)	Listening-time is the number of ticks the user hears the message while in the rectangular space.  

  (e) Adoption probability is set for each technology - the probability of adopting that technology during the listening time.

## DISPLAY

  (a) Internal diffusion depicts people and "conversations" that take place at each tick step.  Links may be drawn if one of the "potentials" adopts a technology.

  (b) External diffusion depicted as a rectangle with varying amounts of "advertising capability" - lighter shade better.

## ADOPTION CATEGORY HISTOGRAMS

  (a) "Initial Adoption Type" - Used to illustrate how many people are in each category at the beginning of a run.

  (b) "Category of Adopters" - Depicts the number of each category that have adopted either of the two technologies.

## RESULTS

  (a) Populations - plots potentials and adopter/disruptor population over time.

  (b) Groups - breaks down adopters and disruptors by category of user.

  (c) Memory - when two individuals meet, a reference to that person is stored in memory.  Right now, it remains there for the duration of the simulation; forgetfulness will be added in a future release.  This feature is not actually used in the model, but a list of contacts may prove useful in future versions of the model.

  (d) Monitors - Mean no. of partners in memory is tabulated, along with a measure of "familiarity" among the people in the simulation as measured by the total number of people already met before ("friends") divided by the number of conversation starts.  
  
  (e) Actual conversation stats are also included - number of contacts between people, how many lead to a converstation starting, how many previous conversations end during this tick, and how many conversations continue on.
    

# HOW IT WORKS 

## Demography

The population size is set by the modeler and does not change during each run.  What changes are the percentages of each type of user:

  (a) "Innovators" in the typical parlance of innovation theory who start out the simulation using the new innovation.

  (b) "Early Adopters" who will decide to adopt if the idea or technology sounds good.

  (c) "Early Majority" who are a little hesitant and wait to see what others are doing.
 
  (d) "Late Majority" who are very hesitant.
 
  (e) "Laggards" who basically wait until the technology is no longer considered innovative.

Note that (a) through (e) correspond to the categories commonly seen in the literature. These people will be created by pressing the SETUP button and will move around the display interacting with other folks ("internal diffusion") or examining mass media or other general forms of information about the innovation ("external diffusion").  A
"link-switch" can be turned on to add a communications channel between any two nodes. In this version of the model, the link remains in place for the duration of the simulation.

## Individual Behavior

Individuals who are not currently in a "conversation" will perform a number of steps:

  (a) Think about their current status, possibly changing their mind after accepting a new technology: they may return to a "Potential," whereby they are subject to the influences of internal or external factors. If they are a technologist ("Adopter" or "Disrupter"), they may become a "Disrupter" if they are currently an "Adopter" or an "Adopter" if currently a "Disrupter." Note that these changes are based on "personal reflection" rather than due to external or internal influences. These changes are based on slider values "prob-tech1-to-potential," "prob-tech1-to-tech2," "prob-tech2-to-potential" and "prob-tech2-to-tech1."

  (b) Move a little based on the "movement" slider set in the interface. 

  (c) Check to see if they are on a "media center" patch, in which case they may accept a new technology after hearing a "mass media presentation."

  (d) Finally, they check to see if someone is around to talk to about technologies. The "movement" parameter" and "prob-conversation" sliders help determine how often
     conversations occur - just meeting someone does not guarantee that a conversation about technology occurs. If a conversation does occur, one individual is the initiator and the other the recipient of information.

  (e) If an individual is already paired, he or she will update his or her status. Whether to accept the new technology is based on the slider probability for each technology. This is only checked at the end of the conversation, not once per time unit. These sliders are "tech1-coefficient-acceptance" and "tech2-coefficient-acceptance." However, each of these values is divided by a factor set for each individual's type (see Demographic Parameters below). For example, an "Innovator" may accept the new technology at the general "coefficient-acceptance"      level, where as a "laggard" may be given a high resistance factor, say 10, meaning that acceptance is 1/10th of the general "coefficient-acceptance" level.

## Statistics

Output graphs provide a number of summaries for the modeler's use.  In addition, debugging statements are printed to the screen.  These may be saved in other tools (e.g., Excel) for further analysis.

# HOW TO USE IT

The model was originally built as a guide to reading through the literature on the diffusion of innovations; some references are provided below. The basic idea is that internal diffusion will follow a logistic curve based on the notion that as word spreads, there will be a threshold until the new technology or innovation "takes off."
After a number of people have accepted the new technology or idea, the adoption rate slows down because the remaining users just don't see the point.  So there is a "life cycle" to technologies or ideas, and, after a while, new concepts are needed to begin the process anew. As a result, we see iPhones and other technologies going through "new
releases," whereby some folks just have to have the latest, while others wait to see what the fuss is about.  It would be interesting to investigate how many cycles a particular technology can go through before people get "bored."  It's not clear that "ideas" go through the same life cycle.  This model could be used to study "memes" since it focuses on horizontal transmission of units.  But this raises all sorts of complications that beg for further analysis.  As well as extensions to include vertical transmission of ideas and technologies (i.e., parents to offspring, one generation to the next, ...).

# THINGS TO TRY
Note change in rate of technology adoption based on parameters. The "expected" behavior is a logistic curve for a single technology introduced by word-of-mouth. A strictly "mass media" introduction will spread more rapidly, shooting up to the maximum after a small delay (depending upon parameter settings) - a negative exponential model.

Adding a second technology after a short delay leads to all sorts of interesting behavior. In some cases, the newer technology will not be able to gain a foothold. If reneging is added, or if "Adopters" can switch to the "Disrupter" technology, the technology curves become quite complex. According to theory, at least, a "Disrupter" technology often needs to hit a specific niche in order to gain a foothold once an "Adopter" technology has saturated the market (e.g., "WII" vs Playstation 3 vs. Xbox 360 marketing strategies).

# EXTENDING THE MODEL 

As social media has grown over the past decade, topics such as tipping points, crowdsourcing, focused advertising,  "influencers", gorilla marketing and social media highlight some possible ways to make use of the basic framework of this model and extend it into several different areas.  

A few thoughts: 

  (a) Change agents - Rogers  (see references) talks about the importance of change agents to facilitate adoption of new technologies or ideas. In the current model, the innovator class provides the change agents - either type 1 or 2 or split between the two depending on the change-agent parameter(a percentage of type 1 is set by the user, so that type 2 is 1 - that percentage; ignored if only one technology/idea used).  In a future model, other characteristics can be added to these agents so they can talk to multiple people at once or have some other characteristics that facilitate change.
   
  (b) Internet - The classic diffusion models differentiate individual contacts from mass media. The Internet, however, is really a combination of the two, providing "intimate" conversations with a single user, but marketing to a wide audience.

  (c) Social Networking - links can be placed between any two nodes, similar to SNA software.  Calculations could be added for degree of centrality and other measures used in Social Network Analysis (SNA). 

  (d) Make more use of "memory" - acceptance changes with familiarity of partner.

  (e) Mixed mode diffusion - e.g., web-based diffusion seems like a mixture of internal and external diffusion models.

  (f) Calibrate with math models of diffusion - would like to see how the various combinations of parameters relate to various mathematical models of diffusion.

  (g) Radical vs. Incremental Innovation - idea of an "innovation" and a "disruption" examine these distinctions through variable values but not through changes in the logic. iPhones, tablets, cloud provisioning are all impacting the concept of the desktop computer, building off of the old (1960s) concepts of time-sharing with dumb terminals accessing mainframes.

  (h) Extensions to radical vs. incremental innovation: Henderson & Clark (1990) note that the distinction between radical and incremental change is incomplete, creating a 2x2 matrix that adds the categories of (1) "modular innovation" (where "core concepts" are overturned as in radical innovation but linkages between components and core concepts are left unchanged, as in incremental innovation) and "architectural innovation" (where core concepts are reinformed as in incremental innovation but linkages are changed as in radical innovation).  The iPhone can arguably be considered an architectural innovation from Apple's standpoint - it takes the core ideas of
graphics, ease of use, a closed OS, etc. - just like Apple computers - but it adds a new twist that appears radical to the cell phone industry.  How to account for the diffusion of such ideas is not yet clear.  Indeed, the percentages of "early adopters" for Apple technology may have to be considered a separate category from the general population of "early adopters."


# NETLOGO FEATURES 

(1) Includes - the original model was set up in one file.  It has since been divided into multiple .nls files to maintain code on each portion of the model.  The main program is used to establish breeds and their attributes, as well as globals.  The "go" portion of the model is also contained here.

(2) Early versions of the model set the "adoption category" of individuals directly in code. The technique was suggested to me on the Community Web Pages, and so I have included it here because I thought it was an interesting programming construct.  

The idea is that some folks are "innovators" and will try anything new. Some will never adopt anything new, and others are spread out into other groups. Rogers (see references below) discusses a normal distribution with 5 categories such as 1 & 2 (the early adopters) = 5 (adopt with a lot of resistance) and two middle categories, 3 & 4. This is referred to as the "kind-structure" in the model. Category 1 is set by the number of "adopters" + "disrupters" - those who already have the new innovation at the start of the simulation. To determine the rest of the population, an array is set up in the initialization part of the model: 

    ;The first entry is the category type; the second is a probability. 
    set kind-structure [ [ 2 12 ] [ 3 47 ] [ 4 81 ] [ 5 100 ] ]  

This is used in the following reporter routine:   

    to-report determine-kind [ probability-index ]  
      let this_kind first ( first ( filter [ last ? >= probability-index ] 
            kind-structure ) )
      print this_kind+":"+probability-index+":"+filter 
            [ last ? >= probability-index ] kind-structure  
      report (this_kind)  
    end  

The "let" statement was graciously explained to me through the community web pages. This routine is called during setup in this model to determine the kind of adopter:   

    to setup-people   
       cct-people initial-potentials [  
         set total-population initial-potentials + total-population  
         setup-people-parms  
         setup-potential  
         set kind determine-kind ( random 100 )  
       ]   
    end  

A good use of the "kind" attribute is to assign different adoption rates based on the kind of person under consideration. 

# CREDITS AND REFERENCES 

## Other Models 

The framework for this model is based on two great models on the Netlogo web site: 

  (a) AIDS - Copyright 1997 Uri Wilensky. All rights reserved. This provided the basic idea of pairing individuals on the same patch. 

  (b) Fitness Landscape - Copyright 2006 David McAvity. This model, from the Community Models section of the Netlogo web site, was created at the Evergeen State College, in Olympia Washington as part of a series of applets to illustrate principles in physics and biology. 

## References 

This model is actually a small portion of an ongoing effort to understand the "Innovation Process" from the invention of ideas and technologies to their development, diffusion, use and obsolescence. The overall model is being developed through System Dynamics, but agent-based modeling has been very helpful in clarifying ideas concerning the competition and spread of technologies. The background for this work comes from three sources: 

  (a) Mahajan, Vijay and Robert A. Peterson.   1985.  MODELS FOR INNOVATION DIFFUSION. Quantitative Applications in the Social Sciences, Sage Publications, 88 pages. 

  (b) Bass, F. M. 1969. "A new product growth model for consumer durables". Management Science 15: 215-227. 

  (c) Rogers, Everett M.   2003.  DIFFUSION OF INNOVATIONS (5th Edition).  Free Press, 512 pp. 

  (d) Henderson, Rebecca M. and Kim B. Clark.   1990. "Architectural Innovation: The Reconfiguration of Existing Product technologies and the Failure of Established Firms."  Administrative Science Quarterly 35:9-30.  

## Version

This version of the model has been imported into Netlogo 6.2.2 and will execute in Netlogo Web.  The interface is crowded, so a lot of scrolling is needed to see everything on the web.

# COPYRIGHT INFORMATION

Copyright 2009-2022 The MITRE Corporation. All rights reserved.

Approved for Public Release: Distribution Unlimited (Tracking #09-1575) 

"The author's affiliation with The MITRE Corporation is provided for identification purposes only, and is not intended to convey or imply MITRE's concurrence with, or support for, the positions, opinions or viewpoints expressed by the author." 

The model may be freely used, modified and redistributed provided the copyright and Public Release statements are included and the resulting models are not used for profit. Contact Michael Samuels at mijujoel@ieee.org if you have questions or comments.
   
  
========================  
Last updated: 2022/01/20 
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 109 6 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -1184463 true false 126 33 14
Circle -1184463 true false 156 34 13
Line -1184463 false 158 70 167 62
Polygon -1184463 true false 141 63 148 40 154 63
Rectangle -1184463 true false 135 70 160 75
Line -1184463 false 134 70 126 61
Polygon -1184463 true false 58 162 34 196 37 190
Rectangle -16777216 true false 30 180 45 195
Rectangle -16777216 true false 45 180 60 165
Rectangle -16777216 true false 60 180 45 165
Rectangle -16777216 true false 45 165 60 180

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
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
