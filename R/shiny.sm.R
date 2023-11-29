shiny.sm<-function(raw_data, method, k_cluster){

  # validate input data
  raw_data<- data.frame(raw_data)
  validate.inputdata(raw_data)

  tmp_data <- preprocess.data(data)

  print("step1 done")
  tmp_data$NAME<- NULL
  # Prepare data by scaling it
  smiles<- rownames(tmp_data)

  preProc <- caret::preProcess(tmp_data[, -1],
                               method = c("center","scale"),
                               rangeBounds = c(0, 1))
  tmp_data <- stats::predict(preProc, tmp_data)



  # Train Ridge Regression on all data

  model<- fit.glmnet(tmp_data,alpha =0)

  weights <- glmnet::coef.glmnet(model)
  weights <- data.frame(name = weights@Dimnames[[1]][weights@i + 1], coefficient = weights@x)
  weights <- weights[-1,]

  # Use the coefficients of trained model as feature weights




  tmp_data<- as.matrix(apply(tmp_data[,-1],1,function(x) x*weights$coefficient))
  tmp_data<- data.frame(t(tmp_data))
  colnames(tmp_data)<- weights$name[-1]

  # Apply Selective Measuring 1.0 on weighted features
  #
  #convert SMILES of data to match CD SMILES
  data$SMILES<-lapply(data$SMILES,function(x) rcdk::parse.smiles(as.character(unlist(x)))[[1]])

  data$SMILES <- lapply(data$SMILES,function(x) rcdk::get.smiles(x, rcdk::smiles.flavors(c("CxSmiles"))))

  tmp_data <- cbind(data[which(data$SMILES%in% smiles),"RT"], tmp_data)


  cluster <- stats::kmeans(tmp_data,centers=as.numeric(k_cluster), iter.max = 30,
                    nstart = 1)
  l<- list()


  for (i in c(seq_len(k_cluster))){
    distances<- tmp_data[which(cluster$cluster==i),]
    distances<- rbind(cluster$centers[i,],distances)
    distances<- stats::dist(distances, method="euclidean")
    distances<- as.matrix(distances)[,1]
    distances<- sort(distances)[-1]
    d<- data.frame(unlist(distances))
    d$SMILES<- rownames(d)
    l[[i]]<- merge(d,data[,which(colnames(data)%in% c("NAME","SMILES"))],by.x = "SMILES")
    l[[i]]<- l[[i]][order(l[[i]]$unlist.distances.),]
  }

  medoids<- l[[1]][1,]
  #write medoids:
  for (i in 2:k_cluster){
    medoids<- rbind(medoids,l[[i]][1,])
  }
  print("step6 done")

  return_obj<- list()
  return_obj$medoids<- medoids
  return_obj$cluster<- l

  return(return_obj)
}
