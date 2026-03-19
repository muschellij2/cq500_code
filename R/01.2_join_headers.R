library(tidyverse)
library(fs)
library(here)
library(purrr)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
dir_header = here::here("data", "header")
dir_header_wide = here::here("data", "header_wide")


iid = 1

df = df %>%
  filter(file.exists(file_header_wide))
x = df$file_header_wide
names(x) = x
res = purrr::map_df(x, readRDS, .progress = TRUE, .id = "file_header_wide")
res = res %>%
  left_join(df %>% select(id_patient, id, id_patient_short,
                          date, time, file_header_wide, dir_series))
res = res %>% tidyr::nest(header = -any_of(c("file_header_wide", "dir_series",
                                             "id_patient", "id", "id_patient_short",
                                             "date", "time")))
readr::write_rds(res, here::here("data", "dicom_header_data.rds"), compress = "xz")

