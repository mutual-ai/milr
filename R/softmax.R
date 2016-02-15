#' @export
#' @method coef softmax
coef.softmax <- function(object, ...){
  return(object$coeffiecents)
}

#' @export
#' @method fitted softmax
fitted.softmax <- function(object, ...){
  return(object$fitted)
}

#' @export
#' @method predict softmax
predict.softmax <- function(object, newdata, bag_newdata, ...){
  return(coef(object) %>% {split(logit(cbind(1, newdata), .) > 0.5, bag_newdata)} %>%
           map_int(~ifelse(sum(.) > 1, 1L, 0L)))
}


#' Multiple-instance logistic regression via softmax function
#'
#' This function calculates the alternative maximum likelihood estimation for multiple-instance logistic regression
#' through a softmax function (Xu and Frank, 2004; Ray and Craven, 2005).
#'
#' @param y A vector. Binay response.
#' @param x The design matrix. The number of rows of x must be equal to the length of y.
#' @param bag A vector, bag id.
#' @param alpha A non-negative realnumber, the softmax parameter. 
#' @param maxit An integer, the maximum iteration for optimization algorithm (Nelder and Mead, 1965).
#' @return An list includes coefficients and fitted values.
#' @examples
#' set.seed(100)
#' beta <- runif(10, -5, 5)
#' trainData <- DGP(70, 3, beta)
#' testData <- DGP(30, 3, beta) 
#' # Fit softmax-MILR model S(0)
#' softmax_result <- softmax(trainData$Z, trainData$X, trainData$ID, alpha = 0)
#' coef(softmax_result)      # coefficients
#' fitted(softmax_result)    # fitted values
#' predict(softmax_result, testData$X, testData$ID) # predicted label
#' # Fit softmax-MILR model S(3)
#' softmax_result <- softmax(trainData$Z, trainData$X, trainData$ID, alpha = 3)
#' @references
#' \enumerate{
#'	 \item S. Ray, and M. Craven. (2005) Supervised versus multiple instance learning: An empirical comparsion. in Proceedings of the 22nd International Conference on Machine Learnings, ACM, 697--704.
#'	 \item X. Xu, and E. Frank. (2004) Logistic regression and boosting for labeled bags of instances. in Advances in Knowledge Discovery and Data Mining, Springer, 272--281.
#' }
#' @importFrom magrittr set_names
#' @importFrom purrr map map_int map2_dbl
#' @importFrom logistf logistf
#' @export
softmax <- function(y, x, bag, alpha = 0, maxit = 500) {
  # if x is vector, transform it to matrix
  if (is.vector(x))
    x <- matrix(x, ncol = 1)
  # input check
  assert_that(length(unique(y)) == 2, length(y) == nrow(x),
              all(is.finite(y)), is.numeric(y), all(is.finite(x)), is.numeric(x),  
              alpha >= 0, is.finite(alpha), is.numeric(alpha), is.finite(maxit), is.numeric(maxit), 
              abs(maxit - floor(maxit)) < 1e-4)
  # objectuve function - negative of the log-likelihood
  nloglik <- function(b){
    pii <- split(as.data.frame(cbind(1, x)), bag) %>% 
      purrr::map(~sum(logit(as.matrix(.), b)*exp(alpha*logit(as.matrix(.), b)), na.rm = TRUE)/
                   sum(exp(alpha*logit(as.matrix(.), b)), na.rm = TRUE) )
    return(-1*(purrr::map2_dbl(split(y, bag) %>% purrr::map(unique), pii, 
                               ~.x*log(.y)+(1-.x)*log(1-.y)) %>% sum(na.rm = TRUE)))
  }
  
  # initial value for coefficients
  init_beta <- coef(logistf(y~x))
  # optimize coefficients
  beta <- optim(init_beta, nloglik, control = list(maxit = maxit))$par
  
  beta %<>% as.vector %>% set_names(c("intercept", colnames(x)))
  fit_y <- beta %>% {split(logit(cbind(1, x), .) > 0.5, bag)} %>%
    purrr::map_int(~ifelse(sum(.) > 1, 1L, 0L))
  out <- list(coeffiecents = beta, fitted = fit_y, loglik = -nloglik(beta))
  class(out) <- 'softmax'
  return(out)
}