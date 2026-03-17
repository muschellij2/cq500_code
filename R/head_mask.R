# library(tidyverse)
# library(readr)
library(dplyr)
library(here)
library(ANTsRCore)
library(extrantsr)
setwd(here::here())

df = readr::read_rds("results/high_resolution_scans.rds")
# take out template
iter = 1

template_dir = file.path("template_creation", 
                         paste0("template_", iter - 1))
template_file = file.path(template_dir, 
                          "img.nii.gz")
template_ss = file.path(template_dir, 
                        "ss.nii.gz")
template_mask = file.path(template_dir, 
                          "mask.nii.gz")
img = antsImageRead(template_file)
cc = largest_component(img > -400 & img < 1000)
head_mask = filler(cc, fill_size = 13)
head_img = mask_img(img, head_mask)
inds = getEmptyImageDimensions(cc)
img = applyEmptyImageDimensions(img, inds = inds)

cc2 = largest_component(img > -400 & img < 1000)
