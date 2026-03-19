Sys.setenv("RETICULATE_PYTHON" = "managed")
reticulate::py_require("pydicom")
library(dplyr)
library(readr)
library(fs)
library(here)
library(tidyr)
library(lubridate)
library(dcmtk)
library(purrr)
library(neurobase)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))

dir_header = here::here("data", "header")
dir_header_wide = here::here("data", "header_wide")
fs::dir_create(c(dir_header, dir_header_wide))

df = df %>%
  filter(type == "ct") %>%
  mutate(
    file_header = nii.stub(file_nifti, bn = TRUE),
    file_header = paste0(file_header, ".rds"),
    file_header = here::here(dir_header, file_header),
    file_header_wide = sub("/header/", "/header_wide/", file_header)
  )


bad = df %>%
  filter(!file.exists(file_header) & file.exists(file_header_wide))
iid = 1

for (iid in seq(nrow(df))) {
  idf = df[iid,]
  ufile = unique(idf$file_header)
  stopifnot(length(ufile) == 1)
  print(ufile)

  ufile_wide = unique(idf$file_header_wide)
  stopifnot(length(ufile_wide) == 1)

  if (!file.exists(ufile_wide) | !file.exists(ufile)) {
    files = list.files(path = idf$dir_series, full.names = TRUE,
               pattern = "[.]dcm$", ignore.case = TRUE)
    if (length(files) == 0) {
      message("No DICOM files found in ", idf$dir_series, ". Skipping.")
      next
    }
    # header = read_dicom_header(path = idf$dir_series, recursive = TRUE)
    header = read_header(files)
    if (is.null(header)) {
      return(NULL)
    }

    stopifnot(!anyNA(header$file))
    readr::write_rds(header, ufile)
    wide = wide_hdr(header)

    readr::write_rds(wide, ufile_wide)

  }
}
