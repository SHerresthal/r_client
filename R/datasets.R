library(methods)
library(stringr)
library(httr)
library(jsonlite)
library(lubridate)

scopes = list("All", "Public", "Private")

#' Get all datasets
#'
#' This list does not contain rejected datasets, only valid, usable datasets.
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#' @param scope Filters the datasets by their scope. Possible Values are: 'All': return all datasets, 'Private': Only your personal datasets, 'Public': Only public datasets
#'
#' @return A FGResponse object
#' @export

#' @examples
#' connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
#' datasets <- fastgenomicsRclient::get_datasets(connection)
#' print(datasets@content) # all datasets available to you
get_datasets <- function(connection, scope="All"){
  url <-  paste(connection@base_url, "dataset/api/v1/datasets", sep="")
  result <- get_data_list(connection, scope, url, "dataset", queries=list(includeHateoas="true" ))

  return(result)
}


#' Get a specific dataset
#'
#' Gets information about a specific dataset. This can also be used to obtain information about a failed dataset upload
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#' @param dataset_id The id of the dataset, usually starting with dts_*****
#'
#' @return A FGResponse object
#' @export
#'
#' @examples
#' connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
#' datasets <- fastgenomicsRclient::get_dataset(connection, "dts_abc")
#' print(datasets@content) # the dataset
get_dataset <- function(connection, dataset_id){
  url <- paste(connection@base_url, "dataset/api/v1/datasets/", dataset_id, sep="")
  result <- get_data(connection, dataset_id, url, "dataset")
  return(result)
}

#' Downloads the whole dataset content as a zip file to the specified folder
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#' @param dataset_id The id of the dataset, usually starting with dts_*****
#' @param folder_path Where to store the dataset? Must exist and be writeable
#'
#' @return None, see the folder for the content
#' @export
#'
#' @examples
#' connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
#' fastgenomicsRclient::download_dataset(connection, "dts_abc", "/temp/")
download_dataset <- function(connection, dataset_id, folder_path){
  if (!dir.exists(folder_path))
  {
    msg = stringr::str_interp("The folder '${folder_path}' does not exist, please create it")
    stop(msg)
  }

  dataset <- get_dataset(connection, dataset_id)
  download_link <- ""
  for (lnk in dataset@content[["links"]]){
    rel <- lnk[["rel"]]

    if (rel == "download-dataset-complete-zip")
    {
       download_link <- lnk[["href"]]
    }
  }

  if (download_link == "")
  {
    msg = stringr::str_interp("No download link found, something is wrong. Please contact us.")
    stop(msg)
  }

 url <- paste(substr(connection@base_url, 1, nchar(connection@base_url)-1), download_link, sep="")
 headers <- get_default_headers(connection)
 headers["output"] = httr::write_disk(file.path(folder_path, stringr::str_interp("${dataset_id}.zip")))["output"]
 headers <- c(headers, httr::progress())
 response <- httr::GET(url, headers)

 httr::stop_for_status(response)
}

#' Creates a new dataset on fastgenomics
#'
#' This call will create the dataset, but the validation on the server
#' can take a long time. The dataset cannot be used before the
#' validation is complete. Use
#' \code{\link{poll_dataset_until_validated}} to query the server for
#' the validation status.  For details on what data formats are
#' supported by FASTGenomics refer to the documentation
#' \href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md}{here}.
#'
#' @param connection The connection to be used, call
#'     \code{\link{connect}} to obtain one.
#' @param title The Title of the dataset
#' @param description A description of the dataset, ca be Markdown
#' @param short_description A oneliner describing your dataset
#' @param organism_id The NCBI Taxonomy ID of your dataset, passed as
#'     an integer. Currently supported IDs are 9606 (Homo Sapiens) and
#'     10090 (Mouse)
#' @param matrix The path to your datafile in a supported
#'     \href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md}{format}
#'     OR a dataframe.  If it's a data frame it will be saved in a
#'     temporary location on your hard drive and uploaded as a file.
#' @param matrix_format The
#'     \href{https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md#upload-file-structure}{format}
#'     of your matrix.
#' @param gene_nomenclature The gene nomenclature to be used, call
#'     \code{\link{get_valid_gene_nomenclatures}} to get a list of
#'     supported formats
#' @param optional_parameters Further parameters to be used, eg. gene
#'     metadata or cell metadata files. Use
#'     \code{\link{FGDatasetUploadParameters}} to define these
#'     parameters.
#'
#' @return FGResponse in case of success, FGErrorResponse if the validation failed for any reason.
#' @export
#'
#' @examples
#' connection <- fastgenomicsRclient::connect("https://fastgenomics.org/", "Beaer ey...")
#' optional <- fastgenomicsRclient::FGDatasetUploadParameters(
#'                                         license ="MIT",
#'                                         technology = "Smart-Seq",
#'                                         web_link="https://example.com",
#'                                         notes="This is a TEST",
#'                                         citation="FG et al",
#'                                         batch_column="sample",
#'                                         current_normalization_status="Counts",
#'                                         cell_metadata="./cell_metadata.tsv", # you can also use a dataframe directly
#'                                         gene_metadata="./gene_metadata.tsv"  ) # you can also use a dataframe directly
#'  result <- fastgenomicsRclient::create_dataset(connection,
#'                            "R client test",
#'                            "description",
#'                            "short_description",
#'                            9606,
#'                            "./matrix.tsv" , # you can also use a dataframe directly
#'                            "sparse_cell_gene_expression",
#'                            "Entrez",
#'                            optional )
#'
#'  status <- fastgenomicsRclient::poll_dataset_until_validated(connection, result, 1 ) # validation messages are shown as messages
#'  print(status) # should be TRUE
create_dataset <- function(connection, title, description, short_description, organism_id, matrix , matrix_format, gene_nomenclature, optional_parameters=NULL)
{
  assert_is_connection(connection)
  assert_token_is_not_expired(connection)

  gene_nomenclatures <- get_valid_gene_nomenclatures(connection)
  if (!gene_nomenclature %in% gene_nomenclatures)
  {
    str = paste(as.character(gene_nomenclatures), collapse=", ")
    stop(stringr::str_interp("The Gene Nomenclature '${gene_nomenclature} is unknown. Choose one of: ${str}' "))
  }

  if (!is.numeric(organism_id))
  {
    stop(stringr::str_interp("The organism id '${organism_id}' is not an integer. Valid NCBI Ids are integers, e.g. Homo Sapiens: 9606 Mouse: 10090"))
  }

  matrix_formats <- get_valid_matrix_formats(connection)
  if (!matrix_format %in% matrix_formats)
  {
    str = paste(as.character(matrix_formats), collapse=", ")
    stop(stringr::str_interp("The Matrix format '${matrix_format}' is unknown. Choose one of: ${str}' "))
  }

  matrix_path <- ""
  if (is.character(matrix)){
    matrix_path <- matrix
  }
  else if (is.data.frame(matrix))
  {
    matrix_path <- get_df_as_file(matrix, "matrix.csv")
  }
  else
  {
    stop("the given matrix is neither a file path nor a dataframe!")
  }

  if (!file.exists(matrix_path))
  {
      stop(stringr::str_interp("The file '${matrix_path}' does not exist. Please provide a valid file!. See https://github.com/FASTGenomics/fastgenomics-docs/blob/master/doc/api/dataset_api.md for valid file formats "))
  }

  optional_data <- list()

  if (!is.null(optional_parameters))
  {
    if (!is(optional_parameters, "FGDatasetUploadParameters"))
    {
      stop("the optional_parameters need to be either NULL or a FGDatasetUploadParameters object. Call new('FGDatasetUploadParameters', ..) to obtain such an object.")
    }
    optional_data <- get_data_from_FGDatasetUploadParameters(optional_parameters, connection)
  }

  headers <- get_default_headers(connection)
  headers <- c(headers, httr::progress("up")) # adds a nice progress bar
  url <-  paste(connection@base_url, "dataset/api/v1/datasets", sep="")

  body = list(
    matrix  = httr::upload_file(matrix_path),
                          title = title,
                          description = description,
                          short_description = short_description,
                          organism_id = organism_id,
                          matrix_format= matrix_format,
                          gene_nomenclature=gene_nomenclature)

  body = c(body, optional_data)

  response <- httr::POST(url, headers, body = body )
  return(parse_response(response, "dataset"))
}

#' Waits for the validation of the dataset to complete.
#'
#' Messages and errors are used to show messages. If you need all messages, use \code{\link{get_dataset}} with the id of this dataset
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#' @param dataset_id The id of the dataset, usually starting with dts_***** OR a FGResponse object
#' @param poll_intervall The time to wait for a new status update in seconds
#'
#' @return TRUE if the validation succeeded, otherweise FALSE
#' @export
#'
#' @examples
#' See create_dataset example
poll_dataset_until_validated <- function(connection, dataset_id, poll_intervall=10){
  assert_is_connection(connection)
  assert_token_is_not_expired(connection)
  if (is(dataset_id, "FGResponse"))
  {
    dtype <- dataset_id@DataType
    if (!dtype == "dataset"){
      stop(stringr::str_interp("Only FgResponse with a DataType of 'dataset' can be polled! This is a ${dtype}"))
    }
    dataset_id <- dataset_id@Id
  }

  if (!is.character(dataset_id))
  {
    stop(stringr::str_interp("dataset_id can be either a character vector or a FgResponse object."))
  }

  headers <- get_default_headers(connection)
  url <-  paste(connection@base_url, "dataset/api/v1/datasets/", dataset_id, "/status", sep="")
  last_check <- lubridate::ymd("2010/03/17") # something old
  while (TRUE) {
    Sys.sleep(poll_intervall)
    response <- httr::GET(url, headers)
    httr::stop_for_status(response)

    parsed <- jsonlite::fromJSON(httr::content(response, "text"), simplifyVector = FALSE)


    for (msg in parsed) {
      msg_time <- lubridate::as_datetime(msg[["timestamp"]], tz="UTC")
      if (msg_time > last_check){
        status <- msg[["status"]]
        file_name <- msg[["file_name"]]
        msg_text <- msg[["msg"]]

        if (status == "Error"){
          warning(stringr::str_interp("${msg_time} | ${status} | ${file_name} | ${msg_text}"))
        }
        else{
          message(stringr::str_interp("${msg_time} | ${status} | ${file_name} | ${msg_text}"))
        }

      }
    }

    newest_message <- parsed[[length(parsed)]]
    if (newest_message[["status"]] == "Ready")
    {
      # success!
      return(TRUE)
    }

    if (newest_message[["status"]] == "Rejected")
    {
      # error!
      warning(stringr::str_interp("There where upload errors. Call get_dataset with the id of this dataset to obtain more information."))
      return(FALSE)
    }

    last_check <- lubridate::now(tz="UTC")
  }

}

#' Get a list of all supported gene nomenclatures
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#'
#' @return a list of the valid gene nomenclatures
#' @export
#'
#' @examples
#' None
get_valid_gene_nomenclatures = function(connection){
  return(get_info(connection, "dataset/api/v1/validgenenomenclatures"))
}

#' Get a list of all supported matrix formats
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#'
#' @return a list of the valid matrix formats
#' @export
#'
#' @examples
#' None
get_valid_matrix_formats = function(connection){
  return(get_info(connection, "dataset/api/v1/validmatrixformats"))
}

#' Get a list of all supported technologies
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#'
#' @return a list of the valid technologies
#' @export
#'
#' @examples
#' None
get_valid_technologies = function(connection){
  return(get_info(connection, "dataset/api/v1/validtechnologies"))
}

#' Get a list of all supported normalization schemes
#'
#' @param connection The connection to be used, call \code{\link{connect}} to obtain one.
#'
#' @return a list of supported normalization schemes
#' @export
#'
#' @examples
#' None
get_valid_current_normalization_status = function(connection){
  return(get_info(connection, "dataset/api/v1/validcurrentnormalizationstatus"))
}

get_info <- function(connection, url){
  assert_is_connection(connection)
  assert_token_is_not_expired(connection)

  headers <- get_default_headers(connection)
  url <- paste(connection@base_url, url, sep="")
  response <- httr::GET(url, headers)
  httr::stop_for_status(response)
  parsed <- jsonlite::fromJSON(httr::content(response, "text"), simplifyVector = FALSE)
  data = lapply(parsed, function(x){ return(x[["key"]])})
  return(data)
}

get_df_as_file <- function(df, file_name){
  column_names <- names(df)

  tempdir <- tempdir()
  rand_folder <- stringi::stri_rand_strings(n=1, length = 20)[[1]]
  message(stringr::str_interp("Saving dataframe for '${file_name}' to disk"))
  tmp_dir <- file.path(tempdir, rand_folder)
  tmp_file <- file.path(tmp_dir, file_name )
  dir.create(tmp_dir)
  write.csv(df, tmp_file, row.names=FALSE)

  message(stringr::str_interp("compressing file '${file_name}', this may take a while"))
  zip_file <- file.path(tmp_dir, "data.zip")
  zip(zipfile = zip_file, files=tmp_file, flags="-j")

  message(stringr::str_interp("Compressing ${file_name}' finished"))
  return(zip_file)
}
