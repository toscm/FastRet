# Method Selection 

Here you can choose by which method the regression model should be trained on. You can choose between Lasso or XGBoost. 

## Lasso 
Lasso (Least absolut shrinkage and selection operator) is based on the Least Minimum Square approach with the extension of a L1 penalty norm. This leads to a selection of variables as well as a generalization of the trained model.  
Lasso was implemented with the R-package glmnet [2].

## XGBoost 

XGBoost is a more soffisticated Machine Learning method based on Boosted Regression Trees (BRT) [3]. The main difference to random forest is, that trees are not trained independant from each other but each tree is built with a loss function based on its predecessor. It was implemented with the R-package XGBoost [4].

## References
[1] Santosa, Fadil; Symes, William W. (1986). "Linear inversion of band-limited reflection seismograms". _SIAM Journal on Scientific and Statistical Computing_. SIAM. **7** (4): 1307–1330
[2] Jerome Friedman, Trevor Hastie, Robert Tibshirani (2010).
  Regularization Paths for Generalized Linear Models via
  Coordinate Descent. Journal of Statistical Software, 33(1),
  1-22.
[3] Jerome H. Friedman. "Greedy function approximation: A gradient boosting machine.." Ann. Statist. 29 (5) 1189 - 1232, October 2001
[4] Tianqi Chen et. Al, (2021). xgboost: Extreme Gradient Boosting. R package
  version 1.4.1.1.