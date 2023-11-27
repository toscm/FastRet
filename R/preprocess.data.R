#function to preprocess data in order to train models on said data
# expects data as dataframe with 4 columns NAME, INCHKEY,
# SMILES, RT

# Prepare data set variables
#   preprocessed: if TRUE no additional
#     preprocessing gets done
#   clean_data: if TRUE columns with NA's or near zero variance get excluded
#   scale: if TRUE data gets scaled and scaling model gets returned
#   include_polynomial: if TRUE polynomials of each
#     columns get added as new one
#   degree_polynomial: defines how many polynomials get added (if 3
#     quadratic and cubic terms get added)
#   interaction_terms: if T all interaction terms
#     get added to data set

preprocess.data <- function(data, preprocessed = FALSE,
                            include_HMDB = FALSE,
                            clean_data = TRUE,
                            include_polynomial = FALSE,
                            degree_polynomial = 2,
                            interaction_terms = FALSE) {

  db_rt<-data


  if (preprocessed) {
    db_rt <- data
  } else {
    # Calculate Chemical Descriptors
    db_rt <- suppressWarnings(getCD(data), classes = "warning")

    if (clean_data) {

      # clean data, exclude columns with
      # NA's or near zero variance
      db_rt <- db_rt[, !apply(db_rt, 2, function(x) any(is.na(x)))]
      db_rt <- db_rt[, -caret::nearZeroVar(db_rt)]
      db_rt <- data.frame(db_rt)
      db_rt <- db_rt[, -which(colnames(db_rt) %in%
                                c("NAME", "SMILES", "InChIKey","INCHKEY"))]

    } else {
      #Kier3 has NA's in it therefore set NA's to mean of columns
      db_rt[which(is.na(db_rt[, "Kier3"])), "Kier3"] <- mean(db_rt[, "Kier3"], na.rm = TRUE)
      db_rt <- db_rt[, !apply(db_rt, 2, function(x) any(is.na(x)))]
      db_rt <- db_rt[, -which(colnames(db_rt) %in%
                                c("NAME", "SMILES", "InChIKey","INCHKEY"))]


    }
  }
  # add Polynomial predictors up to a specified
  # degree_polynomial if include_polynomial = T
  npredictors <- ncol(db_rt)
  if (include_polynomial) {
    for (p in c(2:degree_polynomial)) {
      for (predictor in c(2:npredictors)) {
        # add predicotr**p as new column
        # to predictor set
        new_name <- paste(colnames(db_rt)[predictor],
                          "^", p, sep = "")
        db_rt[, new_name] <- db_rt[, predictor]^p
      }
    }
  }


  # add interaction terms, if interaction_terms = T
  if (interaction_terms) {

    for (predictor in c(2:npredictors - 1)) {
      for (predictor2 in c((predictor + 1):npredictors)) {
        new_name <- paste(colnames(db_rt)[predictor],
                          "/", colnames(db_rt)[predictor2],
                          sep = "")

        db_rt[, new_name] <- db_rt[, predictor]/db_rt[, predictor2]
      }
    }
    db_rt[is.na.data.frame(db_rt)] <- 0
  }


  return(db_rt)

}
