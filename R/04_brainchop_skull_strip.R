library(neurobase)
library(brainchop)
library(tibble)
library(dplyr)
library(fs)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))


iid = get_fold()

for (iid in seq(nrow(df))) {
  print(iid)
  idf = df[iid,]

  file_nifti = idf$file_nifti
  file_mask = idf$file_mask
  file_ss = idf$file_ss


  if (!all(file.exists(c(file_ss, file_mask)))) {

    Sys.setenv(
      GPU = 0,
      CPU = 0,
      LLVM = 1,
      METAL = 0,
      CUDA = 0
    )
    res = ct_mindgrab(
      input = file_nifti,
      device = "LLVM"
    )
    file.copy(res$output_file, file_ss, overwrite = TRUE)
    file.copy(res$mask_file, file_mask, overwrite = TRUE)

  }
}
