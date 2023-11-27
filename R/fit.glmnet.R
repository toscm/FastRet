#training and fitting a lasso model using the function glmnet::cv.glmnet
#function expects dataframe x with one column named "RT" which gets predicted

fit.glmnet<- function(x,alpha=1){


  print("Computing model glmnet  ... Please wait ...")
  cv_glmnet<- glmnet::cv.glmnet(x= data.matrix(x[,-which(colnames(x) =="RT")]),
                                   y = x[,which(colnames(x) =="RT")],
                                   alpha=alpha,
                                   type.measure = "mse", nfolds = 10,
                                  nlambda =200,
                                standardize = FALSE,

                                   family = "gaussian")

  plot(cv_glmnet)
  model_glmnet<-glmnet::glmnet(x= data.matrix(x[,-which(colnames(x) =="RT")]),
                       y = x[,which(colnames(x) =="RT")],
                       family = "gaussian",
                       alpha=alpha,
                       standardize = FALSE,
                       lambda = cv_glmnet$lambda.min)


  print("End training")
  return(model_glmnet)

}
