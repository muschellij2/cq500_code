# library(tidyverse)
# library(readr)
library(dplyr)
library(dcm2niir)
library(tibble)
library(tidyr)
library(neurobase)
library(ichseg)
library(dcmtk)
library(dcmsort)
library(here)
setwd(here::here())

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  mutate(
    hdr = file.path("hdr", 
                    paste0(stub, ".rds")),
    sub_hdr = file.path("sub_hdr", 
                        paste0(stub, ".rds")))
# 
# run_df = df %>%
#   filter(!(file.exists(outfile) &
#              file.exists(ssfile) &
#              file.exists(ss400) &
#              file.exists(smooth_robust)))
# run_df = run_df %>%
#   filter(n > 1)
# df = run_df
iscen = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iscen)) {
  iscen = 1
}


# for (iscen in seq(nrow(df))) {
  print(iscen)
  idf = df[iscen, ]
  if (!file.exists(idf$hdr)) {
    hdr = read_dicom_header(path = idf$dir, 
                            recursive = TRUE)
    readr::write_rds(hdr, path = idf$hdr)
  } else {
    hdr = readr::read_rds(idf$hdr)
  }
  if (!file.exists(idf$sub_hdr)) {
    sub_hdr = dcmsort::subset_hdr(hdr)
    readr::write_rds(sub_hdr, path = idf$sub_hdr)
  }
  if (!file.exists(idf$outfile)) {
    img = ct_dcm2nii(basedir = idf$dir)
    writenii(img, idf$outfile)
  }
  if (!file.exists(idf$ssfile)) {
    ss = CT_Skull_Strip(idf$outfile, 
                        outfile = idf$ssfile)
  }
  if (!file.exists(idf$ss400)) {
    ss400 = CT_Skull_Strip(idf$outfile, 
                           outfile = idf$ss400,
                           uthresh = 400)
  }
  
  if (!file.exists(idf$smooth_robust)) {
    smooth_robust = CT_Skull_Strip_robust(
      idf$outfile, 
      outfile = idf$smooth_robust,
      smooth_before_threshold = TRUE,
      smooth.factor = 1,
      remove.neck = TRUE,
      remover = "remove_neck",
      recog = FALSE,
      nvoxels = 0)
  }
  
# }
# }

