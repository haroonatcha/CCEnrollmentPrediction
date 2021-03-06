library('forecast')
library('scales')
library(tidyverse)

data <- read.csv('data.csv',
                 colClasses = c('NULL', rep(NA, 6)))

for(i in 1:nrow(data)) {
  data$lag[i] <- data$Total_enrollment[i - 1]
}

# Aggregate-only model ----------------------------------------------------

#fit models to 1:t-1 data and predict t
for(i in 5:nrow(data)) {
  #fit simple lm model with semester and GDP terms
  lm <- lm(Total_enrollment ~ GDP + Spring + Summer + Fall,
           data = data[1:(i - 1),])
  
  #linear t + 1 prediction
  data$lm_prediction[i] <- predict(lm,
                                   data[i,!names(data) %in% 'Total_enrollment'])
  
  #fit lagged linear model
  lm_lagged <- lm(Total_enrollment ~ GDP + lag +Spring + Summer + Fall,
                  data = data[1:(i - 1),])
  
  #linear with lat t + 1 prediction
  data$lm_lagged_prediction[i] <- predict(lm_lagged,
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

data$lm_lagged_residuals <- data$Total_enrollment - data$lm_lagged_prediction

data$arima_residuals <- data$Total_enrollment - data$arima_prediction

#calculate absolute percent error for each type of model
data$lm_ape <- abs(data$lm_residuals) / data$Total_enrollment

data$lm_lagged_ape <- abs(data$lm_lagged_residuals) / data$Total_enrollment

data$arima_ape <- abs(data$arima_residuals) / data$Total_enrollment

# Stacked model -----------------------------------------------------------

#read in student level data and keep only necessary columns
student_data <- read.csv('student_level.csv')

student_data <- student_data[, names(student_data) %in% c('returned', 'Gender', 'Cumulative_credits', 'semester')]

#read in # of new students and coerce to vector for easier
#time series modelling
new_student_count <- semester_variables %>%
  dplyr::select(new_student_count, GDP)

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
  
  #fit stacked model 1 (no polynomial term) to training data
  individual_model <- glm(returned ~ Gender + Cumulative_credits,
                          data = train,
                          family = 'binomial')
  
  #fit stacked model 2 (polynomial term)
  individual_model_1 <- glm(returned ~ Gender + poly(Cumulative_credits, 2) + Cumulative_credits,
                            data = train,
                            family = 'binomial')
  
  #prediction = t + 1
  test <- student_data[which(student_data$semester == i + 1),]
  
  #predicted # of students returning is mean likelihood of return * number of students
  #in given semester
  stacked_model_predictions$Retained_prediction[i + 1] <- mean(predict(individual_model, 
                                                                       test, type = 'response')) * nrow(test)
  
  #predict as above but with higher order model
  stacked_model_predictions$Retained_prediction_1[i + 1] <- mean(predict(individual_model_1,
                                                                         test, type = 'response')) * nrow(test)
  
  
  #build linear model
  #lm <- lm(new_student_count[1:i] ~ GDP + Spring + Summer,
  #         data = data[1:i,])
  
  #predict linear model
  #stacked_model_predictions$New_prediction[i + 1] <- predict(lm,
  #                                                           data[i + 1,])
  
  #build arima model for new students only. As above, time through i
  arima <- auto.arima(new_student_count[1:i],
                      allowdrift = FALSE,
                      seasonal = TRUE)
  
  #predict number of new students in t + 1
  stacked_model_predictions$New_prediction[i + 1] <- predict(arima,
                                                             n.ahead = 1)$pred[1]
  
  #remove temporary objects
  remove(train)
  remove(test)
  remove(individual_model)
  remove(individual_model_1)
  remove(arima)
}

#'stacked' model predicts # of predicted return + # of predicted new
stacked_model_predictions$Combined_prediction <- stacked_model_predictions$Retained_prediction + 
  stacked_model_predictions$New_prediction

stacked_model_predictions$Combined_prediction_1 <- stacked_model_predictions$Retained_prediction_1 +
  stacked_model_predictions$New_prediction

#add variable to overall dataset
data$stacked_predictions <- stacked_model_predictions$Combined_prediction

data$stacked_predictions_1 <- stacked_model_predictions$Combined_prediction_1

#calculate residual
data$stacked_residuals <- data$Total_enrollment - data$stacked_predictions

data$stacked_residuals_1 <- data$Total_enrollment - data$stacked_predictions_1

#calculate absolute percent error
data$stacked_ape <- abs(data$stacked_residuals) / data$Total_enrollment

data$stacked_ape_1 <- abs(data$stacked_residuals_1) / data$Total_enrollment

# Predictive accuracy diagnostics -----------------------------------------

#create diagnostics and create DF
diagnostics <- data.frame(cbind(c('Linear Model', 'Linear w/ lag', 'ARIMA', 'Stacked Model', 'Stacked Model w/ Polynomial'),
                                #MAE
                                c(mean(abs(data$lm_residuals), na.rm = TRUE),
                                  mean(abs(data$lm_lagged_residuals), na.rm = TRUE),
                                  mean(abs(data$arima_residuals), na.rm = TRUE),
                                  mean(abs(data$stacked_residuals), na.rm = TRUE),
                                  mean(abs(data$stacked_residuals_1), na.rm = TRUE)),
                                #MAPE
                                c(mean(data$lm_ape, na.rm = TRUE),
                                  mean(data$lm_lagged_ape, na.rm = TRUE),
                                  mean(data$arima_ape, na.rm = TRUE),
                                  mean(data$stacked_ape, na.rm = TRUE),
                                  mean(data$stacked_ape_1, na.rm = TRUE)),
                                #RMSE
                                c(sqrt(mean(data$lm_residuals^2, na.rm = TRUE)),
                                  sqrt(mean(data$lm_lagged_residuals^2, na.rm = TRUE)),
                                  sqrt(mean(data$arima_residuals^2, na.rm = TRUE)),
                                  sqrt(mean(data$stacked_residuals^2, na.rm = TRUE)),
                                  sqrt(mean(data$stacked_residuals_1^2, na.rm = TRUE)))))

#rename columns and coerce to numeric
colnames(diagnostics) <- c('Model', 'MAE', 'MAPE', 'RMSE')

for(i in 2:4) {
  diagnostics[,i] <- as.numeric(diagnostics[,i])
}

#round MAE and RMSE, coerce MAPE to %
diagnostics[,2] <- round(diagnostics[,2], 2)
diagnostics[,3] <- percent(diagnostics[,3], 0.01)
diagnostics[,4] <- round(diagnostics[,4], 2)

diagnostics

#write out table for paper
write.csv(diagnostics,
          file = 'diagnostics.csv') 


#write out predictions to plot for paper
write.csv(data,
          file = 'predictions.csv')

stacked_model_predictions
summary(lm)
