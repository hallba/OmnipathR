#!/usr/bin/env Rscript

#
#  This file is part of the `OmnipathR` R package
#
#  Copyright
#  2018-2021
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


#' Default values for the package options
#'
#' These options describe the default settings for OmnipathR so you do not
#' need to pass these parameters at each function call.
#' Currently the only option useful for the public web service at
#' omnipathdb.org is ``omnipath.license``. If you are a for-profit
#' user set it to ``'commercial'`` to make sure all the data you download
#' from OmniPath is legally allowed for commercial use. Otherwise just leave
#' it as it is: ``'academic'``.
#' If you don't use omnipathdb.org but within your organization you deployed
#' your own pypath server and want to share data whith a limited availability
#' to outside users, you may want to use a password. For this you can use
#' the ``omnipath.password`` option.
#' Also if you want the R package to work from another pypath server instead
#' of omnipathdb.org, you can change the option ``omnipath.url``.
.omnipath_options_defaults <- list(
    omnipath.url = 'https://omnipathdb.org/',
    omnipath.license = 'academic',
    omnipath.password = NULL,
    omnipath.print_urls = FALSE,
    omnipath.loglevel = 'trace',
    omnipath.console_loglevel = 'success',
    omnipath.logfile = NULL,
    omnipath.cachedir = NULL,
    omnipath.cache_timeout = 5,
    omnipath.pathwaycommons_url = paste0(
        'https://www.pathwaycommons.org/archives/PC2/v12/',
        'PathwayCommons12.All.hgnc.sif.gz'
    ),
    omnipath.harmonizome_url = paste0(
        'https://maayanlab.cloud/static/hdfs/harmonizome/data/',
        '%s/gene_attribute_edges.txt.gz'
    ),
    omnipath.vinayagam_url = paste0(
        'https://stke.sciencemag.org/content/sigtrans/suppl/2011/09/01/',
        '4.189.rs8.DC1/4_rs8_Tables_S1_S2_and_S6.zip'
    ),
    omnipath.cpdb_url = paste0(
        'http://cpdb.molgen.mpg.de/download/',
        'ConsensusPathDB_human_PPI.gz'
    ),
    omnipath.evex_url = paste0(
        'http://evexdb.org/download/network-format/Metazoa/',
        'Homo_sapiens.tar.gz'
    ),
    omnipath.all_uniprots_url = paste0(
        'https://www.uniprot.org/uniprot/?',
        'query=*&format=tab&force=true&columns=%s&fil=',
        'organism:%d%s&compress=no'
    ),
    omnipath.inbiomap_url = paste0(
        'https://inbio-discover.intomics.com/api/data/map_public/',
        '2016_09_12/inBio_Map_core_2016_09_12.tar.gz'
    ),
    omnipath.inbiomap_login_url = paste0(
        'https://inbio-discover.intomics.com/api/login_guest'
    )
)

.omnipath_local_config_fname <- 'omnipathr.yml'

omnipath_get_user_config_path <- function(){

    file.path(
        user_config_dir(appname = 'OmnipathR', appauthor = 'saezlab'),
        'omnipathr.yml'
    )

}

#' importFrom rappdirs user_config_dir
omnipath_get_default_config_path <- function(user = FALSE){

    `if`(
        file.exists(.omnipath_local_config_fname) && !user,
        .omnipath_local_config_fname,
        omnipath_get_user_config_path()
    )

}


omnipath_get_config_path <- function(user = FALSE){

    config_path_default <- omnipath_get_default_config_path(user = user)

    config_path <- mget(
        'omnipath_config',
        envir = .GlobalEnv,
        ifnotfound = Sys.getenv('OMNIPATHR_CONFIG')
    )[[1]]

    `if`(nchar(config_path) > 0, config_path, config_path_default)

}


omnipath_ensure_config_dir <- function(){

    .ensure_dir(.omnipath_config_path)

}


#' Save the current package configuration
#'
#' @param path Path to the config file. Directories and the file will be
#' created if don't exist.
#' @param title Save the config under this title. One config file might
#' contain multple configurations, each identified by a title.
#' @param local Save into a config file in the current directory instead of
#' a user level config file. When loading, the config in the current directory
#' has prioroty over the user level config.
#'
#' @export
#' @importFrom yaml write_yaml
omnipath_save_config <- function(
        path = NULL,
        title = 'default',
        local = FALSE
    ){

    path <- `if`(
        is.null(path),
        `if`(
            local,
            omnipath_local_config_fname(),
            omnipath_get_config_path()
        ),
        path
    )
    .ensure_dir(path)

    omnipath_options_to_config()
    this_config <- list()
    this_config[[title]] <- .omnipath_config

    write_yaml(this_config, file = path)

}


#' Load the package configuration from a config file
#'
#' @param path Path to the config file.
#' @param title Load the config under this title. One config file might
#' contain multple configurations, each identified by a title. If the title
#' is not available the first section of the config file will be used.
#' @param user Force to use the user level config even if a config file
#' exists in the current directory. By default, the local config files have
#' prioroty over the user level config.
#'
#' @export
#' @importFrom yaml yaml.load_file
#' @importFrom RCurl merge.list
omnipath_load_config <- function(
        path = NULL,
        title = 'default',
        user = FALSE,
        ...
    ){

    path <- `if`(
        is.null(path),
        omnipath_get_config_path(user = user),
        path
    )

    yaml_config <- yaml.load_file(input = path, ...)

    if(title %in% names(yaml_config)){
        this_config <- yaml_config[[title]]
    }else{
        title <- names(yaml_config)[1]
        if(!is.na(title)){
            this_config <- yaml_config[[title]]
        }
    }

    if(title != 'default' && 'default' %in% yaml_config){
        this_config <- RCurl::merge.list(
            this_config,
            yaml_config[['default']]
        )
    }

    # ensure the `omnipath.` prefix for all parameter keys
    names(this_config) <- ifelse(
        startsWith(names(this_config), 'omnipath.'),
        names(this_config),
        sprintf('omnipath.%s', names(this_config))
    )

    this_config <- RCurl::merge.list(
        this_config,
        .omnipath_options_defaults
    )

    .omnipath_config <<- this_config
    omnipath_config_to_options()

}


#' Restores the built-in default values of all config parameters
#'
#' @param save If a path, the restored config will be also saved
#' to this file. If TRUE, the config will be saved to the current default
#' config path (see `omnipath_get_config_path()`).
#'
#' @return The config as a list.
#'
#' @export
#' @seealso \code{\link{omnipath_load_config}, \link{omnipath_save_config},
#' \link{omnipath_get_config_path}}
omnipath_reset_config <- function(save = NULL){

    .omnipath_config <<- .omnipath_options_defaults
    omnipath_config_to_options()

    if(!is.null(save)){
        path <- `if`(
            is.logical(save) && save,
            omnipath_get_config_path(),
            save
        )
        omnipath_save_config(path)
    }

    invisible(.omnipath_config)

}


#' Populates the config from the default local or user level config file
#' or the built-in defaults.
omnipath_init_config <- function(user = FALSE){

    config_path <- omnipath_get_config_path(user = user)

    if(file.exists(config_path)){
        omnipath_load_config(config_path)
    }else{
        # this normally happens only at the very first use of the package
        omnipath_reset_config(save = config_path)
    }

}


#' Loads the settings from .omnipath_config to options
omnipath_config_to_options <- function(){

    do.call(options, .omnipath_config)

}

#' Copies OmnipathR settings from options to .omnipath_config
#'
#' @importFrom RCurl merge.list
omnipath_options_to_config <- function(){

    from_options <- do.call(
        options,
        as.list(names(.omnipath_options_defaults))
    )
    .omnipath_config <<- merge.list(
        from_options,
        .omnipath_config
    )

}


#' Setting up the logfile and logging parameters.
omnipath_init_log <- function(pkgname = 'OmnipathR'){

    log_path <- `if`(
        is.null(options('omnipath.logfile')[[1]]),
        file.path(
            'omnipathr-log',
            sprintf('omnipathr-%s.log', format(Sys.time(), "%Y%m%d-%H%M"))
        ),
        options('omnipath.logfile')[[1]]
    )
    dir.create(dirname(log_path), showWarnings = FALSE, recursive = TRUE)

    for(idx in 1:2){
        # 1 = logfile
        # 2 = console

        loglevel <- sprintf(
            'omnipath.%sloglevel',
            `if`(idx == 1, '', 'console_')
        )
        appender <- `if`(
            idx == 1,
            logger::appender_file(log_path),
            logger::appender_console
        )
        layout_format <- `if`(
            idx == 1,
            paste0(
                '[{format(time, "%Y-%d-%m %H:%M:%S")}] ',
                '[{level}] [{ns}] ',
                '{msg}'
            ),
            paste0(
                '[{format(time, "%Y-%d-%m %H:%M:%S")}] ',
                '[{colorize_by_log_level(level, levelr)}] [{ns}] ',
                '{grayscale_by_log_level(msg, levelr)}'
            )
        )

        logger::log_formatter(
            logger::formatter_glue_or_sprintf,
            namespace = pkgname,
            index = idx
        )
        logger::log_threshold(
            ensure_loglevel(options(loglevel)[[1]]),
            namespace = pkgname,
            index = idx
        )
        logger::log_appender(appender, namespace = pkgname, index = idx)
        logger::log_layout(
            logger::layout_glue_generator(format = layout_format),
            namespace = pkgname,
            index = idx
        )

    }

}


.onLoad <- function(libname, pkgname){

    omnipath_init_config()
    omnipath_init_log(pkgname = pkgname)

    logger::log_info('Welcome to OmnipathR!')

}