#' get signs for ptms interactions
#'
#' ptms data does not contain sign (activation/inhibition), we generate this
#' information based on the interaction network
#'
#' @param ptms ptms data frame generated by \code{\link{import_omnipath_enzsub}}
#' @param interactions interaction data frame generated by
#' \code{\link{import_omnipath_interactions}}
#' @return data.frame of ptms with is_inhibition and is_stimulation columns
#' @export
#' @examples
#' ptms = import_omnipath_enzsub(resources=c("PhosphoSite", "SIGNOR"))
#' interactions = import_omnipath_interactions()
#' ptms = get_signed_ptms(ptms,interactions)
#' @seealso \code{\link{import_omnipath_enzsub}}
#' \code{\link{import_omnipath_interactions}}
get_signed_ptms <- function(
    ptms = import_omnipath_enzsub(),
    interactions = import_omnipath_interactions()
){

    signed.ptms <- merge(
        ptms,
        interactions[,c("source","target","is_stimulation","is_inhibition")],
        by.x = c("enzyme","substrate"),
        by.y = c("source","target"),
        all.x = TRUE
    )

    return(signed.ptms)
}
