surv_summary <- function (x, data = NULL)
{
  res <- as.data.frame(.compact(unclass(x)[c("time", "n.risk",
                                             "n.event", "n.censor")]))
  if (inherits(x, "survfitms")) {
    surv <- 1 - x$prev
    upper <- 1 - x$upper
    lower <- 1 - x$lower
    res <- cbind(res, surv = c(surv), std.err = c(x$std.err),
                 upper = c(upper), lower = c(lower))
    res$state <- rep(x$states, each = nrow(surv))
  }
  else {
    if (is.matrix(x$surv)) {
      ncurve <- ncol(x$surv)
      res <- data.frame(time = rep(x$time, ncurve), n.risk = rep(x$n.risk,
                                                                 ncurve), n.event = rep(x$n.event, ncurve), n.censor = rep(x$n.censor,
                                                                                                                           ncurve))
      res <- cbind(res, surv = .flat(x$surv), std.err = .flat(x$std.err),
                   upper = .flat(x$upper), lower = .flat(x$lower))
      res$strata <- as.factor(rep(colnames(x$surv), each = nrow(x$surv)))
    }
    else res <- cbind(res, surv = x$surv, std.err = x$std.err,
                      upper = x$upper, lower = x$lower)
  }
  if (!is.null(x$strata)) {
    data <- .get_data(x, data = data)
    res$strata <- rep(names(x$strata), x$strata)
    res$strata <- .clean_strata(res$strata, x)
    variables <- .get_variables(res$strata, x, data)
    for (variable in variables) res[[variable]] <- .get_variable_value(variable,
                                                                       res$strata, x, data)
  }
  structure(res, class = c("data.frame", "surv_summary"))
  attr(res, "table") <- as.data.frame(summary(x)$table)
  res
}

