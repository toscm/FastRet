# create boxplots for up to 4 models to compare
# their performance measures

plot.boxplot <- function(model1, model2, model3, model4,
                         main = "main", name1 = "model1", name2 = "model2",
                         name3 = "model3", name4 = "model4", save_plot = FALSE) {
  stats <- t(matrix(as.numeric(unlist(model1$stats)),
                    nrow = 4))
  rmse <- stats[, 1]
  r2 <- stats[, 2]
  mae <- stats[, 3]
  percentage <- stats[, 4]
  models <- rep(name1, nrow(stats))
  measure_count <- nrow(stats)
  LC_column <- 0

  if (!missing(model2)) {
    stats <- t(matrix(as.numeric(unlist(model2$stats)),
                      nrow = 4))
    rmse <- c(rmse, stats[, 1])
    r2 <- c(r2, stats[, 2])
    mae <- c(mae, stats[, 3])
    percentage <- c(percentage, stats[, 4])
    models <- c(models, rep(name2, nrow(stats)))
    measure_count <- measure_count + nrow(stats)
  }

  if (!missing(model3)) {
    stats <- t(matrix(as.numeric(unlist(model3$stats)),
                      nrow = 4))
    rmse <- c(rmse, stats[, 1])
    r2 <- c(r2, stats[, 2])
    mae <- c(mae, stats[, 3])
    percentage <- c(percentage, stats[, 4])
    models <- c(models, rep(name3, nrow(stats)))
    measure_count <- measure_count + nrow(stats)
  }
  if (!missing(model4)) {
    stats <- t(matrix(as.numeric(unlist(model4$stats)),
                      nrow = 4))
    rmse <- c(rmse, stats[, 1])
    r2 <- c(r2, stats[, 2])
    mae <- c(mae, stats[, 3])
    percentage <- c(percentage, stats[, 4])
    models <- c(models, rep(name4, nrow(stats)))
    measure_count <- measure_count + nrow(stats)
  }

  models <- as.factor(rep(models, 4))
  measures <- c(rmse, r2, mae, percentage)
  measure_type <- as.factor(c(rep("RMSE", measure_count),
                              rep("R2", measure_count), rep("MAE", measure_count),
                              rep("% below 1 min", measure_count)))


  df <- data.frame(measures, LC_column = models,
                   measure_type)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = measure_type,
                                        y = measures))
  p <- p + ggplot2::xlab("performance measure")
  p <- p + ggplot2::ylab("")
  p <- p + ggplot2::geom_boxplot(position = ggplot2::position_dodge(0.75),
                                 ggplot2::aes(fill = LC_column))
  p <- p + ggplot2::theme_bw()
  p <- p + ggplot2::coord_cartesian(ylim = c(0, 2.8))
  p <- p + ggplot2::scale_fill_manual(values = c("#ff0000",
                                                 "#0000FF", "#00FF00", "#999999"))
  p <- p + ggplot2::ggtitle(main)

  if (save_plot) {
    grDevices::pdf(paste0("results/", main, ".pdf"))

    print(p)
    grDevices::dev.off()
  }

  return(p)
}
