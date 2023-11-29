#' Retention time prediction  workflow
#'
#' Whole retention time prediction workflow. Function creates predictor set with RCDK based on SMILES.
#' Trains a chosen predcition model and validates the approach with a cross validation.
#'
#' @param data  data.frame with columns NAME, RT, SMILES
#' @param method prediction algorithm, either glmnet or xgboost
#' @param verbose additional print outputs to user if TRUE
#' @param data_set_name name of dataset will appear on validation plot
#' @param final_model TRUE if final model trained on whole dataset should be returned
#' @param preprocessed TRUE if data is already preprocessed and descriptor varialbes are already added
#' @param include_polynomial TRUE if polynomial terms should be added to descriptor set
#' @param degree_polynomial specifies degree up until which polynomials will be added if include_polynomials == TRUE
#' @param interaction_terms TRUE if interaction terms between all variables should be added
#' @param nfolds number of folds for cross validation
#' @param scale if TRUE, all variables will be centered to a mean of 0 and scaled to a standard deviation of 1
#' @keywords FastRet
#' @export
fastret.workflow <- function(data, method = "glmnet",
                             verbose = FALSE,
                             data_set_name = "data set",
                             final_model = TRUE,
                             preprocessed = FALSE,
                             interaction_terms = FALSE,
                             nfolds = 2,
                             include_polynomial = FALSE,
                             degree_polynomial = 2,
                             scale = TRUE) {
  reverse_split <- FALSE
  split_method <- "CV"
  # calculate Chemical descriptors, clear data
  # and add additional columns (polynomials and
  # interactions)
  db_rt <- preprocess.data(data,
    preprocessed = preprocessed,
    include_polynomial = include_polynomial,
    interaction_terms = interaction_terms,
    degree_polynomial = degree_polynomial
  )


  # Build a model to center and scale the data
  if (scale) {
    preProc <- caret::preProcess(db_rt[, -1], method = c(
      "center",
      "scale"
    ), rangeBounds = c(0, 1))
    db_rt <- stats::predict(preProc, db_rt)
  } else {
    preProc <- 0
  }
  db_rt$NAME <- NULL

  # outer cross validation split (either CV
  # with n-folds or Medoids-kmean with n medoids)

  split <- create.split(split_method, db_rt, n = nfolds)

  models <- list()
  stats <- list()
  i <- 1

  for (inSplit in split) {
    if (reverse_split) {
      training <- db_rt[inSplit, ]
      testing <- db_rt[-inSplit, ]
    } else {
      training <- db_rt[-inSplit, ]
      testing <- db_rt[inSplit, ]
    }

    # Train Model
    model <- switch(method,
      xgboost = fit.xgboost(training),
      glmnet = fit.glmnet(training),
      stop(paste("method \"", method, "\" is invalid "))
    )
    models[[i]] <- model

    # analyse performance of model
    title <- paste0(data_set_name, ", ", method)
    if (length(db_rt$RT) == nfolds) {
      stat <- stats::predict(object = model, newx = as.matrix(testing[
        ,
        -1
      ]))
    } else {
      stat <- get.stats(testing, model, name = paste0(
        title,
        " iteration ", i
      ))
    }

    stats[[i]] <- stat

    print(paste0("Iteration: ", i))

    i <- i + 1
  }

  return_object <- list()


  if (final_model) {
    # train model on whole data set
    model <- switch(method,
      xgboost = fit.xgboost(db_rt),
      glmnet = fit.glmnet(db_rt),
      stop(paste("method \"", method, "\" is invalid "))
    )
    pred <- data.frame(stats::predict(model, as.matrix(db_rt[, -1])))
    return_object$plot <- function() {
      p <- graphics::plot(x = db_rt$RT, y = t(pred), xlab = "RT", ylab = "predicted RT")
      p <- graphics::abline(a = 0, b = 1, col = "red")
    }
  }

  # create return object and return all
  # potential interesting variables
  return_object$final_model <- model
  return_object$method <- method
  return_object$data_set_name <- data_set_name
  return_object$model <- models
  return_object$stats <- stats
  return_object$predictor_set <- db_rt
  return_object$split <- split
  return_object$scaling_model <- preProc

  print("Workflow completed")
  return(return_object)
}
