# Set default CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.org"))

# Set default R package directory
library_path <- "~/.local/R/library"
if (!dir.exists(library_path)[1]) {
  dir.create(library_path, recursive = TRUE)
}

.libPaths(library_path)
