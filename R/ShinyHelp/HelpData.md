# Training data upload 

Here you can upload your own data to the tool. In order for this to work you need to follow a strikt .xlsx format. If any columns are named incorrect the program won't work correctly. The programm wil always load in the first worksheet of the excel file. Therefore it is suggested that you reduce your file to one sheet beforehand to avoid any errors. 

## Required columns 
The file must consist of the following columns (case sensitive) :

- "RT": Retention time of your molecules. Can be any numeric input, minutes or seconds. Remember what you put in when you analyse the predictions, since those will be on the same scale as your input data.
- "NAME": you can put in any characters you like. Preferably the names of your molecules. (Names are used for identification in the Selective Measuring Mode)  
- "SMILES":  Isomeric or canonical SMILES, has to be present for chemical descriptors calculated with the chemistry development kit
- "HMDB": (only necessary for predictors gotten from the HMDB) HMDB ID, can have the following formats: HMDB0000001, 1, 001, HMDB00001 (it is suggested you use the official format of "HMDB" + 7 digits id) 

## More columns 
You can include your own predictors to be indluded in the regression analysis. To do that simply add columns to your input data and name them whatever you like. Keep in mind that you need to reproduce the same columns when trying to do predictions afterwards. Those columns should consist of pure numeric entries with preferably no categorical data. If you have nominal data you might get away with leaving it in but if you have ordinal data consider creating seperated columns for each individual category with either 0 or 1 depending on the affiliation of your molecules. If a column does not contain pure numerical values it is excluded beforehand. 
