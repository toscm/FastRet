# Function to get RMSE, Rsquared, MAE and %below1min for a specific dataset and model 
# expects data with retention time in the first column 
# and a prediction model which is ready to predict on 

get.stats<- function(data,model,name="model"){

  prd <- stats::predict(model, as.matrix(data)[, -1])
  prd <- data.frame(prd)
  names(prd) <- c("RTP")
  x <- data$RT
  y <- prd$RTP
  measures <- data.frame(round((caret::postResample(x, y)), 2))
  colnames(measures) <- name
  measures <- as.data.frame(t(measures))
  measures$"%below1min" <- get.below.threshhold(data,model,threshhold = 1.)
    
  print(measures)
  return(measures)
  
}

# like get.stats but uses an additional linear model on the  
# predictions afterwards 
# this model has to be given to the function as well  
get.stats.LMadjusted<- function(data,model,lm_fit,name="model"){
  
  prd <- stats::predict(model, as.matrix(data)[, -1])
  prd <- as.data.frame(prd)
  names(prd)<- c("RT")
  
  #use linear model to adjust predictions
  prd$RT <- stats::predict.lm(lm_fit,newdata=prd)
  prd <- as.data.frame(prd)
  
  names(prd) <- c("RTP")
  x <- data$RT
  y <- prd$RTP
  measures <- data.frame(round((caret::postResample(x, y)), 2))
  colnames(measures) <- name
  measures <- as.data.frame(t(measures))
  measures$"%below1min" <- get.below.threshhold(data,model,threshhold = 1.)

  print(measures)
  return(measures)
}


#calculate predictions and get percentage that is below specific threshhold 
get.below.threshhold<- function(data, model,threshhold=1.00){
  
  data <- as.matrix(data)
  preds <- stats::predict(model, data[, 2:ncol(data)])
  residues <- data[,1]-preds
  percentage <- sum(abs(residues)<threshhold) / length(residues)
  
  return(percentage)
}