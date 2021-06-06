library('forecast')

data <- read.csv('data.csv',
                 colClasses = c('NULL', rep(NA, 6)))


# Aggregate-only model ----------------------------------------------------

#fit models to 1:t-1 data and predict t
for(i in 5:nrow(data)) {
  #fit simple lm model with semester and GDP terms
  lm <- lm(Total_enrollment ~ GDP + Spring + Summer + Fall,
           data = data[1:(i - 1),])
  
  #linear t + 1 prediction
  data$lm_prediction[i] <- predict(lm,
                                   data[i,!names(data) %in% 'Total_enrollment'])
  
  #find optimal arima model to 1:t-1 data
  arima <- auto.arima(data$Total_enrollment[1:(i - 1)],
                      allowdrift = FALSE)
  
  #arima t + 1 prediction
  data$arima_prediction[i] <- predict(arima,
                                      n.ahead = 1)$pred[1]
  
  #get rid of temporary objects
  remove(lm)
  remove(arima)
}

#calculate residuals for each type of model
data$lm_residuals <- data$Total_enrollment - data$lm_prediction

data$arima_residuals <- data$Total_enrollment - data$arima_prediction

#calculate absolute percent error for each type of model
data$lm_ape <- abs(data$lm_residuals) / data$Total_enrollment

data$arima_ape <- abs(data$arima_residuals) / data$Total_enrollment

# Stacked model -----------------------------------------------------------

#read in student level data and keep only necessary columns
student_data <- read.csv('student_level.csv')

student_data <- student_data[, names(student_data) %in% c('returned', 'Gender', 'Cumulative_credits', 'semester')]

#read in # of new students and coerce to vector for easier
#time series modelling
new_student_count <- read.csv('new_student_count.csv',
                              colClasses = c('NULL', NA))

new_student_count <- as.vector(new_student_count$new_student_count)

#set number of iterations
semesters <- length(unique(student_data$semester))

#create data frame to hold predictions
stacked_model_predictions <- data.frame(matrix(nrow = semesters,
                                               ncol = 3))

colnames(stacked_model_predictions) <- c('Retained_prediction', 'New_prediction', 'Combined_prediction')

for(i in 4:(semesters - 1)) {
  #train dataset = all observations where semester <= i
  train <- student_data[which(student_data$semester <= i),]
  
  #fit model to training data
  individual_model <- glm(returned ~ Gender + Cumulative_credits,
                          data = train)
  
  #prediction = t + 1
  test <- student_data[which(student_data$semester == i + 1),]
  
  #predicted # of students returning is mean likelihood of return * number of students
  #in given semester
  stacked_model_predictions$Retained_prediction[i + 1] <- mean(predict(individual_model, test)) * nrow(test)
  
  #build arima model for new students only. As above, time through i
  arima <- auto.arima(new_student_count[1:i],
                      allowdrift = FALSE)
  
  #predict number of new students in t + 1
  stacked_model_predictions$New_prediction[i + 1] <- predict(arima,
                                                             n.ahead = 1)$pred[1]
  
  #remove temporary objects
  remove(train)
  remove(test)
  remove(individual_model)
  remove(arima)
}

#'stacked' model predicts # of predicted return + # of predicted new
stacked_model_predictions$Combined_prediction <- stacked_model_predictions$Retained_prediction + 
  stacked_model_predictions$New_prediction

#add variable to overall dataset
data$stacked_predictions <- stacked_model_predictions$Combined_prediction

#calculate residual
data$stacked_residuals <- data$Total_enrollment - data$stacked_predictions

#calculate absolute percent error
data$stacked_ape <- abs(data$stacked_residuals) / data$Total_enrollment


# Predictive accuracy diagnostics -----------------------------------------

#calculate mape for each type of model
mean(data$lm_ape, na.rm = TRUE)

mean(data$arima_ape, na.rm = TRUE)

mean(data$stacked_ape, na.rm = TRUE)
