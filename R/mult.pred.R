mult.pred<- function(model,pred_data, lm_transfer, lm_model, lm_predictors){


  pred_data$RT<- rep(0,nrow(pred_data))
  validate(need("NAME" %in% colnames(pred_data),
                "No NAME found in new data"))

  if ("nAtom" %in% colnames(model$predictor_set)){
    validate(need("SMILES" %in% colnames(pred_data),
                  "No SMILES found in new data"))

    x<- getCD(pred_data)

    validate(need(all(colnames(model$predictor_set)%in%colnames(x)),
                  "Not all Predictor variables available"))
    pred_data$SMILES<-lapply(pred_data$SMILES,function(x) rcdk::parse.smiles(as.character(unlist(x)))[[1]])

    pred_data$SMILES <- lapply(pred_data$SMILES,function(x) rcdk::get.smiles(x, rcdk::smiles.flavors(c("CxSmiles"))))

    pred_data<- pred_data[which(pred_data$SMILES %in% rownames(x)),]

  }


  x<- x[,colnames(model$predictor_set)]
  x$RT<- NULL

  x<- stats::predict(model$scaling_model,x)
  if(model$method== "glmnet"){
    x<- data.matrix(x)
  }
  pred<- statspredict(model$final_model,newx=x)
  pred_data$pred_RT<- pred

  if (lm_transfer){
    #adjust predictions with lm
    pred_data$pred_RT<- stats::predict(lm_model,
                                prepare.x(pred
                                          ,lm_predictors))

  }
  pred_data$RT<- NULL

  return(pred_data)
}
