install.packages("renv")
renv::consent(provided = TRUE)
renv::restore(rebuild = TRUE, prompt = FALSE)