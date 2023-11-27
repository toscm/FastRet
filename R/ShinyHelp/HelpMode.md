# Welcome to FastRet!

With this R shiny tool you can choose between three modes. 

- Train new Model
- Selective Measuring 
- Utilize Model on new data

Each mode is shortly described here. For more information about the inputs see the (?) behind the corresponding input. 

## Train new Model 

This is usually the first step you take, this mode allows you to create and evaluate a Model on your own new data. Model can be trained with various parameters and afterwards the regression model as well as the predictor set can be downloaded. As an evaluation this step outputs you a scatterplot of your regression model as well as a boxplot with its general performance.

## Selective Measuring 

This mode calculates on a given dataset the best k molecules to be measured for a retention time prediction. It uses a combination of Ridge Regression and k-means to determine the best representatives of your dataset. Representatives as well as their corresponding clusters can be downloaded afterwards as an excel file. This step should be used once you have a predictive model ond/or data set and want to use it for new column/gradient/temperature... combination.

## Utilize model on new data

This step requires a pretrained model which can be uploaded. Afterwards you can use your model to predict retention times of new metabolites by providing either a single SMILE/HMDB ID combination or a whole list of molecules.