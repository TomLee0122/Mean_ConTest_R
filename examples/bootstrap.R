# Helpers for running the source-tree examples without installing the package.
load_meancontest <- function(project_dir, envir = parent.frame()) {
  source_dir <- file.path(project_dir, "R")
  if (file.exists(file.path(source_dir, "api.R"))) {
    for (path in sort(list.files(source_dir, pattern = "\\.R$", full.names = TRUE))) {
      sys.source(path, envir = envir)
    }
  } else {
    if (!requireNamespace("meancontest", quietly = TRUE)) {
      stop("Install meancontest or run these scripts from its source tree.", call. = FALSE)
    }
    for (name in c("ConTest", "Utilities", "contest_constants")) {
      assign(name, getExportedValue("meancontest", name), envir = envir)
    }
  }
  invisible(project_dir)
}

load_example_helpers <- function(project_dir, envir = parent.frame()) {
  for (name in c("constants", "utilities", "data_generation", "adversary")) {
    sys.source(file.path(project_dir, "examples", paste0(name, ".R")), envir = envir)
  }
  invisible(project_dir)
}
