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

## Haroon's Garden of Forking Paths

Here I'm listing things that are either a problem or area for improvement, ordered by what I think is most to least important. Problems are **bolded**, nice-to-haves are not.

1. **Credits currently have a linear relationship with likelihood of return. This means that as times goes on, our 'enrolled' numbers start increasing exponentially since we get SUPER seniors with hundreds of credits. We need to change this relationship to a parabolic one, increasing up to N credit load (probably ~60, to align with graduation) and decreasing from there**
  - Update (06/02/21): I added exponential terms and seem to have roughly accomplished this. However, likelihood 'peaks' quite early and the penalty for approaching 60 credits is too high. We'll need to adjust these coefficients to make it lifelike.

2. **I haven't disaggregated between current semester credits and cumulative credits. I use the 'credits' variable as the cumulative version but this should be changed.**

3. **Right now, there's a non-returning rate of roughly 50% per period. This means to keep relatively stable numbers, there need to be about that many new students each semester. I'll need to find a better way of adjusting the return rate**
  - Update (06/02/21): I adjusted the number of new students each semester so that we stay around 1k each term. However, I think the underlying problem has to do with how I'm generating likelihood of returning. Mean return rate should be higher than 50%.

4. It's unclear whether our new student / returning student proportion is reflective of real life dynamics. Perhaps I can submit a data request at SLCC for super aggregated summary stats showing that proportion?

5. It may be useful to add a seasonal component to our new student model. This would probably just be a t - 3 lag and we can name categories 'spring', 'summer', and 'fall'. That might capture the intuition that practitioners are more used to.