library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(freesurfer)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))

# df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
dir_ss = here::here("data", "brain_extracted")
dir_mask = here::here("data", "brain_mask")

dir_ss_synth = here::here("data", "brain_extracted_synth")
dir_mask_synth = here::here("data", "brain_mask_synth")

dir_mask_hdctbet = here::here("data", "brain_mask_hdctbet")
dir_ss_hdctbet = here::here("data", "brain_extracted_hdctbet")

dir_mask_ctbet = here::here("data", "brain_mask_ctbet")
dir_ss_ctbet = here::here("data", "brain_extracted_ctbet")
# dir_ss_hdctbet = here::here("CT_BET", "predictions")

dir_ss_original = here::here("data", "brain_extracted_original")
dir_mask_original = here::here("data", "brain_mask_original")

fs::dir_create(
  c(
    dir_ss,
    dir_mask,
    dir_ss_synth,
    dir_mask_synth,
    dir_ss_original,
    dir_mask_original
  )
)

df = df %>%
  filter(type == "ct") %>%
  mutate(
    stub = basename(file_nifti),
    id_patient = sub("_.*", "", stub),
    file_ss = here::here(dir_ss, stub),
    file_mask = here::here(dir_mask, stub),
    file_ss_original = here::here(dir_ss_original, stub),
    file_mask_original = here::here(dir_mask_original, stub),

    file_ss_hdctbet = here::here(dir_ss_hdctbet, stub),

    file_ss_synth = here::here(dir_ss_synth, stub),
    file_mask_synth = here::here(dir_mask_synth, stub)

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

file_mask_original = idf$file_mask_original
file_ss_original = idf$file_ss_original

file_mask_synth = idf$file_mask_synth
file_ss_synth = idf$file_ss_synth

if (!all(file.exists(c(file_ss, file_mask)))) {
  ss.template.file =
    system.file("scct_unsmooth_SS_0.01.nii.gz",
                package = "ichseg")
  ss.template.mask =
    system.file("scct_unsmooth_SS_0.01_Mask.nii.gz",
                package = "ichseg")

  ss = CT_Skull_Strip_robust(
    img = file_nifti,
    retimg = FALSE,
    keepmask = TRUE,
    template.file = ss.template.file,
    template.mask = ss.template.mask,
    # remover = "double_remove_neck",
    outfile = file_ss,
    maskfile = file_mask)
}

if (!all(file.exists(c(file_ss_original, file_mask_original)))) {

  # original
  ss = CT_Skull_Strip(
    img = file_nifti,
    retimg = FALSE,
    keepmask = TRUE,
    # remover = "double_remove_neck",
    outfile = file_ss_original,
    maskfile = file_mask_original)
}


if (!all(file.exists(c(file_ss_synth, file_mask_synth)))) {

  res = freesurfer::mri_synthstrip(
    file = file_nifti,
    retimg = FALSE,
    outfile = file_ss_synth,
    maskfile = file_mask_synth
  )
  if (res > 0 && !file.exists(file_ss_synth)) {
    tfile = tempfile(fileext = ".nii.gz")
    file.copy(file_nifti, tfile)
    img_run = fslr::fslorient(tfile, opts = "-copyqform2sform")
    res = freesurfer::mri_synthstrip(
      file = img_run,
      retimg = FALSE,
      outfile = file_ss_synth,
      maskfile = file_mask_synth
    )
  }
}

# }
