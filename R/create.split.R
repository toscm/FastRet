create.split <- function(split_method, data, n = 10) {

  if (split_method == "CV") {

    if (!(n %in% c(2:length(data$RT)))) {
      stop(paste("nfolds = ", n, "is invalid input must either be \"LOO\" or integer between 2 and amount of samples"))
    }
    split <- caret::createFolds(y = data$RT, k = n)
    return(split)

  } else if (split_method == "Medoids-kmean") {
    # create splits according their clustered
    # Chemical descriptors

    # calculate n clusters
    cluster <- stats::kmeans(data, centers = n, iter.max = 30,
                      nstart = 1)

    # create distance matrice
    dist <- pdist::pdist(as.matrix(data), as.matrix(cluster$centers))
    dist <- as.matrix(dist)
    split <- list()
    rownames(dist) <- rownames(data)
    split[[1]] <- rownames(dist)[apply(dist, 2,
                                       which.min)]
    dist <- dist[-apply(dist, 2, which.min), ]

    # convert to indexes
    split[[1]] <- match(split[[1]], rownames(data))

    return(split)

  }else if (split_method=="Medoids-kmean2"){
    # create splits according to their weighted clustered Descriptors


    # Train Elastic Net on all data


    model<- fit.glmnet(data,alpha =0)

    weights <- glmnet::coef.glmnet(model)
    weights <- data.frame(name = weights@Dimnames[[1]][weights@i + 1], coefficient = weights@x)
    weights <- weights[-1,]

    # Use the coefficients of trained model as feature weights



    RT<- data$RT
    data<- as.matrix(apply(data[,-1],1,function(x) x*weights$coefficient))
    data<- data.frame(t(data))
    colnames(data)<- weights$name[-1]
    data <- cbind(RT, data)




    # calculate n clusters
    cluster <- stats::kmeans(data, centers = n, iter.max = 30,
                      nstart = 1)

    # create distance matrice
    dist <- pdist::pdist(as.matrix(data), as.matrix(cluster$centers))
    dist <- as.matrix(dist)
    split <- list()
    rownames(dist) <- rownames(data)
    split[[1]] <- rownames(dist)[apply(dist, 2,
                                       which.min)]
    dist <- dist[-apply(dist, 2, which.min), ]

    # convert to indexes
    split[[1]] <- match(split[[1]], rownames(data))

    return(split)

  } else {
    stop(paste0("Split method ", split_method, " not known"))
  }
}



