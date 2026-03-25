library(extrantsr)
library(tidyverse)
library(neurobase)
source(here::here("R/utils.R"))

df = readRDS(here::here("data", "nifti_image_dimensions.rds"))

iid = get_fold()

# for (iid in seq(nrow(df))) {
  idf = df[iid,]
  print(iid)
  
  file_nifti = idf$file_nifti
  file_mask = idf$file_mask
  file_ss = idf$file_ss
  d3 = idf$dim3
  
  
  res = resample_image(file_nifti, 
                       parameters = c(512L, 512L, d3), 
                       parameter_type = "voxels", 
                       interpolator = "nearestneighbor")
  neurobase::writenii(res, idf$file_nifti_512)
  
  
  res = resample_image(file_nifti, 
                       parameters = c(256L, 256L, 256L),
                       parameter_type = "voxels", 
                       interpolator = "nearestneighbor")
  neurobase::writenii(res, idf$file_nifti_256)
  # dim(res)
# }

