library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))


ifold = get_fold(default = NA_real_)
if (all(is.na(ifold))) {
  ifold = sort(unique(df$fold))
}
open = function(...) {
  system2("open", ...)
}
df = df %>%
  filter(fold %in% ifold)

iid = 1
all_bad = NULL
print(nrow(df))
for (iid in seq(nrow(df))) {
  print(iid)
  idf = df[iid,]
  print(idf$dir_series)

  dir_series = idf$dir_series
  file_nifti = idf$file_nifti
  type = idf$type
  if (!file.exists(file_nifti)) {
    res = try({
      ct_dcm2nii(basedir = dir_series,
                 verbose = FALSE,
                 dcm2niicmd = "dcm2niix_feb2024",
                 ignore_roi_if_multiple = TRUE,
                 fail_on_error = TRUE)
    })
    # if error on conversion or only 2 dimensions (aka one slice)
    # print message and move on to hext one
    if (length(dim(res)) != 3 || inherits(res, "try-error")) {
      message("Bad: ", dir_series)
      all_bad = c(all_bad, dir_series)
        next
    }
    # write file to disk
    writenii(res, file_nifti)
  } else {
    # res = readnii(file_nifti, drop_dim = FALSE)
  }

}
print(all_bad)
