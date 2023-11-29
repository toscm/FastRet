shiny.train <- function(raw_data, method) {
  raw_data <- data.frame(raw_data)
  raw_data <- validate.inputdata(raw_data)

  # Add Predictors to Data
  tmp_data <- preprocess.data(raw_data)
  method <- c("glmnet", "xgboost")[as.numeric(method)]

  # Train and evaluate Regression Model
  model <- fastret.workflow(tmp_data, method = method, preprocessed = TRUE)

  return(model)
}
