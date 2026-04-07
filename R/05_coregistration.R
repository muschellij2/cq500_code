library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(extrantsr)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames_wide.rds"))
dir_ss = here::here("data", "brain_extracted")
dir_mask = here::here("data", "brain_mask")

replace_here = function(x) {
  here::here(sub("/Users/johnmuschelli/Desktop/mistie_3/", "", x))
}
df = df %>%
  mutate(
    across(c(starts_with("file"), starts_with("dir")), replace_here)
  )

df = df %>%
  mutate(
    stub = basename(file_nifti_ct),
    file_ss = here::here(dir_ss, stub),
    file_mask = here::here(dir_mask, stub),
  ) %>%
  select(-stub)


sdf = split(df, df$id_patient)

ids = names(sdf)
iid = get_fold()


# for (iid in seq_along(ids)) {
print(iid)
print(names(sdf)[iid])
iid_df = sdf[[iid]]

for (irow in seq(nrow(iid_df))) {
  idf = iid_df[irow,]
  file_nifti_ct = idf$file_nifti_ct
  print(file_nifti_ct)
  file_nifti_roi = idf$file_nifti_roi
  file_coreg_ct = idf$file_coreg_ct
  file_coreg_roi = idf$file_coreg_roi
  file_coreg_transforms = nii.stub(idf$file_coreg_transforms)
  file_ss = idf$file_ss

  if (!all(file.exists(c(file_coreg_ct, file_coreg_roi)))) {
    reg = registration(
      filename = file_ss,
      skull_strip = FALSE,
      correct = FALSE,
      retimg = TRUE,
      outfile = file_coreg_ct,
      other.files = file_nifti_roi,
      other.outfiles = file_coreg_roi,
      other_interpolator = "NearestNeighbor",
      template.file = idf$file_ss_template,
      interpolator = "Linear",
      typeofTransform = "Rigid",
      remove.warp = FALSE,
      outprefix = file_coreg_transforms
    )

  } else {
    # res = readnii(file_nifti, drop_dim = FALSE)
  }
}
# }
