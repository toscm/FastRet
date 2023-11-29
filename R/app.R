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
FastRet <- function(port = 80, host = "0.0.0.0") {
  app <- shinyApp(
    ui = app_ui,
    server = app_server,
    options = list(port = port, host = host)
  )
  return(app)
}


app_server <- function(input, output) {
  text_log <- shiny::reactiveVal("")

  shinyhelper::observe_helpers()

  calc_model <- shiny::reactiveVal()
  shiny::observeEvent(input$train, {
    if (isTruthy(input$inputdata$datapath)) {
      x <- shiny.train(
        raw_data = as.data.frame(readxl::read_excel(input$inputdata$datapath, sheet = 1)),
        method = input$method
      )
      calc_model(x)
    } else {
      showNotification("Please upload a excel sheet with the required data first", type = "error")
    }
  })
  output$scatterplot <- shiny::renderPrint({
    shiny::req(calc_model())
    print("Scatterplot with identity")
  })
  output$plot <- shiny::renderPlot({
    shiny::req(calc_model())
    calc_model()$plot()
  })
  output$boxplot <- shiny::renderPrint({
    shiny::req(calc_model())
    print("Boxplot with general Performance")
  })
  output$plot2 <- shiny::renderPlot({
    shiny::req(calc_model())
    plot.boxplot(calc_model())
  })

  # Selective Measuring 2.0
  cluster_calc <- shiny::reactive({
    shiny.sm(
      raw_data = as.data.frame(readxl::read_excel(input$inputdata$datapath, sheet = 1)),
      method = input$method, k_cluster = input$k
    )
  })

  shiny::observeEvent(input$sm2, {
    output$medoidtable <- shiny::renderPrint({
      print("Medoids:")
    })
    output$medoids <- shiny::renderTable({
      # v_train()
      cluster <- cluster_calc()
      cluster$medoids[, c("NAME", "SMILES")]
    })
  })

  output$save_predictors <- shiny::downloadHandler(
    filename = function() {
      paste("predictor_set_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      xlsx::write.xlsx(calc_model()$predictor_set, file, row.names = TRUE)
    }
  )

  output$save_model <- shiny::downloadHandler(
    filename = function() {
      paste("model-", Sys.Date(), sep = "")
    },
    content = function(file) {
      saveRDS(calc_model(), file)
    }
  )

  output$save_cluster <- shiny::downloadHandler(
    filename = paste("Cluster_k_", input$k, ".xlsx", sep = ""),
    content = function(file) {
      xlsx::write.xlsx(cluster_calc()$cluster[[1]], file, sheetName = paste("cluster", 1, sep = ""))

      for (i in 2:input$k) {
        xlsx::write.xlsx(cluster_calc()$cluster[[i]], file, sheetName = paste("cluster", i, sep = ""), append = TRUE)
      }
      xlsx::write.xlsx(cluster_calc()$medoids, file, sheetName = "medoids", append = TRUE)

      # write.xlsx(cluster_calc()$medoids, file, row.names = FALSE)
    }
  )


  # Create lm to adjust RT
  lm_adjust <- shiny::reactive({
    train.lm(
      original_data = base::readRDS(input$pretrained_model$datapath)$predictor_set,
      new_data = as.data.frame(
        readxl::read_excel(input$lm_data$datapath, sheet = 1)
      ),
      predictors = input$lm_predictors
    )
  })

  shiny::observeEvent(input$lm_analyze, {
    output$lmplot <- shiny::renderPlot({
      original_data <- readRDS(input$pretrained_model$datapath)$predictor_set
      new_data <- as.data.frame(
        readxl::read_excel(input$lm_data$datapath, sheet = 1)
      )
      lm_model <- lm_adjust()

      new_data$SMILES <- lapply(
        new_data$SMILES,
        function(x) rcdk::parse.smiles(as.character(unlist(x)))[[1]]
      )
      new_data$SMILES <- lapply(
        new_data$SMILES,
        function(x) rcdk::get.smiles(x, rcdk::smiles.flavors(c("CxSmiles")))
      )

      x <- original_data[which(rownames(original_data) %in% new_data$SMILES), ]
      x <- x[unlist(new_data$SMILES), ]
      y <- new_data$RT[which(new_data$SMILES %in% rownames(original_data))]

      plot(x[, "RT"], y)
      graphics::abline(a = 0, b = 1, col = "#c04a30")
      graphics::lines(sort(x[, "RT"]), stats::predict(lm_model, prepare.x(x[order(x[, "RT"]), "RT"], input$lm_predictors)), type = "l", col = "#2a92a9")
    })
  })

  # Predict single
  shiny::observeEvent(input$single_pred, {
    model <- base::readRDS(input$pretrained_model$datapath)

    x <- try(suppressWarnings(getCD(data.frame(
      SMILES = c(input$smiles, input$smiles),
      RT = c(0, 0)
    ))[1, ], classes = "warning"), silent = TRUE)

    if (inherits(x, "try-error")) {
      text_log(paste(text_log(), "Error with SMILES:", isolate(input$smiles), "\n"))
      text_log(paste(text_log(), "Please check if input is valid SMILES \n"))
    } else {
      x <- x[colnames(model$predictor_set)]
      x$RT <- NULL
      x <- as.matrix(x)
      x <- rbind(x, x)
      x <- stats::predict(model$scaling_model, x)

      if (model$method == "glmnet") {
        pred <- glmnet::predict.glmnet(model$final_model, newx = x)
        pred <- pred[1]
      } else {
        pred <- stats::predict(model$final_model, newx = x)
        pred <- pred[1]
      }

      text_log(paste(text_log(), "Prediction for the following Metabolite \n"))
      text_log(paste(text_log(), "SMILES:", isolate(input$smiles), "\n"))
      text_log(paste(text_log(), "Retention time: ", pred, "\n"))
    }
  })

  output$single_pred_out <- shiny::renderText({
    text_log()
  })

  # Predict Mult
  mult_pred_react <- shiny::reactive({
    mult.pred(
      model = base::readRDS(input$pretrained_model$datapath),
      pred_data = base::as.data.frame(
        readxl::read_excel(input$preddata$datapath, sheet = 1)
      ),
      lm_transfer = input$lm_transfer,
      lm_model = lm_adjust(),
      lm_predictors = input$lm_predictors
    )
  })

  shiny::observeEvent(input$mult_pred, {
    output$mult_pred_out <- renderTable({
      mult_pred_react()[, c("NAME", "SMILES", "pred_RT")]
    })
  })
  output$save_mult_pred <- shiny::downloadHandler(
    filename = "predictions.xlsx",
    content = function(file) {
      xlsx::write.xlsx(mult_pred_react(), file, sheetName = "predictions")
    }
  )
  return(NULL)
}

app_ui <- shiny::fluidPage(
  # title
  shiny::titlePanel("LCMS Retention Time prediciton"),

  # Sidebar layout with input and output definitions
  shiny::sidebarLayout(

    # Sidebar panel for inputs
    sidebarPanel(
      shinyhelper::helper(
        selectInput(
          "mode", "Mode",
          c(
            "Train new Model",
            "Selective Measuring",
            "Utilize Model to predict on new Data"
          )
        ),
        icon = "question-circle",
        colour = "#696969",
        type = "inline",
        content = "<h1 id=\"welcome-to-Fastret-\">Welcome to Ret!</h1>
<p>With this R shiny tool you can choose between three modes. </p>
<ul>
<li>Train new Model</li>
<li>Selective Measuring </li>
<li>Utilize Model on new data</li>
</ul>
<p>Each mode is shortly described here. For more information about the inputs see the (?) behind the corresponding input. </p>
<h2 id=\"train-new-model\">Train new Model</h2>
<p>This is usually the first step you take, this mode allows you to create and evaluate a Model on your own new data. Model can be trained with various parameters and afterwards the regression model as well as the predictor set can be downloaded. As an evaluation this step outputs you a scatterplot of your regression model as well as a boxplot with its general performance.</p>
<h2 id=\"selective-measuring\">Selective Measuring</h2>
<p>This mode calculates on a given dataset the best k molecules to be measured for a retention time prediction. It uses a combination of Ridge Regression and k-means to determine the best representatives of your dataset. Representatives as well as their corresponding clusters can be downloaded afterwards as an excel file. This step should be used once you have a predictive model ond/or data set and want to use it for new column/gradient/temperature... combination.</p>
<h2 id=\"utilize-model-on-new-data\">Utilize model on new data</h2>
<p>This step requires a pretrained model which can be uploaded. Afterwards you can use your model to predict retention times of new metabolites by providing either a single SMILE/HMDB ID combination or a whole list of molecules.</p>"
      ),
      # Selective Measuring and Train new Model
      shiny::conditionalPanel(
        condition = "input.mode == 'Selective Measuring' ||
                     input.mode == 'Train new Model'",
        shinyhelper::helper(
          fileInput("inputdata", h3("Data as .xlsx file"), accept = ".xlsx"),
          icon = "question-circle",
          colour = "#696969",
          type = "inline",
          content = "<h1 id=\"training-data-upload\">Training data upload</h1>
<p>Here you can upload your own data to the tool. In order for this to work you need to follow a strikt .xlsx format. If any columns are named incorrect the program won&#39;t work correctly. The programm wil always load in the first worksheet of the excel file. Therefore it is suggested that you reduce your file to one sheet beforehand to avoid any errors. </p>
<h2 id=\"required-columns\">Required columns</h2>
<p>The file must consist of the following columns (case sensitive) :</p>
<ul>
<li>&quot;RT&quot;: Retention time of your molecules. Can be any numeric input, minutes or seconds. Remember what you put in when you analyse the predictions, since those will be on the same scale as your input data.</li>
<li>&quot;NAME&quot;: you can put in any characters you like. Preferably the names of your molecules. (Names are used for identification in the Selective Measuring Mode)  </li>
<li>&quot;SMILES&quot;:  Isomeric or canonical SMILES, has to be present for chemical descriptors calculated with the chemistry development kit</li>
<li>&quot;HMDB&quot;: (only necessary for predictors gotten from the HMDB) HMDB ID, can have the following formats: HMDB0000001, 1, 001, HMDB00001 (it is suggested you use the official format of &quot;HMDB&quot; + 7 digits id) </li>
</ul>
<h2 id=\"more-columns\">More columns</h2>
<p>You can include your own predictors to be indluded in the regression analysis. To do that simply add columns to your input data and name them whatever you like. Keep in mind that you need to reproduce the same columns when trying to do predictions afterwards. Those columns should consist of pure numeric entries with preferably no categorical data. If you have nominal data you might get away with leaving it in but if you have ordinal data consider creating seperated columns for each individual category with either 0 or 1 depending on the affiliation of your molecules. If a column does not contain pure numerical values it is excluded beforehand. </p>
"
        ),
      ),
      # Train new Model
      shiny::conditionalPanel(
        condition = "input.mode == 'Train new Model'",
        shinyhelper::helper(
          radioButtons("method", h3("Method"),
            choices = list(
              "Lasso" = 1,
              "XGBoost" = 2
            ), selected = 1
          ),
          icon = "question-circle",
          colour = "#696969",
          type = "inline",
          content = "<h1 id=\"method-selection\">Method Selection</h1>
<p>Here you can choose by which method the regression model should be trained on. You can choose between Lasso or XGBoost. </p>
<h2 id=\"lasso\">Lasso</h2>
<p>Lasso (Least absolut shrinkage and selection operator) is based on the Least Minimum Square approach with the extension of a L1 penalty norm. This leads to a selection of variables as well as a generalization of the trained model.<br>Lasso was implemented with the R-package glmnet [2].</p>
<h2 id=\"xgboost\">XGBoost</h2>
<p>XGBoost is a more soffisticated Machine Learning method based on Boosted Regression Trees (BRT) [3]. The main difference to random forest is, that trees are not trained independant from each other but each tree is built with a loss function based on its predecessor. It was implemented with the R-package XGBoost [4].</p>
<h2 id=\"references\">References</h2>
<p>[1] Santosa, Fadil; Symes, William W. (1986). &quot;Linear inversion of band-limited reflection seismograms&quot;. <em>SIAM Journal on Scientific and Statistical Computing</em>. SIAM. <strong>7</strong> (4): 1307<e2><80><93>1330
[2] Jerome Friedman, Trevor Hastie, Robert Tibshirani (2010).
  Regularization Paths for Generalized Linear Models via
  Coordinate Descent. Journal of Statistical Software, 33(1),
  1-22.
[3] Jerome H. Friedman. &quot;Greedy function approximation: A gradient boosting machine..&quot; Ann. Statist. 29 (5) 1189 - 1232, October 2001
[4] Tianqi Chen et. Al, (2021). xgboost: Extreme Gradient Boosting. R package
  version 1.4.1.1.</p>
"
        ),
        shiny::actionButton("train", "Train Model and get evaluation"),
        shiny::downloadButton("save_model", "save Model"),
        shiny::downloadButton("save_predictors", "save predictor set as csv")
      ),
      # Selective Measuring
      shiny::conditionalPanel(
        condition = "input.mode == 'Selective Measuring'",
        shiny::numericInput("k",
          h3("k Cluster "),
          value = 25
        ),
        shiny::actionButton("sm2", "Calculate Cluster and Medodids"),
        shiny::downloadButton("save_cluster", "Save Cluster and Medoids as .xlsx")
      ),
      # Utilize Model to predict on new Data
      shiny::conditionalPanel(
        condition = "input.mode == 'Utilize Model to predict on new Data'",
        shinyhelper::helper(
          fileInput("pretrained_model", "Upload a pretrained Model"),
          icon = "question-circle",
          colour = "#696969",
          type = "inline",
          content = "<h1 id=\"model-upload\">Model upload</h1>
<p>Here you need to upload a prediction model generated with this programm in the &quot;Train new Model&quot; mode.
This Model can also be read in with R by calling </p>
<blockquote>
<p>model&lt;- readRDS( <em>path to model file</em> )</p>
</blockquote>
<p>Things you can do with this are e.g. analyzing lasso coefficients for a model:</p>
<blockquote>
<p>coef(codel$final_model) </p>
</blockquote>
<p>or analyzing the predictor set with </p>
<blockquote>
<p>model$predictor_set</p>
</blockquote>
<p>In detail this R object contains the following information: </p>
<ul>
<li>which method was used</li>
<li>the final model, either a glmnet or xgboost object depending on the method  </li>
<li>scaling model, simple prediction model to scale and center new data</li>
<li>predictor set, consisting of the whole sample/varaible matrix used for training the model</li>
<li>statistical measures for all cross validation steps </li>
<li>which split was used for the cross validation </li>
</ul>
"
        ),
        shinyhelper::helper(
          shiny::checkboxInput("lm_transfer", "Use measured metabolites to adjust Prediciton"),
          icon = "question-circle",
          colour = "#696969",
          type = "inline",
          content = "<h1 id=\"adjust-prediciton-model-with-a-linear-model\">Adjust prediciton model with a linear model</h1>
<p>This mode can be used to adjust an existing model to a new experiment design.
It requires a subset of the molecules that are in the original data set to be measured again with the new experiment.
Afterwards the programm creates a linear model between the two experiments to adjust the predictions of the original model.
The coefficients of the model can be selected or unselected depending on the needs. An Intercept as well as the linear term are always included. </p>
<p>To analyze the linear model click on &quot;Analyze Linear Model&quot; once. (if the checkbox is set a linear model will be trained and utilized on the predictions independant from this step)</p>
<p>The program maps the molecules through Isomeric SMILES so the new SMILES should be the same SMILES as they were in the original data set, otherwise a connection between two metabolites can not be drawn. </p>
"
        ),
        shiny::conditionalPanel(
          condition = "input.lm_transfer == true",
          shiny::fileInput("lm_data", h3("Transfer data to train lm as .xlsx file"), accept = ".xlsx"),
          shiny::checkboxGroupInput("lm_predictors", h3("Choose components of lm"),
            choices = list(
              "x^2" = 1,
              "x^3" = 2,
              "log(x)" = 3,
              "exp(x)" = 4,
              "sqrt(x)" = 5
            )
          ),
          shiny::actionButton("lm_analyze", "Analyze Linear Model")
        ),
        shiny::textInput("smiles", "Input SMILES", value = ""),
        shiny::actionButton("single_pred", "Calculate single input"),
        shinyhelper::helper(
          fileInput("preddata", h3("New data to predict as .xlsx file"), accept = ".xlsx"),
          icon = "question-circle",
          colour = "#696969",
          type = "inline",
          content = "<h1 id=\"prediction-data-upload\">Prediction Data Upload</h1>
<p>This file input has to be an excel file with the following columns: </p>
<ul>
<li>NAME</li>
<li>SMILES (if model used uses CDK descriptors) </li>
<li>HMDB (if model used uses HMDB descriptors)</li>
</ul>
"
        ),
        shiny::actionButton("mult_pred", "Calculate predictions for input file"),
        shiny::downloadButton("save_mult_pred", "Save predictions for input file")
      )
    ),

    # Main panel for displaying outputs
    mainPanel(

      # Output:
      shinybusy::add_busy_spinner(spin = "fading-circle"),
      shiny::verbatimTextOutput("single_pred_out"),
      shiny::tableOutput("mult_pred_out"),
      shiny::verbatimTextOutput("value"),
      shiny::verbatimTextOutput("medoidtable"),
      shiny::tableOutput("medoids"),
      shiny::verbatimTextOutput("scatterplot"),
      shiny::plotOutput("plot"),
      shiny::verbatimTextOutput("boxplot"),
      shiny::plotOutput("plot2"),
      shiny::plotOutput("lmplot")
    )
  )
)
