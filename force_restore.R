if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

options(repos = BiocManager::repositories())
Sys.setenv(RENV_CONFIG_BIOCONDUCTOR_VERSION = "3.12")

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

renv::restore(project = "workflow", prompt = FALSE)
