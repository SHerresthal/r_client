% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasets.R
\name{create_dataset}
\alias{create_dataset}
\title{Creates a new dataset on fastgenomics}
\usage{
create_dataset(connection, title, description, short_description,
  organism_id, matrix, matrix_format, gene_nomenclature,
  optional_parameters = NULL)
}
\arguments{
\item{connection}{The connection to be used, call
\code{\link{connect}} to obtain one.}

\item{title}{The Title of the dataset}

\item{description}{A description of the dataset, ca be Markdown}

\item{short_description}{A oneliner describing your dataset}

\item{organism_id}{The NCBI Taxonomy ID of your dataset, passed as
an integer. Currently supported IDs are 9606 (Homo Sapiens) and
10090 (Mouse)}

\item{matrix}{The path to your datafile in a supported
\href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md}{format}
OR a dataframe.  If it's a data frame it will be saved in a
temporary location on your hard drive and uploaded as a file.}

\item{matrix_format}{The
\href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md#upload-file-structure}{format}
of your matrix.}

\item{gene_nomenclature}{The gene nomenclature to be used, call
\code{\link{get_valid_gene_nomenclatures}} to get a list of
supported formats}

\item{optional_parameters}{Further parameters to be used, eg. gene
metadata or cell metadata files. Use
\code{\link{FGDatasetUploadParameters}} to define these
parameters.}
}
\value{
FGResponse in case of success, FGErrorResponse if the validation failed for any reason.
}
\description{
This call will create the dataset, but the validation on the server
can take a long time. The dataset cannot be used before the
validation is complete. Use
\code{\link{poll_dataset_until_validated}} to query the server for
the validation status.  For details on what data formats are
supported by FASTGenomics refer to the documentation
\href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md}{here}.
}
\examples{
connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
optional <- fastgenomicsRclient::FGDatasetUploadParameters(
                                        license ="MIT",
                                        technology = "Smart-Seq",
                                        web_link="https://example.com",
                                        notes="This is a TEST",
                                        citation="FG et al",
                                        batch_column="sample",
                                        current_normalization_status="Counts",
                                        cell_metadata="./cell_metadata.tsv", # you can also use a dataframe directly
                                        gene_metadata="./gene_metadata.tsv"  ) # you can also use a dataframe directly
 result <- fastgenomicsRclient::create_dataset(connection,
                           "R client test",
                           "description",
                           "short_description",
                           9606,
                           "./matrix.tsv" , # you can also use a dataframe directly
                           "sparse_cell_gene_expression",
                           "Entrez",
                           optional )

 status <- fastgenomicsRclient::poll_dataset_until_validated(connection, result, 1 ) # validation messages are shown as messages
 print(status) # should be TRUE
}
