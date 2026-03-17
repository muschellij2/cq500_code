# library(tidyverse)
# library(readr)
library(dplyr)
library(RNifti)
library(fslr)
library(here)
library(extrantsr)
setwd(here::here())

reads = readr::read_csv("data/reads.csv")
reads = reads %>% 
  mutate(id = gsub("-", "", name))
rs = reads %>% 
  select(-name, -id, -Category) %>% 
  rowSums()
no_path = reads[rs == 0, ]

checks = readr::read_csv("code/checking_cq500_ss.csv")
checks = checks %>% 
  mutate(
    stub = sub(".png", "", ID),
    lower_stub = tolower(stub)
  )

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  filter(id %in% no_path$id)
df = df %>% 
  mutate(
    hdr = file.path("hdr", 
                    paste0(stub, ".rds")),
    sub_hdr = file.path("sub_hdr", 
                        paste0(stub, ".rds")))
df = df[ file.exists(df$outfile), ]
hdrs = pbapply::pblapply(df$outfile, niftiHeader)

pdim = t(sapply(hdrs, `[[`, "pixdim"))
pdim = pdim[, 2:4]
colnames(pdim) = paste0("pixdim", 1:3)

dims = t(sapply(hdrs, `[[`, "dim"))
dims = dims[, 2:4]
colnames(dims) = paste0("dim", 1:3)

df = cbind(df, pdim, dims)
df$zmm = df$pixdim3 * df$dim3
df = df %>% 
  mutate(lower_stub = tolower(stub))

high_res = df %>% 
  filter(pixdim3 <= 0.7)

# full head
high_res = high_res %>% 
  filter(zmm >= 140)

high_res = high_res %>% 
  arrange(zmm)

length(unique(high_res$id))

high_res[ !high_res$stub %in% checks$stub,]

high_res[ !high_res$lower_stub %in% checks$lower_stub,]


high_res = high_res %>%
  mutate(n4 = file.path("n4", basename(ssfile)))

high_res = high_res %>% 
  select(-stub) %>% 
  left_join(checks)

high_res = high_res %>% 
  filter(full_head > 0 & ss > 0)
high_res = high_res %>% 
  filter(!grepl("post-contrast", tolower(series_name)))
high_res = high_res %>% 
  filter(!series_name %in% c("CT-Thin-Contrast", "CT-C-THIN", 
                             "CT-I-To-S"))
length(unique(high_res$id))
dup_id = high_res %>% 
  count(id) %>% 
  filter(n > 1)
high_res[ high_res$id %in% dup_id$id,]
high_res = high_res %>% 
  mutate(voxres = pixdim1 * pixdim2 * pixdim3) %>% 
  arrange(id, voxres) %>% 
  group_by(id) %>% 
  dplyr::slice(1)
high_res = high_res %>% 
  ungroup()

path_high_res = readLines("data/remove_high_resolution.txt")
stopifnot(all(path_high_res %in% high_res$stub))
high_res = high_res %>% 
  filter(!stub %in% path_high_res)

readr::write_rds(high_res, 
                 path = "results/high_resolution_scans.rds")
readr::write_csv(high_res, 
                 path = "results/high_resolution_scans.csv")

#########################################
# Getting high and low z-dimensions
#########################################
hlow = df %>% 
  filter(id %in% high_res$id) %>% 
  mutate(high = stub %in% high_res$stub)
stopifnot(nrow(high_res) == sum(hlow$high))

hlow[ !hlow$stub %in% checks$stub,]
hlow[ !hlow$lower_stub %in% checks$lower_stub,]

hlow = hlow %>% 
  select(-stub) %>% 
  left_join(checks)

hlow = hlow %>% 
  filter(full_head > 0 & ss > 0) %>% 
  filter(!grepl("post-contrast", tolower(series_name))) %>% 
  filter(!series_name %in% 
           c("CT-Thin-Contrast", "CT-C-THIN", 
             "CT-I-To-S", "CT-PRE-CONTRAST-BONE"))  

# Keep full heads
hlow = hlow %>% 
  filter(zmm >= 140)
# Categorize slice thickness
hlow = hlow %>% 
  mutate(pd_type = cut(pixdim3, breaks = c(0, 2, 4, 6),
                       include.lowest = TRUE))
stopifnot(!any(is.na(hlow$pd_type)))

# Keep only those with thin and thick scans
hlow = hlow %>% 
  filter(pixdim3 < 1 | (pixdim3 > 4 & pixdim3 < 5.5))
hlow = hlow %>% 
  group_by(id) %>% 
  mutate(n_types = length(unique(pd_type)))
stopifnot(max(hlow$n_types) == 2)
hlow = hlow %>% 
  filter(n_types == 2)
readr::write_rds(hlow, 
                 path = "results/both_resolution_scans.rds")
readr::write_csv(hlow, 
                 path = "results/both_resolution_scans.csv")

# "nifti/CQ500CT389_CT-C-THIN.nii.gz" 

sel = high_res %>% 
  filter(dim1 == 512 & dim2 == 512 & 
           pixdim3 <= 0.55 & pixdim3 >= 0.45)

template = sel %>% 
  filter(grepl("CT100", id))
img = template$outfile
ss = template$ssfile
mask = sub(".nii", "_Mask.nii", ss)



# template CQ500CT100_CT-Plain-THIN.png


# img = readNifti(high_res$outfile[1])
# ortho2(img, window = c(0, 100))
