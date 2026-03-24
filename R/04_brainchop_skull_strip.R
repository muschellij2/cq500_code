library(neurobase)
library(brainchop)
library(tibble)
library(dplyr)
library(fs)
source(here::here("R/utils.R"))
df = tibble(
  file_nifti = list.files(
    path = here::here("data", "nifti"),
    recursive = TRUE,
    pattern = "_ct.nii.gz",
    full.names = TRUE),
  type = "ct"
)
# df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
dir_ss = here::here("data", "brain_extracted_brainchop")
dir_mask = here::here("data", "brain_mask_brainchop")



fs::dir_create(
  c(
    dir_ss,
    dir_mask
  )
)

df = df %>%
  filter(type == "ct") %>%
  mutate(
    stub = basename(file_nifti),
    id_patient = sub("_.*", "", stub),
    file_ss = here::here(dir_ss, stub),
    file_mask = here::here(dir_mask, stub)
  ) %>%
  select(-stub) %>%
  mutate(id = sub("_(ct|roi)", "", nii.stub(file_nifti, bn = TRUE) ))

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
