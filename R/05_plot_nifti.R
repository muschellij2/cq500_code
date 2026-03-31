library(neurobase)
library(ichseg)
library(tibble)
library(dplyr)
library(fs)
library(oro.nifti)
library(png)
library(grid)
library(gridExtra)
library(tidyr)
source(here::here("R/utils.R"))
source(here::here("R/helper_functions.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))

print(nrow(df))


iid = get_fold()

# df = df[1:100,]
for (iid in seq(nrow(df))) {
  print(iid)
  idf = df[iid,]
  
  file_nifti = idf$file_nifti_512
  file_neck_mask = idf$file_mask_neck_512
  
  file_image_nifti = idf$file_image_nifti
  dir_study = nii.stub(idf$file_nifti, bn = TRUE)
  dir_study = gsub("_", "\n", dir_study)
  
  if (!file.exists(file_image_nifti) &&
      file.exists(file_neck_mask)) {
    img = readnii(file_nifti)
    img = window_img(img, c(0, 100))
    roi = readnii(file_neck_mask) 
    # roi = roi > 0
    roi = roi == 0
    # expand the image a bit for slices
    # overlay_file = create_overlay(img, roi)
    ortho_file = create_ortho(img, roi, dir_study, pngname = file_image_nifti)
    
    # img1 <-  rasterGrob(as.raster(readPNG(overlay_file)), interpolate = FALSE)
    # img2 <-  rasterGrob(as.raster(readPNG(ortho_file)), interpolate = FALSE)
    # png(file_image_nifti, res = 300, width = 2000, height = 1000)
    # grid.arrange(img1, img2, ncol = 2)
    # dev.off()
  } else {
    # res = readnii(file_nifti, drop_dim = FALSE)
  }
  
}
