library(tidyverse)
library(reticulate)
source(here::here("R/utils.R"))
source(here::here("R/run_ctbet.R"))


df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
print(nrow(df))

iid = get_fold()

iid = 5
idf = df[iid,]
print(idf)
file_nifti = idf$file_nifti_512_noneck
file_mask = idf$file_mask_ctbet_512_noneck

if (!file.exists(file_mask) && file.exists(file_nifti)) {
  res = run_ctbet(file_nifti, file_mask)
}


# unlink(full_image_folder, recursive = TRUE)
# unlink(full_save_folder, recursive = TRUE)
#to run unet3D model, use Predict3D
