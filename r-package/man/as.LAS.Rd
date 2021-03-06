% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util.R
\name{as.LAS}
\alias{as.LAS}
\title{Convert data.frame of points to LAS object of lidR package.}
\usage{
as.LAS(df, proj4string = sp::CRS())
}
\description{
Convert data.frame of points (received from PointDB or PointCloud) to \link[lidR]{LAS} in lidR package.
}
\details{
optional parameter proj4string: crs of points. e.g. proj4string <- CRS(pointdb$info$proj4)
}
\seealso{
\link[lidR]{LAS}
}
\author{
woellauer
}
