library(tidyverse)
library(neurobase)
library(extrantsr)
df = readRDS(here::here("data", "nifti_image_dimensions.rds"))
bad = df %>% 
  filter(dim1 != 512 | dim2 != 512)
img = bad$file_nifti[1]
d3 = bad$dim3[1]
res = resample_image(img, c(256L, 256L, 256L),
                     parameter_type = "voxels", interpolator = "nearestneighbor")
dim(res)
### NO - does min/max scaling on intensities
# library(freesurfer)
# outfile = tempfile(fileext = ".nii.gz")
# res = mri_convert(img, outfile, opts = "--conform")
# img = readnii(outfile)
# range(img)
# dim(img)
