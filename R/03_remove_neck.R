library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(freesurfer)
library(extrantsr)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))

# df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
dir_noneck = here::here("data", "noneck")
dir_mask_neck = here::here("data", "neck_mask")


fs::dir_create(
  c(
    dir_noneck,
    dir_mask_neck
  )
)

df = df %>%
  filter(type == "ct") %>%
  mutate(
    stub = basename(file_nifti),
    id_patient = sub("_.*", "", stub),
    file_noneck = here::here(dir_noneck, stub),
    file_mask_neck = here::here(dir_mask_neck, stub),
    
  ) %>%
  select(-stub) %>%
  mutate(id = sub("_(ct|roi)", "", nii.stub(file_nifti, bn = TRUE) ))

iid = get_fold()

# for (iid in seq(nrow(df))) {
print(iid)
idf = df[iid,]

file_nifti = idf$file_nifti
file_mask_neck = idf$file_mask_neck
file_noneck = idf$file_noneck

if (!all(file.exists(c(file_noneck, file_mask_neck)))) {
  ss.template.file =
    system.file("scct_unsmooth_SS_0.01.nii.gz",
                package = "ichseg")
  ss.template.mask =
    system.file("scct_unsmooth_SS_0.01_Mask.nii.gz",
                package = "ichseg")
  
  lthresh = 0
  uthresh = 100
  img = file_nifti
  
  reorient = FALSE
  
  img = check_nifti(img, reorient = reorient)
  thresh_img = niftiarr(img, img * (img > lthresh & img < uthresh))
  if (!any(c(thresh_img) > 0)) {
    stop("No positive values in the thresholded output!")
  }
  thresh_img = oro.nifti::drop_img_dim(thresh_img)
  thresh = neurobase::checkimg(thresh_img)
  rm(thresh_img)
  remover = "remove_neck"
  verbose = TRUE
  if (verbose) {
    message(paste0("# Removing Neck\n"))
  }
  L = list(file = thresh, 
           template.file = ss.template.file, 
           template.mask = ss.template.mask, rep.value = 0, verbose = verbose, 
           ret_mask = TRUE, swapdim = TRUE)
  neck_mask = do.call(remover, args = L)
  neurobase::writenii(neck_mask, file_mask_neck)
  
  add_value = 1024
  noneck = mask_img(img + add_value, neck_mask) - add_value
  neurobase::writenii(neck_mask, file_noneck)
}
