#' @title FastRet Retention time prediction
#' @description This shiny function will show you a GUI where you can choose
#' between three modes:
#'
#' - Train new Model
#' - Selective Measuring
#' - Utilize Model on new data
#'
#' Each mode is briefly described below. For more information about the inputs,
#' see the (?) behind the corresponding input.
#'
#' ## Train new Model
#'
#' This mode allows you to create and evaluate a model on your own new data. The
#' model can be trained with various parameters and the regression model and
#' predictor set can be downloaded afterwards. This step outputs a scatterplot
#' of your regression model and a boxplot showing its general performance.
#'
#' ## Selective Measuring
#'
#' This mode calculates the best k molecules to be measured for a retention time
#' prediction on a given dataset. It uses a combination of Ridge Regression and
#' k-means to determine the best representatives of your dataset. The
#' representatives and their corresponding clusters can be downloaded afterwards
#' as an excel file. This step should be used once you have a predictive model
#' and/or dataset and want to use it for a new column/gradient/temperature...
#' combination.
#'
#' ## Utilize model on new data
#'
#' This step requires a pretrained model which can be uploaded. You can then use
#' your model to predict retention times of new metabolites by providing either
#' a single SMILE/HMDB ID combination or a list of molecules.
#'
#' @param port The port the application should listen on
#' @param host The address the application should listen on
#' @return A shiny app. This function returns a shiny app that can be run to interact with the model.
#' @keywords FastRet
#' @export
FastRet <- function(port = 8080, host = "0.0.0.0") {
  app <- shinyApp(
    ui = app_ui(),
    server = app_server,
    options = list(port = port, host = host)
  )
  return(app)
}
