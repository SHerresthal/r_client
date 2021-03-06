% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/workflows.R
\name{save_workflow_as_file}
\alias{save_workflow_as_file}
\title{Saves the JSON of a workflow as a file}
\usage{
save_workflow_as_file(workflow, path)
}
\arguments{
\item{workflow}{A FGResponse object with DataType == "workflow"}

\item{path}{The path to write the json to}
}
\description{
Works on edit_models and normal workflows
}
\examples{
connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
 # get a workflow as example
workflow <- fastgenomicsRclient::get_edit_model_of_workflow(connection, "wf_abc")
fastgenomicsRclient::save_workflow_as_file(workflow, "edit_mode.json")
}
