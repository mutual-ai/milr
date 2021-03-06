% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{logit}
\alias{logit}
\title{logit link function}
\usage{
logit(X, beta)
}
\arguments{
\item{X}{A matrix, the design matrix.}

\item{beta}{A vector, the coefficients.}
}
\value{
An vector of the values of logit link.
}
\description{
calculate the values of logit link
}
\examples{
logit(matrix(c(1, 0.5, -0.2, 0.3), 2), c(-0.5, -3)) # 0.5249792, 0.2404891
}

