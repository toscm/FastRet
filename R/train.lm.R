train.lm <- function(original_data, new_data, predictors){

  new_data$SMILES<-lapply(new_data$SMILES,
                          function(x) rcdk::parse.smiles(as.character(unlist(x)))[[1]])
  new_data$SMILES <- lapply(new_data$SMILES,
                            function(x) rcdk::get.smiles(x, rcdk::smiles.flavors(c("CxSmiles"))))
  x<- original_data[which(rownames(original_data) %in% new_data$SMILES),]
  x<- x[unlist(new_data$SMILES),]
  x<- prepare.x(x$RT, predictors)
  model<- stats::lm(y~.,data= data.frame(y= new_data$RT,
                                  x))
  return(model)
}


prepare.x<-function(x, predictors){
  x<- data.frame(x = x)
  colnames(x)<-c("x")
  if ("1" %in% predictors){
    x$sqare<- x$x^2
  }
  if ("2" %in% predictors){
    x$cubic<- x$x^3
  }
  if ("3" %in% predictors){
    x$log<- log(x$x)
  }
  if ("4" %in% predictors){
    x$exp<- exp(x$x)
  }
  if ("5" %in% predictors){
    x$sqrt<- sqrt(x$x)
  }
  return(x)

}
