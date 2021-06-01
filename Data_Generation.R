library('truncnorm')

# Initialize variables ----------------------------------------------------

set.seed(100)

#values for GDP. Random walk process
periods <- 20
GDP <- rnorm(1, mean = 0, sd = 1)

for(i in 2:periods) {
  GDP[i] <- GDP[i - 1] + rnorm(1, mean = 0, sd = 1)
}

#initial values for new student aggregate model
B_GDP <- 2
mean_new_students <- 100
sd_new_students <- 20

#initial values for t = 0 individual student creation
proportion_female <- 0.5
initial_students <- 900

#parameters for assigning credit load
mean_credits <- 9
sd_credits <- 6

#values for 'return' variable calculation
B_Gender <- 0.5
B_Credits <- 0.02

# Aggregate prediction ----------------------------------------------------

#general linear model for enrollment which has linear relationship with GDP + noise
new_student_count <- GDP * B_GDP + rnorm(length(GDP),
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
                                         #sample credit load from a uniform  distribution
                                         #truncated at lower bound = 1 and upper at 80 to capture the
                                         #range of all reasonable credit loads
                                         round(runif(n = initial_students,
                                                     min = 1,
                                                     max = 80))),
                                       nrow = 900,
                                       ncol = 3,
                                       byrow = FALSE))

colnames(enrolled_students) <- c('SID', 'Gender', 'Credits')

#variables save as character; fixing them here
enrolled_students$Credits <- as.numeric(enrolled_students$Credits)

enrolled_students$Gender <- as.numeric(enrolled_students$Gender)

# Predict likelihood of returning -----------------------------------------

#linear model predicting likelihood of return.
#model includes gender, cumulative credits, and noise
temp <- enrolled_students$Gender * B_Gender + 
  enrolled_students$Credits * B_Credits + 
  rnorm(nrow(enrolled_students),
        mean = 0,
        sd = 0.1)

#likelihood to probability
enrolled_students$likelihood_of_return <- 1 / (1 + exp(1)^-(temp))

#generate realized 'return' values by sampling (0/1) using probability
#generated above
for(i in 1:nrow(enrolled_students)) {
  enrolled_students$returned[i] <- enrolled_students$returned[i] <- sample(0:1,
                                                                           size = 1,
                                                                           replace = TRUE,
                                                                           #I know this says 'likelihood of return', but since I
                                                                           #did 0/1, it's reversed for the sake of probability
                                                                           prob = c(1 - enrolled_students$likelihood_of_return[i], 
                                                                                    enrolled_students$likelihood_of_return[i]))
}

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
                                               sd = sd_credits))),
                            nrow = new_student_count[i],
                            ncol = 3,
                            byrow = FALSE))
  
  colnames(temp) <- c('SID', 'Gender', 'Credits')
  
  temp$Credits <- as.numeric(temp$Credits)
  
  temp$Gender <- as.numeric(temp$Gender)
  
  #for new students, generate likelihood of returning at t+1
  temp$likelihood_of_return <- temp$Gender * B_Gender + temp$Credits * B_Credits + rnorm(nrow(temp),
                                                                                         mean = 0,
                                                                                         sd = 0.1)
  
  #coerce to probability using logistic function
  temp$likelihood_of_return <- 1 / (1 + exp(1)^-(temp$likelihood_of_return))
  
  #generate realized value for 'returned' variable using probability
  #generated above. This is for each NEW student
  for(j in 1:nrow(temp)) {
    temp$returned[j] <- sample(0:1,
                               size = 1,
                               replace = TRUE,
                               #I know this says 'likelihood of return', but since I
                               #did 0/1, it's reversed for the sake of probability
                               prob = c(1 - temp$likelihood_of_return[j], 
                                        temp$likelihood_of_return[j]))
  }
  
  #bind together all new students at t = 1 and 
  # returning students from t - 1
  enrolled[[i]] <- rbind(temp, enrolled[[i - 1]][which(enrolled[[i - 1]]$returned == 1),])
  
  #add the credit load from t to get cumulative credits
  enrolled[[i]]$Credits <- enrolled[[i]]$Credits + round(rtruncnorm(n = nrow(enrolled[[i]]),
                                                                    a = 1,
                                                                    b = 21,
                                                                    mean = mean_credits,
                                                                    sd = sd_credits))
  
  remove(temp)
}

