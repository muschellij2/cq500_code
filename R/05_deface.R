library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(freesurfer)
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
dir_ss = here::here("data", "brain_extracted")
dir_mask = here::here("data", "brain_mask")
dir_face_mask = here::here("data", "face_mask")
dir_biometric_mask = here::here("data", "biometric_mask")

fs::dir_create(
  c(
    dir_ss,
    dir_mask,
    dir_face_mask,
    dir_biometric_mask
  )
)

df = df %>%
  filter(type == "ct") %>%
  mutate(
    stub = basename(file_nifti),
    id_patient = sub("_.*", "", stub),
    file_ss = here::here(dir_ss, stub),
    file_face_mask = here::here(dir_face_mask, stub),
    file_biometric_mask = here::here(dir_biometric_mask, stub),
    file_mask = here::here(dir_mask, stub)
  ) %>%
  select(-stub) %>%
  mutate(id = sub("_(ct|roi)", "", nii.stub(file_nifti, bn = TRUE) ))

iid = get_fold()

# for (iid in seq(nrow(df))) {
print(iid)
idf = df[iid,]

file_nifti = idf$file_nifti
file_mask = idf$file_mask
file_ss = idf$file_ss
file_face_mask = idf$file_face_mask
file_biometric_mask = idf$file_biometric_mask

if (!all(file.exists(file_face_mask))) {

  res = ct_face_mask(
    file = file_nifti,
    mask = file_mask,
    skull_strip = FALSE
  )
  writenii(res, file_face_mask)

}


if (!all(file.exists(file_biometric_mask))) {

  res = ct_biometric_mask(
    file = file_nifti,
    mask = file_mask,
    skull_strip = FALSE
  )
  writenii(res, file_biometric_mask)

}
