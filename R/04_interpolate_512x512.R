library(extrantsr)
library(tidyverse)
df = readRDS(here::here("data", "nifti_image_dimensions.rds"))
bad = df %>% 
  filter(dim1 != 512 | dim2 != 512)
img = bad$file_nifti[1]
d3 = bad$dim3[1]
res = resample_image(img, c(512, 512, d3), 
                     parameter_type = "voxels", interpolator = "nearestneighbor")
