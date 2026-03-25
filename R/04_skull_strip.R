library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(freesurfer)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))


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
