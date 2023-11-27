# Predictor selection 

Here you can defined how your predcitor dataset should look like. 
Principle Predictors can be added by CDK [1] or via the HMDB [2] database. Keep in mind that predictors that have zero to none variance are excluded before training the regression model.

## Chemistry Development Kit (CDK) 

This option calculates 291 precitors by using the R-Wrapper package RCDK [3]. For this option you need to provide SMILES with your data. 
For further details about this predictor set, see: 
https://egonw.github.io/cdkbook/appmoldescs.html#molecular-descriptors

## Human Metabolome Database (HMDB) 

The HMDB provides a wide variety of information for metabolomic researchers, this software utilizes the provided predicted molecular properties. For this option you need to provide the HMDB ID's with your data. 

## References 

[1] Willighagen et al. The Chemistry Development Kit (CDK) v2.0: atom typing, depiction, molecular formulas, and substructure searching. J. Cheminform. 2017; 9(3)
[2] Wishart DS, Feunang YD, Marcu A, Guo AC, Liang K, et al., _HMDB 4.0 — The Human Metabolome Database for 2018._ Nucleic Acids Res. 2018. Jan 4;46(D1):D608-17
[3] Guha, R. (2007). 'Chemical Informatics Functionality in R'.  Journal of Statistical Software 6(18)

