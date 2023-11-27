
<!-- README.md is generated from README.Rmd. Please edit that file -->

# FastRet

<!-- badges: start -->
<!-- badges: end -->

The goal of FastRet is to provide easy retention time prediction for
Liquid Chromatography especially with small datasets and adapt this prediction for new experiment setups.
By providing a GUI to navigate through the steps we removed all barriers to entry this domain of science. The package utilizes rcdk to get predictor variables from SMILES and training regression model (Lasso/XGBoost) on this data.

## Installation

You can install the development version of FastRet from
[GitHub](https://github.com/) with:

``` r
 install.packages("devtools")
 devtools::install_github("ChristianAmes/FastRet", build_vignettes = T)
```

## Starting the GUI

You can start the GUI with one function call.

``` r
library(FastRet)

FastRet()
```



A more in-depth tutorial on how to use this package is available as a
vignette

``` r
vignette("fastret", package="FastRet")

```
