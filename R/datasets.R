library(methods)
library(stringr)
library(httr)
library(jsonlite)

scopes = list("All", "Public", "Private")

get_datasets <- function(connection, scope="All"){
  if(!scope %in% scopes)
  {
    scope_str = paste(as.character(scopes), collapse=", ")
    msg = str_interp("scope is '${scope}' but should be one of: ${scope_str}")
    stop(msg)
  }

  assert_is_connection(connection)
  url <-  paste(connection@base_url, "dataset/api/v1/datasets", sep="")
  headers <- get_default_headers(connection)
  response <- httr::GET(url, headers, query=list(scope=scope,includeHateoas="true" ))
  stop_for_status(response)

  if (http_type(response) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }

  parsed <- jsonlite::fromJSON(content(response, "text"), simplifyVector = FALSE)
  dataset_id <- "" #  we do have multiple objects, so no id
  result <- new("FGResponse", path = url, content = parsed, DataType="List ofDatasets", Id=dataset_id )

  return(result)
}

get_dataset <- function(connection, dataset_id){
  assert_is_connection(connection)

  if(dataset_id == "")
  {
    msg = str_interp("dataset_id cannot be empty!")
    stop(msg)
  }

  url <- paste(connection@base_url, "dataset/api/v1/datasets/", dataset_id, sep="")

  headers <- get_default_headers(connection)
  response <- httr::GET(url, headers, query=list(includeHateoas="true"))

  if (response["status_code"] == 404) {
    stop(str_interp("The dataset '${dataset_id}' was not found on the server"),
      call. = FALSE
    )
 }

  stop_for_status(response)

  if (http_type(response) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }

  parsed <- jsonlite::fromJSON(content(response, "text"), simplifyVector = FALSE)
  dataset_id <- parsed[["dataset_id"]]
  result <- new("FGResponse", path = url, content = parsed, DataType="Dataset", Id=dataset_id )
}

download_dataset <- function(connection, dataset_id, folder_path){
  if (!dir.exists(folder_path))
  {
    msg = str_interp("The folder '${folder_path}' does not exist, please create it")
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
    msg = str_interp("No download link found, something is wrong. Please contact us.")
    stop(msg)
  }

 url <- paste(substr(connection@base_url, 1, nchar(connection@base_url)-1), download_link, sep="")
 browser()
 headers <- get_default_headers(connection)
 headers["output"] = write_disk(file.path(folder_path, str_interp("${dataset_id}.zip")))["output"]
 response <- httr::GET(url, headers)

 stop_for_status(response)
}

setClass("FGResponse",
         slots = c(
           content  = "list",
           path  = "character",
           response   = "list",
           DataType = "character",
           Id = "character"
         )
)

setMethod("show", "FGResponse", function(object) {
  cat(is(object)[[1]], "\n",
      "  DataType: ", object@DataType, "\n",
      "  Id:  ", object@Id, "\n",
      sep = ""
  )
})