library(here)
library(dplyr)
library(tidyr)
setwd(here::here())
reads = readr::read_csv("data/reads.csv")
reads = reads %>% 
  mutate(name = gsub("-", "", name)) %>% 
  rename(id = name)


dcm_file = "results/all_dicoms.txt"
if (!file.exists(dcm_file)) {
  dcms = list.files(pattern = ".dcm$", recursive = TRUE, 
                    path = "dcm", full.names = TRUE)
  writeLines(dcms, con = dcm_file)
} else {
  dcms = readLines(dcm_file)
}
all_dirs = unique(dirname(dcms))

writeLines(all_dirs, con = "results/all_directories.txt")

dcm_df = tibble(
  dcm = dcms,
  dir = dirname(dcms)
)
dcm_df = dcm_df %>% 
  group_by(dir) %>% 
  tally()

df = tibble(
  dir = all_dirs
) %>% 
  separate(dir, 
           into = c("base", "id", "other"), 
           remove = FALSE, sep = "/", extra = "drop") %>% 
  select(-other, -base) %>%
  mutate(id = sub(" .*", "", id ),
         series_name = basename(dir),
         series_name = gsub("  ", " ", series_name),
         series_name = gsub(" ", "-", series_name),
         stub = paste0(id, "_", series_name),
         outdir = "nifti",
         outfile = file.path(outdir, paste0(stub, ".nii.gz")),
         ssfile = file.path("ss", basename(outfile)),
         ss400 = file.path("ss400",  basename(outfile)),
         smooth_robust = file.path("smooth_robust", basename(outfile)),
         regfile = file.path("reg", basename(outfile)),
         smooth_regfile = file.path("smooth_reg", basename(outfile)),
         reg400 = file.path("reg400",  basename(outfile))         
  )
df = left_join(df, dcm_df)
readr::write_rds(df, "results/directory_df.rds", compress = "xz")
xdf = df

df = xdf
df = df %>% 
  select(id, series_name, stub, outfile, 
         smooth_robust, smooth_regfile, n) %>% 
  mutate(smooth_robust = sub("[.]nii", "_Mask.nii", smooth_robust)) %>% 
  rename(img = outfile,
         brain_mask = smooth_robust, 
         registered = smooth_regfile) %>% 
  left_join(reads)
  
readr::write_csv(df, "results/directory_df.csv.gz")
