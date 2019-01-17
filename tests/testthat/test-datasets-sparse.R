context("test-datasets-sparse")

BEARER_FROM_ENV = Sys.getenv("FGBEARERTOKEN")
BASE_URL = Sys.getenv("FGBASEURL")

gen_data <- function(){
    cell_metadata = data.frame(cellId=c("cell_1", "cell_2", "cell_3"))
    gene_metadata = data.frame(geneId=c("gene_1", "gene_2", "gene_3"))
    matrix = sparseMatrix(
        i=c(1,2), j=c(2,3), x=c(4,5),
        giveCsparse=FALSE, dims=c(3,3), dimnames=list(gene_metadata$geneId, cell_metadata$cellId))
    return(list(cells=cell_metadata, genes=gene_metadata, matrix=matrix))
}

gen_args <- function(replacements){
    default_conn <- new(
        "FGConnection", base_url=BASE_URL, bearer_token=BEARER_FROM_ENV)
    input = gen_data()
    args = list(connection = default_conn,
                matrix = input$matrix,
                cell_metadata = input$cells,
                gene_metadata = input$genes,
                title = "R client test",
                description = "description",
                short_description = "short_description",
                organism_id = 9606,
                gene_nomenclature = "GeneSymbol",
                tmpdir="./temp")
    args[names(replacements)] = replacements
    args
}

test_that(
    "create-sparse: can create a dataset", {
        default_conn <- new(
            "FGConnection", base_url=BASE_URL, bearer_token=BEARER_FROM_ENV)
        input <- gen_data()
        result <- create_dataset_df(default_conn,
                                    matrix = input$matrix,
                                    cell_metadata = input$cells,
                                    gene_metadata = input$genes,
                                    title = "R client test",
                                    description = "description",
                                    short_description = "short_description",
                                    organism_id = 9606,
                                    gene_nomenclature = "GeneSymbol",
                                    tmpdir="./tmpdata")
        expect_is(result, "FGResponse")
    })

test_that(
    "create-sparse: wrong matrix type", {
        args <- gen_args(list(matrix = "abc"))
        expect_error(do.call(create_dataset_df, args), "Unsupported matrix format, expected a \"dgTMatrix\".")
    })

test_that(
    "create-sparse: wrong cell_metadata type", {
        args <- gen_args(list(cell_metadata = "abc"))
        expect_error(do.call(create_dataset_df, args), "cell_metadata must be a data frame.")
    })

test_that(
    "create-sparse: wrong gene_metadata type", {
        args <- gen_args(list(gene_metadata = "abc"))
        expect_error(do.call(create_dataset_df, args), "gene_metadata must be a data frame.")
    })

test_that(
    "create-sparse: cell_metadata has no cellId", {
        args <- gen_args(list(cell_metadata = data.frame()))
        expect_error(do.call(create_dataset_df, args), "cell_metadata must have a cellId column.")
    })

test_that(
    "create-sparse: gene_metadata has no geneId", {
        args <- gen_args(list(gene_metadata = data.frame()))
        expect_error(do.call(create_dataset_df, args), "gene_metadata must have a geneId column.")
    })

test_that(
    "create-sparse: no common cell names", {
        args <- gen_args(list(cell_metadata = data.frame(cellId=c(1,2,3))))
        expect_error(do.call(create_dataset_df, args), "No common cell names found in matrix and cell_metadata.")
    })

test_that(
    "create-sparse: no common gene names", {
        args <- gen_args(list(gene_metadata = data.frame(geneId=c(1,2,3))))
        expect_error(do.call(create_dataset_df, args), "No common gene names found in matrix and gene_metadata.")
    })