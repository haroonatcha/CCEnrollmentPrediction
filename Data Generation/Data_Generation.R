library('truncnorm')
library('rlist')
library(logitnorm)
library(tidyverse)

# Functions for the data-generating process -------------------------------

# Generate GDP (random walk process)
generate_gdp = function(n_periods) {
  mean_gdp = 0
  sd_gdp = 1
  gdp = c()
  gdp = rnorm(1, mean = mean_gdp, sd = sd_gdp)
  for(i in 2:n_periods) {
    gdp = c(gdp, gdp[i-1] + rnorm(1, mean = mean_gdp, sd = sd_gdp))
  }
  gdp = gdp + abs(min(gdp))
  return(gdp)
}

# Generate new student counts
generate_new_student_counts = function(period_data) {
  # general linear model for enrollment which has linear relationship with GDP,
  # semester fixed effects, and noise
  B_GDP = 2
  B_spring = 3
  B_summer = 0
  B_fall = 6
  new_student_counts = (period_data$GDP * B_GDP) +
    (period_data$SeasonSpring * B_spring) + 
    (period_data$SeasonSummer * B_summer) +
    (period_data$SeasonFall * B_fall) + 
    rnorm(nrow(period_data),
          mean = 0,
          sd = 1)
  #un-standardizing the calculation so we can get sensible numbers
  mean_new_students = 150
  sd_new_students = 25
  new_student_counts <- round((new_student_counts * sd_new_students) + mean_new_students)
  return(new_student_counts)
}

# Generate a set of students and their demographic characteristics
generate_demographics = function(n_students) {
  proportion_female = 0.5
  students = data.frame(
    Gender = as.numeric(runif(n_students, 0, 1) < proportion_female)
  )
  return(students)
}

# Generate IDs (integers) for new students
generate_ids = function(n_students, current_max_id) {
  return((current_max_id + 1):(current_max_id + n_students))
}

# Generate credit loads for students
generate_credit_loads = function(n_students) {
  mean_credits = 9
  sd_credits = 4
  return(round(rtruncnorm(n_students, a = 1, b = 21,
                          mean = mean_credits, sd = sd_credits)))
}

# Generate total number of credits passed
generate_credits_earned = function(credit_loads) {
  # 60% of students pass all of their credits
  # 15% of students pass none of their credits
  # for the remaining students, the pass rate is ~ N(0.5, 0.2)
  total_students = length(credit_loads)
  credits_passed = case_when(runif(total_students, 0, 1) < 0.6 ~ credit_loads,
                             runif(total_students, 0, 1) < 0.15 ~ 0,
                             T ~ round(rnorm(total_students, 0.5, 0.2) * credit_loads))
  credits_passed = pmin(credits_passed, credit_loads)
  credits_passed = pmax(credits_passed, 0)
  return(credits_passed)
}

# Generate cumulative prior credits for students
generate_cumulative_credits = function(n_students) {
  min_cumulative_credits = 0
  max_cumulative_credits = 80
  cumulative_credits = round(rexp(n_students, 0.07))
  cumulative_credits = pmin(cumulative_credits, max_cumulative_credits)
  cumulative_credits = pmax(cumulative_credits, min_cumulative_credits)
  return(cumulative_credits)
}

# Generate a set of new students
generate_new_students = function(n_students, current_max_id) {
  new_students = generate_demographics(n_students) %>%
    mutate(SID = generate_ids(n_students, current_max_id),
           Credits = generate_credit_loads(n_students),
           Credits_passed = generate_credits_earned(Credits),
           Cumulative_credits = generate_cumulative_credits(n_students))
  return(new_students)
}

# Predict retention
predict_retention = function(student_data) {
  # linear model predicting likelihood of return.
  # model includes gender, cumulative credits, and noise
  B_Gender = 0.1
  B_Credits = 0.02
  C_constant = 0.9
  retention = (student_data$Gender * B_Gender) - 
    (student_data$Cumulative_credits * B_Credits)^2 + 
    (student_data$Cumulative_credits * B_Credits) +
    C_constant +
    rnorm(nrow(student_data),
          mean = 0,
          sd = 0.1)
  retention = invlogit(retention)
  return(retention)
}

# Initialize variables ----------------------------------------------------

set.seed(1000)

# number of semesters
periods = 100

# creating a data frame with semester binaries
semester_variables = cbind(
  GDP = generate_gdp(periods),
  model.matrix(~ 0 + Season,
               data.frame(Season = as.factor(rep_len(c("Spring", "Summer", "Fall"),
                                                     length.out = periods))))
) %>%
  data.frame()

#initial values for t = 0 individual student creation
initial_students = 900

# Aggregate prediction ----------------------------------------------------

# general linear model for enrollment which has linear relationship with GDP,
# semester fixed effects, and noise
semester_variables = semester_variables %>%
  mutate(new_student_count = generate_new_student_counts(semester_variables))

plot(semester_variables$GDP)

# Create new students at t = 0 --------------------------------------------

# create t = 0, initial data frame
enrolled_students = generate_new_students(n_students = initial_students,
                                          current_max_id = 0)

# Predict likelihood of returning -----------------------------------------

# linear model predicting likelihood of return.
enrolled_students = enrolled_students %>%
  mutate(likelihood_of_return = predict_retention(enrolled_students))

# generate realized 'return' values by sampling (0/1) using probability
# generated above
enrolled_students = enrolled_students %>%
  mutate(returned = as.numeric(runif(n(), 0, 1) < likelihood_of_return))

#put all new students into a data frame
enrolled = enrolled_students %>%
  mutate(semester = 1)

remove(enrolled_students)

# Generate t != 0 datasets ------------------------------------------------

# generating the list of students enrolled in semester = t
# this includes returning students from t - 1 and new students
for(i in 2:periods) {
  
  # here I'm generating new students in the same way that I generated the
  # original cohort of students at t = 0
  new = generate_new_students(n_students = semester_variables$new_student_count[i],
                              current_max_id = max(enrolled$SID))
  
  # sample credit distribution for returning students
  # add the credit load from t - 1 to get cumulative credits
  returning = enrolled %>%
    filter(semester == i - 1,
           returned == 1) %>%
    mutate(Cumulative_credits = Cumulative_credits + Credits_passed,
           Credits = generate_credit_loads(n()))
  
  # bind together all new students at t = 1 and 
  # returning students from t - 1
  enrolled_students = bind_rows(new, returning)
  
  # calculate retention in t + 1
  enrolled_students = enrolled_students %>%
    mutate(likelihood_of_return = predict_retention(enrolled_students),
           returned = as.numeric(runif(n(), 0, 1) < likelihood_of_return))
  
  #add semester index
  enrolled_students = enrolled_students %>%
    mutate(semester = i)
  
  enrolled = bind_rows(enrolled, enrolled_students)
  remove(new)
  remove(returning)
  remove(enrolled_students)
  
}


# Diagnosis and robustness checks -----------------------------------------

# enrollment seems steady over time so it looks like
# the coefficients and constants specified are ok.
# trying to keep it around a thousand
plot(aggregate(enrolled$likelihood_of_return,
               by = list(enrolled$semester),
               FUN = length))

# credit load per semester also seems robust over time
# There's some variation but nothing that's concerning
aggregate(enrolled$Credits,
          by = list(enrolled$semester),
          FUN = sum)

# our initial specification of the cumulative credit load
# seems too high. However, it looks like we hit an equilibrium
# really fast. It seems that the penalty coefficient of
# credits -> likelihood of return is doing its job. Even so,
# we'll probably want to be careful and throw out the first
# few observations when fitting models
aggregate(enrolled$Cumulative_credits,
          by = list(enrolled$semester),
          FUN = mean)


# Create aggregate output file --------------------------------------------

# Appending total headcount to semester dataframe created
# at the beginning
semester_variables$Total_enrollment <- aggregate(enrolled$SID,
                                                 by = list(enrolled$semester),
                                                 FUN = length)[,2]

# Appending total credits taken in given semester
semester_variables$Total_credits_taken <- aggregate(enrolled$Credits,
                                                    by = list(enrolled$semester),
                                                    FUN = sum)[,2]

# write out aggregate file
write.csv(semester_variables,
          file = 'data.csv')

# write out individual file
write.csv(enrolled,
          file = 'student_level.csv')
