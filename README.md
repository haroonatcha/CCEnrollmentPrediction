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

### 06/03/21 notes

Key takeaways
- Improved data generation process
- Started Modelling
- Fixed bugs

Detailed summary
I added a constant term to the 'likelihood of return' model to increase the mean retention rate and hold cohort levels stable. I also differentiated between semester credits and cumulative credits^[Unless we're going to assume that t = 1 is the very first semester our college accepted students (and other nonsense assumptions), we need to simulate cumulative credit loads for students at that time period. We *could* just increase our t and throw away the first 10-20 observations with the expectation that cumulative loads will find an equilibrium pretty quickly, but that seems like a wasteful way to do it when we can just simulate reasonable starting points.]. I also simplified the code for binding together 'new' and 'returning' students and realized that I was adding 'credit load' twice to new students. This has been fixed. I also added a few diagnostic plots and some of the tests I ran to see if we were producing reasonable simulations. It looks like we are but should probably toss out the first few (3-4) semesters when model fitting.

I also put together a preliminary model building file. This fits arima and linear models to the aggregate trends and compares them to the 'stacked' model. Unsurprisingly, the stacked model does better. Something to note though, it does better EVEN WITHOUT including the GDP term for new students. Seasonality alone gets us really close. This might be something I try to emphasize in the paper writing process.

### 06/06/21 notes

- Added a polynomial term stacked model for comparison
- Fixed a problem where I didn't specify family = 'binomial' in the individual model
- Calculated RMSE and MAE for the models
- Added line chart comparing different forecasts in 'results' section
- Updated model generation chart
- Added a linear model with a lagged term for comparison
- Changed the ARIMA portion of the stacked model to a linear model to better reflect data generating process

## Haroon's Garden of Forking Paths

Here I'm listing things that are either a problem or area for improvement, ordered by what I think is most to least important. Problems are **bolded**, nice-to-haves are not.

- ~~**Credits currently have a linear relationship with likelihood of return. This means that as times goes on, our 'enrolled' numbers start increasing exponentially since we get SUPER seniors with hundreds of credits. We need to change this relationship to a parabolic one, increasing up to N credit load (probably ~60, to align with graduation) and decreasing from there**~~
    - Update (06/02/21): I added exponential terms and seem to have roughly accomplished this. However, likelihood 'peaks' quite early and the penalty for approaching 60 credits is too high. We'll need to adjust these coefficients to make it lifelike.
    - Update (06/03/21): After fiddling with the coefficients, I'm actually happy with the influence of this variable. No observation has significantly more than 120 credits (3-4 years). While I might want to make this a 'peakier' relationship, for now I think it serves the purpose fine.

- ~~**I haven't disaggregated between current semester credits and cumulative credits. I use the 'credits' variable as the cumulative version but this should be changed.**~~
    - Update (06/02/21) I disaggregated credit load in the given semester and cumulative credits taken. This helped for diagnostic and analytic purposes.

- ~~**Right now, there's a non-returning rate of roughly 50% per period. This means to keep relatively stable numbers, there need to be about that many new students each semester. I'll need to find a better way of adjusting the return rate**~~
    - Update (06/02/21): I adjusted the number of new students each semester so that we stay around 1k each term. However, I think the underlying problem has to do with how I'm generating likelihood of returning. Mean return rate should be higher than 50%.
    - Update (06/03/21): I added a constant term to the 'likelihood of return' model that solves this problem. I think this is pretty much taken care of at this point. Any further tweaks will likely come in the form of fiddling with the coefficients and constant term and shouldn't require lots of dedicated time.

- It's unclear whether our new student / returning student proportion is reflective of real life dynamics. Perhaps I can submit a data request at SLCC for super aggregated summary stats showing that proportion?

- ~~It may be useful to add a seasonal component to our new student model. This would probably just be a t - 3 lag and we can name categories 'spring', 'summer', and 'fall'. That might capture the intuition that practitioners are more used to.~~
    - Update (06/03/21): I added semester binary columns and added a small effect for each in the 'new student' model. I don't add semester terms to returning student likelihood model. Though I'm sure this theoretically plays some role, I think the point of this exercise is to show that different populations act differently. If we *do* add these to the model of retention likelihood, it will be as a model for the constant (since semester is constant in any given semester) and it should have less pronounced effects. However, I'd like to stay away from overcomplicating things at this point. I'm gonna call this done.
    
- ~~I should model the new enrollees as an actual AR(3) process, maybe with a MA(1) term. Right now, I get half way there with the semester terms but it's not the correct~~
    - Update (06/03/21): I've changed my mind on this. I generated GDP change as a random walk process which, given how important the GDP term is in the new student model, imparts time series qualities to the # of new students anyway. Moreover, I think theoretically the # of new students *isn't* actually an autoregressive process. Gonna leave this as is.

- ~~Clean up the data generating chart for the paper. Right now it's needlessly complicated and the formulas can be taken out since they're in the body of the text.~~
    - Update (06/06/21) Removed and updated parts of this chart. Cut out a lot of the specific random sampling nodes and simplified a lot of the rest of it.
    
- ~~Adding the lagged term to the linear model immediately made it the best model out there. That doesn't necessarily fit with the point of the paper but I'm gonna try to roll with it. I need to find a way to incorporate this into the paper. Initially, I was thinking that having 'return' be a function of GDP as well (with different influence on returning vs new students) would show why you need to have theoretically informed models (i.e., the model would have difficulty finding the 'correct' estimate for the effect of GDP since it varies across sub-populations)~~
    - Update (06/07/21): See update below.

- ~~Iterate over a ton of datasets and get aggregate measures of MAE, MAPE, and RMSE
    - Update (06/07/21): Done. This solved the problem of the linear-lag model competing essentially head to head with~~ the stacked models. It's good on MAE and MAPE but is far more volatile on RMSE. My interpretation: it gets things right on average as often as the stacked models, but when it's wrong, it gets it WAY more wrong than the stacked models.
    
- Finish up writing the 'full' version and then cut it down to ~3 pages. I like having all the robustness checks and having iterated over 100 different datasets. I don't think the paper would have been complete without trying this. I think the analytical value in running a total 1k is limited and it'd take like, 18 hours so I'm gonna skip that for now unless reviewers request it. After writing up the long version, I'll trim it down to the required page length and settle on 1-2 graphics.
