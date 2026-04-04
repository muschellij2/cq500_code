library(neurobase)
library(tibble)
library(dplyr)
library(fs)
source(here::here("R/utils.R"))
source(here::here("R/helper_functions.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))

dirs = list.dirs(path = "data", full.names = FALSE, recursive = FALSE)
dirs = dirs[grepl("noneck_brain_mask.*", dirs)]

eg = expand.grid(
  dir = dirs,
  fname = basename(df$file_nifti),
  stringsAsFactors = FALSE
) %>% 
  mutate(
    file_mask = here::here("data", dir, fname),
    size = case_when(
      grepl("512", dir) ~ "512",
      grepl("256|convert|conform", dir) ~ "256"
    ),
    file_nifti = here::here("data", paste0("noneck_", size), fname)
  )
stopifnot(!anyNA(eg$size))

df = eg %>% as_tibble()
df = df %>%
  filter(file.exists(file_nifti))
df = df %>% 
  mutate(
    stub = nii.stub(file_nifti, bn = TRUE),
    png = here::here("results", basename(dir), paste0(stub, ".png"))
  )
fs::dir_create(unique(dirname(df$png)), recursive = TRUE, showWarnings = FALSE)
df = df %>% 
  select(file_nifti, file_mask, stub, png) 
df = df %>% 
  tidyr::nest(.by = file_nifti)


file_empty = function(file) {
  !file.exists(file) |
    (file.size(file) == 0 & file.exists(file))
}

iid = get_fold()

# for (iid in seq(nrow(df))) {
print(iid)
idf = df[iid,]


file_nifti = idf$file_nifti
print(file_nifti)
print(data)
data = idf$data[[1]]
if (any(file_empty(data$png))) {
  img = window_img(file_nifti)
  iimg = 1
  for (iimg in seq(nrow(data))) {
    file_mask = data$file_mask[iimg]
    pngname = data$png[iimg]
    stub = data$stub[iimg]
    if (file.exists(file_mask)) {
      roi = readnii(file_mask) > 0
      create_ortho(img, roi, stub, pngname = pngname)
      
    }
  }
}

