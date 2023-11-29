#' getCD
#'
#' Calculate Chemical Descriptors using RCDK, function is based on Retip::getCD.
#'
#' @param x dataframe with two mandatory column: "Name" and "SMILES"
#' @param verbose TRUE if additional print output should be shown
#' @keywords FastRet
#' @export
getCD <- function (x, verbose = FALSE)
{
  print(paste0("Converting SMILES..."))
  for (i in seq_len(nrow(x))) {
    smi <- rcdk::parse.smiles(smiles = as.character(unlist(x[i, "SMILES"])))[[1]]
    smi1 <- rcdk::generate.2d.coordinates(smi)
    smi1 <- rcdk::get.smiles(smi, rcdk::smiles.flavors(c("CxSmiles")))
    x$SMILES[i] <- smi1
    if (verbose){ print(paste0(i, " of ", nrow(x)))}
  }
  descNames <- rcdk::get.desc.names(type = "all")
  descNames1 <- c("org.openscience.cdk.qsar.descriptors.molecular.BCUTDescriptor")
  print(paste0("Checking for compound errors..."))
  mols_x <- rcdk::parse.smiles(as.character(unlist(x[1, "SMILES"])))
  descs1_x <- rcdk::eval.desc(mols_x, descNames1)
  for (i in 2:nrow(x)) {
    mols1 <- rcdk::parse.smiles(as.character(unlist(x[i,
                                                      "SMILES"])))
    descs1_x[i, ] <- rcdk::eval.desc(mols1, descNames1)
    if (verbose){ print(paste0(i, " of ", nrow(x)))}
  }
  x_na <- data.frame(descs1_x, x)
  x_na_rem <- x_na[stats::complete.cases(descs1_x), ]
  x_na_rem <- x_na_rem[, -c(seq_len(6))]
  print(paste0("Computing Chemical Descriptors ",
               nrow(x_na_rem), " ... Please wait"))
  mols_x1 <- rcdk::parse.smiles(as.character(unlist(x_na_rem[1,
                                                             "SMILES"])))[[1]]
  rcdk::convert.implicit.to.explicit(mols_x1)
  descs_x_loop <- rcdk::eval.desc(mols_x1, descNames)
  for (i in 2:nrow(x_na_rem)) {
    mols <- rcdk::parse.smiles(as.character(unlist(x_na_rem[i,
                                                            "SMILES"])))[[1]]
    rcdk::convert.implicit.to.explicit(mols)
    descs_x_loop[i, ] <- rcdk::eval.desc(mols, descNames)
    if (verbose){print(paste0(i, " of ", nrow(x_na_rem)))}

  }
  datadesc <- data.frame(x_na_rem, descs_x_loop)
  return(datadesc)
}
