validate.inputdata<- function(raw_data){

  if((!"RT" %in% colnames(raw_data))) stop("RT could not be found in excel sheet")
  if((!"NAME" %in% colnames(raw_data))) stop("NAME could not be found in excel sheet")
  if((!"SMILES" %in% colnames(raw_data))) stop("SMILES could not be found in excel sheet")

  raw_data<- cbind(raw_data[,which(colnames(raw_data)%in% c("RT", "NAME","SMILES"))],
                   raw_data[,-which(colnames(raw_data)%in% c("RT", "NAME","SMILES"))])

  include <- c(TRUE,TRUE,TRUE)
  include <- c(include,
                   vapply(raw_data[,-which(colnames(raw_data)%in% c("RT", "NAME","SMILES"))],
                          FUN = function(x) is.numeric(x),
                          FUN.VALUE = logical(length = 1)))

  if(ncol(raw_data)!=length(include)) include<- c(include[c(1,2,3)],all(include[4:length(include)]))

  return(raw_data[,include])

}
