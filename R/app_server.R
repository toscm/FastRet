app_server <- function(input, output) {
  text_log <- reactiveVal("")

  shinyhelper::observe_helpers()

  calc_model <- reactiveVal()
  observeEvent(input$train, {
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

  output$scatterplot <- renderPrint({
    req(calc_model())
    print("Scatterplot with identity")
  })
  output$plot <- renderPlot({
    req(calc_model())
    calc_model()$plot()
  })
  output$boxplot <- renderPrint({
    req(calc_model())
    print("Boxplot with general Performance")
  })
  output$plot2 <- renderPlot({
    req(calc_model())
    plot.boxplot(calc_model())
  })

  # Selective Measuring 2.0
  cluster_calc <- reactive({
    shiny.sm(
      raw_data = as.data.frame(readxl::read_excel(input$inputdata$datapath, sheet = 1)),
      method = input$method, k_cluster = input$k
    )
  })

  observeEvent(input$sm2, {
    output$medoidtable <- renderPrint({
      print("Medoids:")
    })
    output$medoids <- renderTable({
      cluster <- cluster_calc()
      cluster$medoids[, c("NAME", "SMILES")]
    })
  })

  output$save_predictors <- downloadHandler(
    filename = function() {
      paste("predictor_set_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      xlsx::write.xlsx(calc_model()$predictor_set, file, row.names = TRUE)
    }
  )

  output$save_model <- downloadHandler(
    filename = function() {
      paste("model-", Sys.Date(), sep = "")
    },
    content = function(file) {
      saveRDS(calc_model(), file)
    }
  )

  output$save_cluster <- downloadHandler(
    filename = paste("Cluster_k_", input$k, ".xlsx", sep = ""),
    content = function(file) {
      xlsx::write.xlsx(cluster_calc()$cluster[[1]], file, sheetName = paste("cluster", 1, sep = ""))
      for (i in 2:input$k) {
        xlsx::write.xlsx(cluster_calc()$cluster[[i]], file, sheetName = paste("cluster", i, sep = ""), append = TRUE)
      }
      xlsx::write.xlsx(cluster_calc()$medoids, file, sheetName = "medoids", append = TRUE)
    }
  )

  # Create lm to adjust RT
  lm_adjust <- reactive({
    train.lm(
      original_data = base::readRDS(input$pretrained_model$datapath)$predictor_set,
      new_data = as.data.frame(
        readxl::read_excel(input$lm_data$datapath, sheet = 1)
      ),
      predictors = input$lm_predictors
    )
  })

  observeEvent(input$lm_analyze, {
    output$lmplot <- renderPlot({
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
  observeEvent(input$single_pred, {
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

  output$single_pred_out <- renderText({
    text_log()
  })

  # Predict Mult
  mult_pred_react <- reactive({
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

  observeEvent(input$mult_pred, {
    output$mult_pred_out <- renderTable({
      mult_pred_react()[, c("NAME", "SMILES", "pred_RT")]
    })
  })
  output$save_mult_pred <- downloadHandler(
    filename = "predictions.xlsx",
    content = function(file) {
      xlsx::write.xlsx(mult_pred_react(), file, sheetName = "predictions")
    }
  )
  return(NULL)
}
