# training and fitting a gradient tree boosting
# model using xgboost and caret function expects
# dataframe x with one column named 'RT' which
# gets predicted function copied from
# Retip::fit.xgboost


fit.xgboost <- function(x) {
  cv.ctrl <- caret::trainControl(method = "cv", number = 10)
  xgb.grid <- base::expand.grid(nrounds = c(300, 400, 500, 600, 700, 800, 1000),
                                max_depth = c(2,3, 4, 5),
                                eta = c(0.01, 0.02),
                                gamma = c(1),
                                colsample_bytree = c(0.5),
                                subsample = c(0.5),
                                min_child_weight = c(10))
  print("Computing model Xgboost  ... Please wait ...")

  model_xgb <- caret::train(RT ~ ., data = x, method = "xgbTree",
                            metric = "RMSE", trControl = cv.ctrl, tuneGrid = xgb.grid)

  print("End training")
  return(model_xgb)
}
