# Model upload

Here you need to upload a prediction model generated with this programm in the "Train new Model" mode. 
This Model can also be read in with R by calling 
> model<- readRDS( *path to model file* )

Things you can do with this are e.g. analyzing lasso coefficients for a model:
> coef(codel$final_model) 

or analyzing the predictor set with 
> model$predictor_set

In detail this R object contains the following information: 

- which method was used
- the final model, either a glmnet or xgboost object depending on the method  
- scaling model, simple prediction model to scale and center new data
- predictor set, consisting of the whole sample/varaible matrix used for training the model
- statistical measures for all cross validation steps 
- which split was used for the cross validation 

