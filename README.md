<!-- badges: start -->
[![R CMD check](https://github.com/toscm/FastRet/workflows/R-CMD-check/badge.svg)](https://github.com/toscm/FastRet/actions)
<!-- badges: end -->

# FastRet

The goal of FastRet is to provide easy retention time prediction for Liquid Chromatography especially with small datasets and adapt this prediction for new experiment setups. By providing a GUI to navigate through the steps we removed all barriers to entry this domain of science. The package utilizes rcdk to get predictor variables from SMILES and training regression model (Lasso/XGBoost) on this data.

## Installation

You can install the development version of FastRet from [GitHub](https://github.com/) with:

```R
install.packages("devtools")
devtools::install_github("toscm/FastRet", build_vignettes = TRUE)
```

## Usage

You can start the GUI with one function call.

```R
FastRet::FastRet()
```
A more in-depth tutorial on how to use this package is available as a vignette at 

``` r
vignette("fastret", package="FastRet")
```
