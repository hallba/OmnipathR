% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/import.R
\name{get_intercell_generic_categories}
\alias{get_intercell_generic_categories}
\alias{get_intercell_classes}
\title{Retrieves a list of the generic categories in the intercell database
of OmniPath}
\usage{
get_intercell_generic_categories()

get_intercell_classes(...)
}
\arguments{
\item{...}{Passed to \code{get_intercell_generic_categories}.}
}
\value{
character vector with the different intercell main classes
}
\description{
Retrieves a list of the generic categories from
\url{https://omnipath.org/intercell}.
}
\examples{
get_intercell_generic_categories()
}
\seealso{
\code{\link{import_omnipath_intercell},
\link{get_intercell_categories}}
}
