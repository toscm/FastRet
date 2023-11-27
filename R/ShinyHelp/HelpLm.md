# Adjust prediciton model with a linear model 

This mode can be used to adjust an existing model to a new experiment design. 
It requires a subset of the molecules that are in the original data set to be measured again with the new experiment. 
Afterwards the programm creates a linear model between the two experiments to adjust the predictions of the original model.
The coefficients of the model can be selected or unselected depending on the needs. An Intercept as well as the linear term are always included. 

To analyze the linear model click on "Analyze Linear Model" once. (if the checkbox is set a linear model will be trained and utilized on the predictions independant from this step)

The program maps the molecules through Isomeric SMILES so the new SMILES should be the same SMILES as they were in the original data set, otherwise a connection between two metabolites can not be drawn. 