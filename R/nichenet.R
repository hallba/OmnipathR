#!/usr/bin/env Rscript

#
#  This file is part of the `OmnipathR` R package
#
#  Copyright
#  2018-2020
#  Saez Lab, Uniklinik RWTH Aachen, Heidelberg University
#
#  File author(s): Alberto Valdeolivas
#                  Dénes Türei (turei.denes@gmail.com)
#                  Attila Gábor
#
#  Distributed under the MIT (Expat) License.
#  See accompanying file `LICENSE` or find a copy at
#      https://directory.fsf.org/wiki/License:Expat
#
#  Website: https://saezlab.github.io/omnipathr
#  Git repo: https://github.com/saezlab/OmnipathR
#


#' Builds all prior knowledge data required by NicheNet
#'
#' @param signaling_network A list of parameters for building the signaling
#'     network, passed to \code{\link{nichenet_signaling_network}}
#' @export
#'
#' @seealso \code{\link{nichenet_signaling_network}}
nichenet_prior_knowledge <- function(
    signaling_network = list()
){

    list(
        signaling_network = do.call(
            nichenet_signaling_network,
            signaling_network
        )
    )

}


#' Builds signaling network prior knowledge for NicheNet using multiple
#' resources
#'
#' @param omnipath List with paramaters to be passed to
#'     \code{\link{nichenet_signaling_network_omnipath}}
#' @param pathwaycommons List with paramaters to be passed to
#'     \code{\link{nichenet_signaling_network_pathwaycommons}}
#' @param harmonizome List with paramaters to be passed to
#'     \code{\link{nichenet_signaling_network_harmonizome}}
#' @export
#'
#' @seealso \code{\link{nichenet_signaling_network_omnipath},
#'     \link{nichenet_signaling_network_pathwaycommons},
#'     \link{nichenet_signaling_network_harmonizome}}
nichenet_signaling_network <- function(
    omnipath = list(),
    pathwaycommons = NULL,
    harmonizome = NULL,
    vinayagam = NULL,
    cpdb = NULL,
    evex = NULL,
    inweb = NULL
){



}


#' Builds signaling network prior knowledge for NicheNet using OmniPath
#'
#' @param min_curation_effort Lower threshold for curation effort
#' @param ... Passed to \code{\link{import_post_translational_interactions}}
#' @importsFrom dplyr %>% mutate select
#' @export
#'
#' @seealso
nichenet_signaling_network_omnipath <- function(
    min_curation_effort = 0,
    ...
){

    import_post_translational_interactions(entity_types = 'protein', ...) %>%
    select(from = source_genesymbol, to = target_genesymbol, is_directed) %>%
    mutate(
        source = ifelse(
            is_directed,
            'omnipath_directed',
            'omnipath_undirected'
        ),
        database = 'omnipath'
    ) %>%
    select(-is_directed)

}


#' Builds signaling network prior knowledge for NicheNet using PathwayCommons
#'
#' @param interaction_types Character vector with PathwayCommons interaction
#'     types. Please refer to the default value and the PathwayCommons
#'     webpage.
#' importsFrom dplyr %>% mutate
#' @importsFrom readr read_tsv
#' @export
nichenet_signaling_network_pathwaycommons <- function(
    interaction_types = c(
        'catalysis-precedes',
        'controls-phosphorylation-of',
        'controls-state-change-of',
        'controls-transport-of',
        'in-complex-with',
        'interacts-with'
    ),
    ...
){

    options('omnipath.pathwaycommons_url') %>%
    read_tsv(
        col_names = c('from', 'source', 'to'),
        col_types = cols()
    ) %>%
    filter(
        source %in% interaction_types
    ) %>%
    mutate(
        source = sprintf(
            'pathwaycommons_%s',
            gsub('-', '_', source, fixed = TRUE)
        ),
        database = 'pathwaycommons_signaling'
    )

}

#' Builds signaling network prior knowledge for NicheNet using Harmonizome
#'
#' @param datasets The datasets to use. For possible values please refer to
#'     default value and the Harmonizome webpage.
#' @importsFrom dplyr %>% mutate bind_rows
#' @export
nichenet_signaling_network_harmonizome <- function(
    datasets = c(
        'phosphosite',
        'kea',
        'depod',
    ),
    ...
){

    dataset_names <- list(
        phosphosite = 'PhosphoSite',
        kea = 'KEA',
        depod = 'DEPOD'
    )

    do.call(
        bind_rows,
        datasets %>% lapply(harmonizome_download)
    ) %>%
    mutate(
        source = sprintf('harmonizome_%s', dataset_names[source]),
        database = 'harmonizome'
    )

}


#' Downloads a single network dataset from Harmonizome
#' https://maayanlab.cloud/Harmonizome
#'
#' @param dataset The dataset part of the URL. Please refer to the download
#'     section of the Harmonizome webpage.
#' @importsFrom dplyr %>% mutate select
#' @importsFrom readr read_tsv read_lines
#' @export
harmonizome_download <- function(dataset){

    'omnipath.harmonizome_url' %>%
    options() %>%
    as.character() %>%
    sprintf(dataset) %>%
    url() %>%
    gzcon() %>%
    read_lines() %>%
    `[`(-2) %>%
    read_tsv(col_types = cols()) %>%
    select(from = source, to = target) %>%
    mutate(source = dataset)

}


#' Builds signaling network prior knowledge for NicheNet using Vinayagam 2011
#' Supplementary Table S6
#'
#' Find out more at https://doi.org/10.1126/scisignal.2001699
#'
#' @importsFrom dplyr %>% select mutate
#' @importsFrom readxl read_xls
#' @export
nichenet_signaling_network_vinayagam <- function(...){

    tmp_zip <- tempfile(fileext = '.zip')
    tmp_xls <- tempfile(fileext = '.xls')
    xls_con <- file(tmp_xls, open = 'wb')

    on.exit(unlink(tmp_xls))

    'omnipath.vinayagam_url' %>%
    options() %>%
    as.character() %>%
    download.file(destfile = tmp_zip, quiet = TRUE)

    xls_unz_con <- unz(tmp_zip, '2001699_Tables_S1_S2_S6.xls', open = 'rb')

    xls_unz_con %>%
    readBin(raw(), n = 6000000) %>%
    writeBin(xls_con, useBytes = TRUE)

    close(xls_unz_con)
    close(xls_con)
    unlink(tmp_zip)

    tmp_xls %>%
    read_xls(sheet = 'S6', progress = FALSE) %>%
    select(
        from = `Input-node Gene Symbol`,
        to = `Output-node Gene Symbol`
    ) %>%
    mutate(
        source = 'vinayagam_ppi',
        database = 'vinayagam'
    )

}


#' Builds signaling network prior knowledge for NicheNet using ConsensusPathDB
#' (CPDB)
#'
#' @importsFrom dplyr select mutate distinct
#' @importsFrom magrittr %>%
#' @export
nichenet_signaling_network_cpdb <- function(...){

    consensuspathdb() %>%
    select(from = genesymbol_a, to = genesymbol_b) %>%
    distinct() %>%
    mutate(
        source = sprintf(
            'cpdb_%s',
            ifelse(in_complex, 'complex', 'interaction')
        ),
        database = 'cpdb'
    ) %>%
    select(-in_complex)

}


#' Compiles a table of binary interactions from ConsensusPathDB and
#' translates the UniProtKB ACs to Gene Symbols
#'
#' @importsFrom readr read_tsv
#' @importsFrom tidyr separate_rows
#' @importsFrom dplyr mutate select inner_join left_join pull filter rename
#' @importsFrom dplyr group_by ungroup
#' @importsFrom magrittr %>%
#' @export
consensuspathdb <- function(){

    cpdb_raw <-  consensuspathdb_raw_table()

    uniprot_genesymbol <- cpdb_raw %>%
        separate_rows(participants, sep = '[,.]') %>%
        pull(participants) %>%
        unique() %>%
        uniprot_id_mapping(from = 'AC', to = 'GENENAME')

    cpdb_raw %>%
    mutate(
        record_id = n(),
        uniprot_b = participants
    ) %>%
    rename(uniprot_a = participants) %>%
    separate_rows(uniprot_a, sep = ',') %>%
    separate_rows(uniprot_b, sep = ',') %>%
    group_by(record_id) %>%
    mutate(in_complex = n() > 2) %>%
    ungroup() %>%
    separate_rows(uniprot_a, sep = '.') %>%
    separate_rows(uniprot_b, sep = '.') %>%
    filter(uniprot_a != uniprot_b) %>%
    left_join(uniprot_genesymbol, by = c('uniprot_a' = 'From')) %>%
    rename(genesymbol_a = To) %>%
    left_join(uniprot_genesymbol, by = c('uniprot_b' = 'From')) %>%
    rename(genesymbol_b = To)

}


#' Downloads interaction data from ConsensusPathDB
#'
#' @importsFrom readr read_tsv cols
#' @importsFrom magrittr %>%
#' @export
consensuspathdb_raw_table <- function(){

    'omnipath.cpdb_url' %>%
    options() %>%
    as.character() %>%
    read_tsv(
        col_names = c(
            'databases',
            'references',
            'participants',
            'confidence'
        ),
        col_types = cols(),
        skip = 2,
        progress = FALSE
    )

}


#' Retrieves an identifier translation table from the UniProt uploadlists
#' service
#'
#' @importsFrom readr read_tsv cols
#' @importsFrom httr POST
#' @importsFrom magrittr %>%
#' @export
uniprot_id_mapping <- function(identifiers, from, to){

    POST(
        url = 'https://www.uniprot.org/uploadlists/',
        body = list(
            from = from,
            to = to,
            format = 'tab',
            query = paste(identifiers, collapse = ' ')
        )
    ) %>%
    content(encoding = 'ASCII') %>%
    read_tsv(col_types = cols())

}