lm.plot<- function(original_data, new_data, lm_model){

  new_data$SMILES<-lapply(new_data$SMILES,
                          function(x) rcdk::parse.smiles(as.character(unlist(x)))[[1]])
  new_data$SMILES <- lapply(new_data$SMILES,
                            function(x) rcdk::get.smiles(x, rcdk::smiles.flavors(c("CxSmiles"))))

  x <- original_data[which(rownames(original_data) %in% new_data$SMILES),]
  x<- x[unlist(new_data$SMILES),]
  y <- new_data$RT[which(new_data$SMILES %in% rownames(original_data))]

  p <- plot(x[,"RT"],y)
  p <-  p+ graphics::abline(a=0,b=1,col="#c04a30")
  p <- p + graphics::lines(sort(x[,"RT"]),stats::predict(lm_model)[order(x[,"RT"])],type="l",col="#2a92a9")
  return(list(p,1))
}
