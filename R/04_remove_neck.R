library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(freesurfer)
library(extrantsr)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))



mode = "_512"
# mode = ""
files = df[[paste0("file_nifti", mode, "_noneck")]]


iid = get_fold()



# for (iid in seq(nrow(df))) {
print(iid)
idf = df[iid,]
print(idf)

file_nifti = idf[[paste0("file_nifti", mode)]]
file_mask_neck = idf[[paste0("file_mask_neck", mode)]]
file_noneck = idf[[paste0("file_nifti", mode, "_noneck")]]

print(file_nifti)
print(file_noneck)

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
  
  img = readnii(img)
  thresh_img = mask_img(img, (img > lthresh & img < uthresh))
  message("Image thresholded")
  if (!any(c(thresh_img) > 0)) {
    stop("No positive values in the thresholded output!")
  }
  remover = "remove_neck"
  verbose = TRUE
  if (verbose) {
    message(paste0("# Removing Neck\n"))
  }
  L = list(file = thresh_img, 
           template.file = ss.template.file, 
           template.mask = ss.template.mask, 
           rep.value = 0, 
           verbose = verbose, 
           ret_mask = TRUE, swapdim = TRUE)
  message("List created")
  neck_mask = do.call(remover, args = L) > 0
  neurobase::writenii(neck_mask, file_mask_neck)
  
  add_value = 1024
  noneck = mask_img(img + add_value, neck_mask) - add_value
  neurobase::writenii(noneck, file_noneck)
}


if (
  grepl("512", mode) && !file.exists(idf$file_nifti_256_noneck)
) {
  res = resample_image(idf$file_nifti_512_noneck, 
                       parameters = c(256L, 256L, 256L),
                       parameter_type = "voxels", 
                       interpolator = "nearestneighbor")
  neurobase::writenii(res, idf$file_nifti_256_noneck)
}
