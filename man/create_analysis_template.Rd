% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/analysis.R
\name{create_analysis_template}
\alias{create_analysis_template}
\title{A helper function that creates a template for the analysis.  A
template is an internal representation of the analysis that is yet
to be started.  Aside from the combination of dataset_id and
workflow_id it contains some additional metadata like title,
abstract and description.}
\usage{
create_analysis_template(connection, dataset_id, workflow_id, title,
  abstract, description)
}
\arguments{
\item{connection}{The connection to be used, call \code{\link{connect}} to obtain one.}

\item{dataset_id}{dataset to be anlayzed}

\item{workflow_id}{workflow to be used}

\item{title}{title of the analysis}

\item{abstract}{short abstract of the analysis}

\item{description}{longer description}
}
\value{
class FGResponse
}
\description{
A helper function that creates a template for the analysis.  A
template is an internal representation of the analysis that is yet
to be started.  Aside from the combination of dataset_id and
workflow_id it contains some additional metadata like title,
abstract and description.
}
\examples{
None
}
