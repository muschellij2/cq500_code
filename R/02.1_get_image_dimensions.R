library(tibble)
library(dplyr)
library(ANTsRCore)
library(tidyr)
source(here::here("R/utils.R"))
df = readr::read_rds(here::here("data", "dicom_study_filenames.rds"))
df_full = df
df = df %>% 
  filter(file.exists(file_nifti))

adim = function(file) {
  x = ANTsRCore::AntsImageHeaderInfo(file)$dimensions
  mat = as.data.frame(t(x))
  colnames(mat) = paste0("dim", 1:3)
  mat$file_nifti = file
  mat
}
results = purrr::map_df(df$file_nifti, adim, .progress = TRUE)

df = full_join(df_full, results)
ct = df %>% filter(type == "ct")

readr::write_rds(df, here::here("data", "nifti_image_dimensions.rds"))

# long = df %>%
#   pivot_longer(
#     cols = starts_with("dim"),
#     names_to = "dimension",
#     values_to = "value"
#   ) %>%
#   mutate(stub = nii.stub(file_nifti, bn = TRUE),
#          stub = sub("_(ct|roi)", "", stub))
# # Save the long format data
# long = long %>%
#   group_by(stub, dimension) %>%
#   summarise(
#     n_value = n_distinct(value),
#     n = n(),
#     .groups = "drop"
#   )
# long %>%
#   filter(!(n_value == 1 & n == 2))
# 
# df = readr::read_rds(here::here("data", "nifti_image_dimensions.rds"))
# df512 = df %>%
#   filter(type == "ct") %>%
#   filter(dim1 == 512, dim2 == 512)
# 
# df512 = df512 %>%
#   mutate(
#     ctbet = here::here(
#       "CT_BET/results_folder/unet_CT_SS_202564_16627/predictions",
#       basename(file_nifti)
#     ),
#     fe = file.exists(ctbet)
#   )

