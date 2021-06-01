# CCEnrollmentPrediction
All files associated with the enrollment prediction project

## Overview
This project is intended to demonstrate the use of 'stacked' models when predicting enrollment numbers. This should include the following steps

1) Generate data
2) Fit stacked model
3) Fit single model
4) Compare models
5) Write up

## Goals

1) Generate 'enrollment' data that is the output of two different processes at different levels of aggregation
2) Demonstrate comparative advantage of modelling processes differently vs fitting one type of model
3) Write up a short report; aiming for the ~5 page 'report' format in CCJRP

## Notes for Abby

### 05/31/21 notes

- I added a diagram for how I think the data generation process should go
- 'Processes' that involve model fitting or generation are cylinders
- Let me know if my diagram makes any sense

I tried to be as explicit as possible in writing out how i think this data should be generated. I didn't go into detail on the variables I was thinking of using, but i think sticking to a simple process is best, so a limited number of variables will be best. I was thinking: gender and cumulative credit load at the individual level and GDP at the semester level. 

### 06/01/21 notes

I took a first stab at generating the data that we can fit models to later down the road. Let me know if this process seems reasonable to you or if I've messed something up. In particular, I'm not sure if I implemented the link function properly to generate probabilities of return at line 81. I think my initial values for a bunch of things were roughly correct but I haven't done much diagnosing to make sure my values are reasonable. For example, I think the proportion of new to returning students looks roughly correct but I'd be happy to be proved wrong. Finally, might it be a good idea for me to put in a data request at SLCC just asking for super basic summary stats like the distribution of credit loads to make those variables more 'realistic'? I don't want to dive too far down that rabbit hole because I don't think it ultimately matters too much but I'd be happy to hear your thoughts.