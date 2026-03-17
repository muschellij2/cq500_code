# library(tidyverse)
# library(readr)
pbapply::pboptions(type = "timer")
library(dplyr)
library(RNifti)
library(fslr)
library(here)
library(ANTsRCore)
library(extrantsr)
setwd(here::here())

source(file.path("code", "make_template.R"))

df = readr::read_rds("results/high_resolution_scans.rds")
df$maskfile = sub(".nii", "_Mask.nii", df$ssfile)
df$mask_vol = NA

for ( i in 1:nrow(df)) {
  print(i)
  img = readNifti(df$maskfile[i])
  s = sum(img) * voxres(img, units = "cm")
  df$mask_vol[i] = s
  print(s)
  rm(img)
}
