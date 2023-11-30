app_ui <- function() {
  navbarPage(title = "FastRet",
    tabPanel(title = "Predict LCMS Retention Times", sidebarLayout(tab_fast_ret_sidebar(), tab_fast_ret_mainpanel())),
    tabPanel(title = "Privacy Policy", fluidPage(HTML(html_privacy_policy))),
    tabPanel(title = "Contact", fluidPage(HTML(html_contact))),
    tabPanel(title = "About", fluidPage(tags$pre(paste(capture.output(sessionInfo()), collapse='\n'))))
  )
}

tab_fast_ret_mainpanel <- function() {
  mainPanel(
    shinybusy::add_busy_spinner(spin = "fading-circle"),
    verbatimTextOutput("single_pred_out"),
    tableOutput("mult_pred_out"),
    verbatimTextOutput("value"),
    verbatimTextOutput("medoidtable"),
    tableOutput("medoids"),
    verbatimTextOutput("scatterplot"),
    plotOutput("plot"),
    verbatimTextOutput("boxplot"),
    plotOutput("plot2"),
    plotOutput("lmplot")
  )
}

tab_fast_ret_sidebar <- function() {
  sidebarPanel(
    # Mode
    helper(selectInput(inputId = "mode", label = h3("Mode"), choices = c("Train new Model", "Selective Measuring", "Utilize Model to predict on new Data")), content = help_mode),
    # Data as .xlsx file
    conditionalPanel(
      condition = "input.mode == 'Selective Measuring' || input.mode == 'Train new Model'",
      helper(fileInput("inputdata", h3("Data as .xlsx file"), accept = ".xlsx"), content = help_inputdata)
    ),
    # Train new Model
    conditionalPanel(
      condition = "input.mode == 'Train new Model'",
      helper(radioButtons("method", h3("Method"), choices = list("Lasso" = 1, "XGBoost" = 2), selected = 1), content = help_method),
      actionButton("train", "Train Model and get evaluation"),
      downloadButton("save_model", "save Model"),
      downloadButton("save_predictors", "save predictor set as csv")
    ),
    # Selective Measuring
    conditionalPanel(
      condition = "input.mode == 'Selective Measuring'",
      numericInput("k", h3("k Cluster "), value = 25),
      actionButton("sm2", "Calculate Cluster and Medodids"),
      downloadButton("save_cluster", "Save Cluster and Medoids as .xlsx")
    ),
    # Utilize Model to predict on new Data
    conditionalPanel(
      condition = "input.mode == 'Utilize Model to predict on new Data'",
      helper(fileInput("pretrained_model", "Upload a pretrained Model"), content = help_pretrained_model),
      helper(checkboxInput("lm_transfer", "Use measured metabolites to adjust Prediciton"), content = help_lm_transfer),
      conditionalPanel(
        condition = "input.lm_transfer == true",
        fileInput("lm_data", h3("Transfer data to train lm as .xlsx file"), accept = ".xlsx"),
        checkboxGroupInput("lm_predictors", h3("Choose components of lm"), choices = list("x^2" = 1, "x^3" = 2, "log(x)" = 3, "exp(x)" = 4, "sqrt(x)" = 5)),
        actionButton("lm_analyze", "Analyze Linear Model")
      ),
      textInput("smiles", "Input SMILES", value = ""),
      actionButton("single_pred", "Calculate single input"),
      helper(fileInput("preddata", h3("New data to predict as .xlsx file"), accept = ".xlsx"), content = help_preddata),
      actionButton("mult_pred", "Calculate predictions for input file"),
      downloadButton("save_mult_pred", "Save predictions for input file")
    )
  )
}

helper <- function(..., content) {
  shinyhelper::helper(
    ...,
    icon = "question-circle",
    colour = "#696969",
    type = "inline",
    content = content
  )
}

help_preddata <- '
  <h1 id="prediction-data-upload">Prediction Data Upload</h1>
  <p>This file input has to be an excel file with the following columns:</p>
  <ul>
  <li>NAME</li>
  <li>SMILES (if model used uses CDK descriptors)</li>
  <li>HMDB (if model used uses HMDB descriptors)</li>
  </ul>
'

help_lm_transfer <- '
  <h1 id="adjust-prediciton-model-with-a-linear-model">Adjust prediciton model with a linear model</h1>
  <p>This mode can be used to adjust an existing model to a new experiment design. It requires a subset of the molecules that are in the original data set to be measured again with the new experiment. Afterwards the programm creates a linear model between the two experiments to adjust the predictions of the original model. The coefficients of the model can be selected or unselected depending on the needs. An Intercept as well as the linear term are always included.</p>
  <p>To analyze the linear model click on &quot;Analyze Linear Model&quot; once. (if the checkbox is set a linear model will be trained and utilized on the predictions independant from this step)</p>
  <p>The program maps the molecules through Isomeric SMILES so the new SMILES should be the same SMILES as they were in the original data set, otherwise a connection between two metabolites can not be drawn. </p>
'

help_pretrained_model <- '
  <h1 id="model-upload">Model upload</h1>
  <p>Here you need to upload a prediction model generated with this programm in the &quot;Train new Model&quot; mode.
  This Model can also be read in with R by calling</p>
  <blockquote>
  <p>model&lt;- readRDS( <em>path to model file</em>)</p>
  </blockquote>
  <p>Things you can do with this are e.g. analyzing lasso coefficients for a model:</p>
  <blockquote>
  <p>coef(codel$final_model) </p>
  </blockquote>
  <p>or analyzing the predictor set with </p>
  <blockquote>
  <p>model$predictor_set</p>
  </blockquote>
  <p>In detail this R object contains the following information:</p>
  <ul>
  <li>which method was used</li>
  <li>the final model, either a glmnet or xgboost object depending on the method</li>
  <li>scaling model, simple prediction model to scale and center new data</li>
  <li>predictor set, consisting of the whole sample/varaible matrix used for training the model</li>
  <li>statistical measures for all cross validation steps </li>
  <li>which split was used for the cross validation </li>
  </ul>
'

help_mode <- '
  <h1 id="welcome-to-Fastret-">Welcome to Ret!</h1>
  <p>With this R shiny tool you can choose between three modes. </p>
  <ul>
  <li>Train new Model</li>
  <li>Selective Measuring </li>
  <li>Utilize Model on new data</li>
  </ul>
  <p>Each mode is shortly described here. For more information about the inputs see the (?) behind the corresponding input. </p>
  <h2 id="train-new-model">Train new Model</h2>
  <p>This is usually the first step you take, this mode allows you to create and evaluate a Model on your own new data. Model can be trained with various parameters and afterwards the regression model as well as the predictor set can be downloaded. As an evaluation this step outputs you a scatterplot of your regression model as well as a boxplot with its general performance.</p>
  <h2 id="selective-measuring">Selective Measuring</h2>
  <p>This mode calculates on a given dataset the best k molecules to be measured for a retention time prediction. It uses a combination of Ridge Regression and k-means to determine the best representatives of your dataset. Representatives as well as their corresponding clusters can be downloaded afterwards as an excel file. This step should be used once you have a predictive model ond/or data set and want to use it for new column/gradient/temperature... combination.</p>
  <h2 id="utilize-model-on-new-data">Utilize model on new data</h2>
  <p>This step requires a pretrained model which can be uploaded. Afterwards you can use your model to predict retention times of new metabolites by providing either a single SMILE/HMDB ID combination or a whole list of molecules.</p>
'

help_method <- '<h1 id="method-selection">Method Selection</h1>
  <p>Here you can choose by which method the regression model should be trained on. You can choose between Lasso or XGBoost. </p>
  <h2 id="lasso">Lasso</h2>
  <p>Lasso (Least absolut shrinkage and selection operator) is based on the Least Minimum Square approach with the extension of a L1 penalty norm. This leads to a selection of variables as well as a generalization of the trained model.<br>Lasso was implemented with the R-package glmnet [2].</p>
  <h2 id="xgboost">XGBoost</h2>
  <p>XGBoost is a more soffisticated Machine Learning method based on Boosted Regression Trees (BRT) [3]. The main difference to random forest is, that trees are not trained independant from each other but each tree is built with a loss function based on its predecessor. It was implemented with the R-package XGBoost [4].</p>
  <h2 id="references">References</h2>
  <p>[1] Santosa, Fadil; Symes, William W. (1986). &quot;Linear inversion of band-limited reflection seismograms&quot;. <em>SIAM Journal on Scientific and Statistical Computing</em>. SIAM. <strong>7</strong> (4): 1307<e2><80><93>1330
  [2] Jerome Friedman, Trevor Hastie, Robert Tibshirani (2010).
    Regularization Paths for Generalized Linear Models via
    Coordinate Descent. Journal of Statistical Software, 33(1),
    1-22.
  [3] Jerome H. Friedman. &quot;Greedy function approximation: A gradient boosting machine..&quot; Ann. Statist. 29 (5) 1189 - 1232, October 2001
  [4] Tianqi Chen et. Al, (2021). xgboost: Extreme Gradient Boosting. R package
    version 1.4.1.1.</p>
'

help_inputdata <- '
  <h1 id="training-data-upload">Training data upload</h1>
  <p>Here you can upload your own data to the tool. In order for this to work you need to follow a strikt .xlsx format. If any columns are named incorrect the program won&#39;t work correctly. The programm wil always load in the first worksheet of the excel file. Therefore it is suggested that you reduce your file to one sheet beforehand to avoid any errors. </p>
  <h2 id="required-columns">Required columns</h2>
  <p>The file must consist of the following columns (case sensitive) :</p>
  <ul>
  <li>&quot;RT&quot;: Retention time of your molecules. Can be any numeric input, minutes or seconds. Remember what you put in when you analyse the predictions, since those will be on the same scale as your input data.</li>
  <li>&quot;NAME&quot;: you can put in any characters you like. Preferably the names of your molecules. (Names are used for identification in the Selective Measuring Mode)  </li>
  <li>&quot;SMILES&quot;:  Isomeric or canonical SMILES, has to be present for chemical descriptors calculated with the chemistry development kit</li>
  <li>&quot;HMDB&quot;: (only necessary for predictors gotten from the HMDB) HMDB ID, can have the following formats: HMDB0000001, 1, 001, HMDB00001 (it is suggested you use the official format of &quot;HMDB&quot; + 7 digits id)</li>
  </ul>
  <h2 id="more-columns">More columns</h2>
  <p>You can include your own predictors to be indluded in the regression analysis. To do that simply add columns to your input data and name them whatever you like. Keep in mind that you need to reproduce the same columns when trying to do predictions afterwards. Those columns should consist of pure numeric entries with preferably no categorical data. If you have nominal data you might get away with leaving it in but if you have ordinal data consider creating seperated columns for each individual category with either 0 or 1 depending on the affiliation of your molecules. If a column does not contain pure numerical values it is excluded beforehand.</p>
'

html_privacy_policy <- '
  <div class="mainpanel">
  <h1>Privacy</h1>
  <h2>Cookies</h2>
  <div>This website does not use cookies.</div>
  <h2> Server Log</h2>
  <div>The web server keeps a log of all requests, with the following data:</div>
  <ul>
    <li>The request IP adress</li>
    <li>Date and Time of the request</li>
    <li>request type and path</li>
    <li>the User-Agent of the web browser</li>
  </ul>
  <div>This data is only used to diagnose tecnical problems.</div>
  <h2>Web Analytics / Other Tracking</h2>
  <div>There are no other tracking methods.</div>
  <h2>Privacy Contact</h2>
  <a href="http://www.uni-regensburg.de/universitaet/datenschutzbeauftragte/index.html">
    Datenschutzbeauftrage derUniversität
  </a>
  </div>
'

html_contact <- '
<div class="mainpanel">
  <h1>Contact</h1>
  <hr/>
  <div>
    <address>
      <strong> Dr. Katja Dettmer-Wilde </strong><br />
      Institute of Functional Genomics<br />
      University of Regensburg<br />
      Am BioPark 9<br />
      93053 Regensburg, Germany<br />
      <abbr title="Phone">P: </abbr>+49 941 943 5051<br />
      <abbr title="Email">M: </abbr>katja.dettmer@klinik.uni-regensburg.de
    </address>
  </div>
</div>
'