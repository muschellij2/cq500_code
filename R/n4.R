library(dplyr)
library(RNifti)
library(neurobase)
library(extrantsr)
library(here)
setwd(here::here())

df = readr::read_rds("results/high_resolution_scans.rds")

# df = readr::read_rds("results/directory_df.rds")
df = df %>%
  mutate(ssmask = sub("[.]nii", "_Mask.nii", ssfile))

df = df %>%
  filter(file.exists(outfile) & file.exists(ssfile)) %>%
  mutate(n4 = file.path("n4", basename(ssfile)))


uids = sort(unique(df$id))
n_ids = length(uids)
# df = run_df
iscen = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iscen)) {
  # iscen = 156
  iscen = 1
}
# id = uids[iscen]
# idf = df[ df$id %in% id, ]

idf = df[ iscen, ]

if (!file.exists(idf$n4)) {
  
  ss = ANTsRCore::antsImageRead(idf$ssfile)
  mask = ANTsRCore::antsImageRead(idf$ssmask)
  ss = ANTsRCore::maskImage(ss + 1025, img.mask = mask)


  bc = bias_correct_ants(
    file = ss,
    correction = "N4",
    mask = mask,
    convergence = list(iters = rep(200, 4), tol = 1e-07)
  )
  if (all(as.array(bc) == 0)) {
    stop("Bias corrected image is empty")
  }
  bc[bc < 0 ] = 0
  bc =  ANTsRCore::maskImage(bc - 1025, img.mask = mask)
  write_nifti(bc, idf$n4)
  # bc = ANTsRCore::maskImage()
  # bc = bias_correct(
  #   file = idf$ssfile,
  #   correction = "N4",
  #   retimg = FALSE,
  #   outfile = idf$n4,
  #   mask = idf$ssmask,
  #   convergence = list(iters = rep(200, 4), tol = 1e-07)
  # )
}
