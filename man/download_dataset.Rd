% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasets.R
\name{download_dataset}
\alias{download_dataset}
\title{Downloads the whole dataset content as a zip file to the specified folder}
\usage{
download_dataset(connection, dataset_id, folder_path)
}
\arguments{
\item{connection}{The connection to be used, call \code{\link{connect}} to obtain one.}

\item{dataset_id}{The id of the dataset, usually starting with dts_*****}

\item{folder_path}{Where to store the dataset? Must exist and be writeable}
}
\value{
None, see the folder for the content
}
\description{
Downloads the whole dataset content as a zip file to the specified folder
}
\examples{
connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
fastgenomicsRclient::download_dataset(connection, "dts_abc", "/temp/")
}
