library('truncnorm')
library('rlist')

# Initialize variables ----------------------------------------------------

set.seed(100)

#values for GDP. Random walk process
periods <- 100
GDP <- rnorm(1, mean = 0, sd = 1)

for(i in 2:periods) {
  GDP[i] <- GDP[i - 1] + rnorm(1, mean = 0, sd = 1)
}

#creating a data frame with semester binaries
semester_variables <- data.frame(cbind(GDP,
                                       rep_len(c(1, 0, 0),
                                               length.out = periods),
                                       rep_len(c(0, 1, 0),
                                               length.out = periods),
                                       rep_len(c(0, 0, 1),
                                               length.out = periods)))

colnames(semester_variables) <- c('GDP', 'Spring', 'Summer', 'Fall')


#initial values for new student aggregate model
B_GDP <- 2
mean_new_students <- 150
sd_new_students <- 25
B_spring <- 3
B_summer <- 0
B_fall <- 6

#initial values for t = 0 individual student creation
proportion_female <- 0.5
initial_students <- 900

#parameters for assigning credit load
mean_credits <- 9
sd_credits <- 6

#values for 'return' variable calculation
B_Gender <- 0.1
B_Credits <- 0.02
C_constant <- 0.9

# Aggregate prediction ----------------------------------------------------

#general linear model for enrollment which has linear relationship with GDP,
# semester fixed effects, and noise
new_student_count <- semester_variables$GDP * B_GDP +
  semester_variables$Spring * B_spring + 
  semester_variables$Summer * B_summer +
  semester_variables$Fall * B_fall + 
  rnorm(nrow(semester_variables),
        mean = 0,
        sd = 1)

#un-standardizing the calculation so we can get sensible numbers
new_student_count <- round(new_student_count * sd_new_students + mean_new_students)


# Create new students at t = 0 --------------------------------------------

#create t = 0, initial data frame
enrolled_students <- data.frame(matrix(c(1:initial_students,
                                         #randomly assign gender
                                         sample(c(0, 1),
                                                size = initial_students,
                                                replace = TRUE,
                                                #probability of gender can be changed if needed
                                                prob = c(proportion_female, 1 - proportion_female)),
                                         #sample credits taken in the GIVEN SEMESTER. This part 
                                         #tells us how many credits the student took NOW. The
                                         #next part tells us cumulative credits
                                         round(rtruncnorm(n = initial_students,
                                                          a = 1,
                                                          b = 21,
                                                          mean = mean_credits,
                                                          sd = sd_credits)),
                                         #sample credit load from a uniform  distribution
                                         #truncated at lower bound = 1 and upper at 80 to capture the
                                         #range of all reasonable credit loads.
                                         round(runif(n = initial_students,
                                                     min = 1,
                                                     max = 80))),
                                       nrow = 900,
                                       ncol = 4,
                                       byrow = FALSE))

colnames(enrolled_students) <- c('SID', 'Gender', 'Credits', 'Cumulative_credits')

#variables save as character; fixing them here
enrolled_students$Gender <- as.numeric(enrolled_students$Gender)

enrolled_students$Credits <- as.numeric(enrolled_students$Credits)

# Predict likelihood of returning -----------------------------------------

#linear model predicting likelihood of return.
#model includes gender, cumulative credits, and noise
temp <- enrolled_students$Gender * B_Gender - 
  (enrolled_students$Cumulative_credits * B_Credits)^2 + 
  enrolled_students$Cumulative_credits * B_Credits +
  C_constant +
  rnorm(nrow(enrolled_students),
        mean = 0,
        sd = 0.1)

#likelihood to probability
enrolled_students$likelihood_of_return <- 1 / (1 + exp(1)^-(temp))

#generate realized 'return' values by sampling (0/1) using probability
#generated above
for(i in 1:nrow(enrolled_students)) {
  enrolled_students$returned[i] <- sample(0:1,
                                          size = 1,
                                          replace = TRUE,
                                          #I know this says 'likelihood of return', but since I
                                          #did 0/1, it's reversed for the sake of probability
                                          prob = c(1 - enrolled_students$likelihood_of_return[i], 
                                                   enrolled_students$likelihood_of_return[i]))
}

enrolled_students$semester <- 1

enrolled <- list()

#put all new students into a list as t = 0
enrolled[[1]] <- enrolled_students

remove(enrolled_students)

# Generate t != 0 datasets ------------------------------------------------

#generating the list of students enrolled in semester = t
#this includes returning students from t - 1 and new students
for(i in 2:periods) {
  
  #here I'm generating new students in the same way that I generated the
  #original cohort of students at t = 0
  temp <- data.frame(matrix(c((max(enrolled[[i - 1]]) + 1):(max(enrolled[[i - 1]]) + new_student_count[i]),
                              #randomly assign gender
                              sample(c(0, 1),
                                     size = new_student_count[i],
                                     replace = TRUE,
                                     #probability of gender can be changed if needed
                                     prob = c(proportion_female, 1 - proportion_female)),
                              #sample credit load from a truncated normal distribution
                              #truncated at lower bound = 1 and upper at 21 to capture the
                              #range of all reasonable cumulative credits. Since these are NEW
                              #students, their upper bound is limited to 21 instead of 80.
                              round(rtruncnorm(n = new_student_count[i],
                                               a = 1,
                                               b = 21,
                                               mean = mean_credits,
                                               sd = sd_credits)),
                              #since they're new students, their cumulative credits are 0
                              rep(0, new_student_count[i])),
                            nrow = new_student_count[i],
                            ncol = 4,
                            byrow = FALSE))
  
  colnames(temp) <- c('SID', 'Gender', 'Credits', 'Cumulative_credits')
  
  temp$Gender <- as.numeric(temp$Gender)
  
  temp$Credits <- as.numeric(temp$Credits)
  
  temp$Cumulative_credits <- as.numeric(temp$Cumulative_credits)
  
  #initiate likelihood of return variable for new students
  temp$likelihood_of_return <- NA

  #add semester index
  temp$semester <- NA
  
  temp$returned <- NA
  
  #sample credit distribution for returning students
  temp2 <- enrolled[[i - 1]][which(enrolled[[i - 1]]$returned == 1),]
  
  temp2$Credits <- round(rtruncnorm(n = nrow(temp2),
                                    a = 1,
                                    b = 21,
                                    mean = mean_credits,
                                    sd = sd_credits))
  
  #bind together all new students at t = 1 and 
  # returning students from t - 1
  enrolled[[i]] <- rbind(temp, temp2)
  
  #add the credit load from t - 1 to get cumulative credits
  enrolled[[i]]$Cumulative_credits <- enrolled[[i]]$Credits + enrolled[[i]]$Cumulative_credits
  
  #calculate likelihood of return in t + 1
  enrolled[[i]]$likelihood_of_return <- enrolled[[i]]$Gender * B_Gender - 
    (enrolled[[i]]$Cumulative_credits * B_Credits)^2 + 
    enrolled[[i]]$Cumulative_credits * B_Credits +
    C_constant +
    rnorm(nrow(enrolled[[i]]),
               mean = 0,
               sd = 0.1)
  
  #coerc to probability
  enrolled[[i]]$likelihood_of_return <- enrolled[[i]]$likelihood_of_return <- 1 / 
    (1 + exp(1)^-(enrolled[[i]]$likelihood_of_return))
  
  for(j in 1:nrow(enrolled[[i]])){
    enrolled[[i]]$returned[j] <- sample(0:1,
                                        size = 1,
                                        replace = TRUE,
                                        prob = c(1 - enrolled[[i]]$likelihood_of_return[j],
                                                 enrolled[[i]]$likelihood_of_return[j]))
    
  }
  
  #add semester index
  enrolled[[i]]$semester <- i
  
  remove(temp)
  
  remove(temp2)
}


# Diagnosis and robustness checks -----------------------------------------

#bring everything into a single dataframe
temp <- list.rbind(enrolled)

#enrollment seems steady over time so it looks like
#the coefficients and constants specified are ok.
#trying to keep it around a thousand
plot(aggregate(temp$likelihood_of_return,
               by = list(temp$semester),
               FUN = length))

#credit load per semester also seems robust over time
#There's some variation but nothing that's concerning
aggregate(temp$Credits,
          by = list(temp$semester),
          FUN = sum)

#our initial specification of the cumulative credit load
#seems too high. However, it looks like we hit an equilibrium
#really fast. It seems that the penalty coefficient of
#credits -> likelihood of return is doing its job. Even so,
#we'll probably want to be careful and throw out the first
#few observations when fitting models
aggregate(temp$Cumulative_credits,
          by = list(temp$semester),
          FUN = mean)


# Create aggregate output file --------------------------------------------

#Appending total headcount to semester dataframe created
#at the beginning
semester_variables$Total_enrollment <- aggregate(temp$SID,
                                                 by = list(temp$semester),
                                                 FUN = length)[,2]

#Appending total credits taken in given semester
semester_variables$Total_credits_taken <- aggregate(temp$Credits,
                                                    by = list(temp$semester),
                                                    FUN = sum)[,2]

#write out aggregate file
write.csv(semester_variables,
          file = 'data.csv')

#write out individual file
write.csv(temp,
          file = 'student_level.csv')




#write out new student count file
write.csv(data.frame(cbind(new_student_count,
                           GDP)),
          file = 'new_student_count.csv')
