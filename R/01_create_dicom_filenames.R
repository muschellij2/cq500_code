library(dplyr)
library(readr)
library(fs)
library(here)
library(tools)
library(tidyr)
library(lubridate)

id_df = read_csv(here::here("data/reads.csv"))
readr::stop_for_problems(id_df)
id_df = id_df %>% 
  mutate(id_patient = gsub("-", "", name)) %>% 
  mutate(id_patient_short = sub("CQ500CT", "", id_patient),
         num_patient_short = as.numeric(id_patient_short)) %>% 
  relocate(id_patient, id_patient_short, num_patient_short, .before = name)


#### Create DICOM Filename df
dir_dicom = here::here("data", "dicom")
dicom = list.files(
  path = dir_dicom,
  full.names = FALSE,
  recursive = TRUE,
  pattern = ".dcm$"
)
dicom = dicom[!grepl("/remove(d|)/", dicom)]
dicom = normalizePath(dicom, winslash = "/", mustWork = FALSE)

df = tibble(
  fname = basename(dicom),
  file = file.path(dir_dicom, dicom),
  ext_file = tolower(file_ext(fname)),
  sub_dir = dirname(dicom)
) %>%
  mutate(dir_series = dirname(file),
         dir_study = dirname(dir_series))



df = df %>%
  separate(sub_dir, sep = "/", into = c("id_patient", "id_study", "id_series"),
           remove = TRUE)
df = df %>% 
  mutate(id_patient = sub(" .*", "", id_patient),
         name_series = basename(dir_series),
         name_series = gsub("  ", " ", name_series),
         name_series = gsub(" ", "-", name_series),
         name_study = basename(dir_study),
         name_study = gsub("  ", " ", name_study),
         name_study = gsub(" ", "-", name_study),
  )
df = df %>% 
  mutate(
    stub = paste0(id_patient, "_", name_series),
  )



df = df %>%
  mutate(id_patient_short = sub("CQ500CT", "", id_patient),
         num_patient_short = as.numeric(id_patient_short))
stopifnot(!anyNA(df$num_patient_short))

# Observed IDs
obs_id_df = df %>%
  distinct(id_patient) %>%
  mutate(in_data = TRUE,
         obs_id_patient_short = sub("-.*", "", id_patient))
obs_id_df = id_df %>%
  mutate(in_ids = TRUE) %>%
  full_join(obs_id_df) %>%
  tidyr::replace_na(list(in_ids = FALSE, in_data = FALSE)) %>%
  mutate(id_patient_short = sub("-.*", "", id_patient))

# seeing if we find IDs with different sites
bad_ids = obs_id_df %>%
  arrange(id_patient) %>%
  filter(!in_data | !in_ids) %>%
  select(id_patient, id_patient_short, in_data, in_ids)
bad_ids = obs_id_df %>%
  filter(id_patient_short %in% bad_ids$id_patient_short) %>%
  select(id_patient, in_data, in_ids) %>%
  mutate(id_patient_short = sub("-.*", "", id_patient))  %>%
  arrange(id_patient)
#!!! Temporary - 6504 data missing
stopifnot(nrow(bad_ids) <= 1)
missing_ids = setdiff(y = df$id_patient, id_df$id_patient)
bad_ids = setdiff(df$id_patient, id_df$id_patient)
# none are bad, only some missing
stopifnot(length(bad_ids) == 0)







#### Naming NIfTIs ####
dirs_to_create = c("nifti", 
                   "brain_extracted", "brain_mask",
                   "brain_extracted_brainchop", "brain_mask_brainchop",
                   "brain_extracted_hdctbet", "brain_mask_hdctbet",
                   "brain_extracted_synth", "brain_mask_synth",
                   "brain_mask_ctbet", "brain_extracted_ctbet",
                   "brain_extracted_original", "brain_mask_original",
                   
                   "brain_extracted_512", "brain_mask_512",
                   "brain_extracted_brainchop_512", "brain_mask_brainchop_512",
                   "brain_extracted_hdctbet_512", "brain_mask_hdctbet_512",
                   "brain_extracted_synth_512", "brain_mask_synth_512",
                   "brain_mask_ctbet_512", "brain_extracted_ctbet_512",
                   "brain_extracted_original_512", "brain_mask_original_512",
                   
                   
                   "noneck_brain_extracted_512", "noneck_brain_mask_512",
                   "noneck_brain_extracted_brainchop_512", "noneck_brain_mask_brainchop_512",
                   "noneck_brain_extracted_hdctbet_512", "noneck_brain_mask_hdctbet_512",
                   "noneck_brain_extracted_synth_512", "noneck_brain_mask_synth_512",
                   "noneck_brain_mask_ctbet_512", "noneck_brain_extracted_ctbet_512",
                   "noneck_brain_extracted_original_512", "noneck_brain_mask_original_512",
                   
                   "header", "header_wide",
                   "nifti_256", "nifti_512",
                   "noneck", "neck_mask",
                   "noneck_512", "neck_mask_512",
                   "noneck_256", "neck_mask_256"
)

dirs = here::here("data", dirs_to_create)
fs::dir_create(dirs)
names(dirs) = dirs_to_create

rs_dirs_to_create = c("image_nifti", "image_ss")
rs_dirs = here::here("results", rs_dirs_to_create)
names(rs_dirs) = rs_dirs_to_create

dirs = as.list(dirs)
dirs = c(dirs, as.list(rs_dirs))

df = df %>%
  mutate(
    fname = paste0(stub, ".nii.gz"),
    file_nifti = file.path(dirs$nifti, fname),
    file_nifti_256 = file.path(dirs$nifti_256, fname),
    file_nifti_512 = file.path(dirs$nifti_512, fname),
  ) %>%
  select(-fname)


df = df %>%
  mutate(
    stub = basename(file_nifti),
    # base_stub = sub("_ct", "", stub),
    base_stub = stub,
    file_ss = here::here(dirs$brain_extracted, base_stub),
    file_mask = here::here(dirs$brain_mask, base_stub),
    
    file_ss_brainchop = here::here(dirs$brain_extracted_brainchop, base_stub),
    file_mask_brainchop = here::here(dirs$brain_mask_brainchop, base_stub),
    
    file_ss_original = here::here(dirs$brain_extracted_original, stub),
    file_mask_original = here::here(dirs$brain_mask_original, stub),
    
    file_ss_hdctbet = here::here(dirs$brain_extracted_hdctbet, stub),
    file_mask_hdctbet = here::here(dirs$brain_mask_hdctbet, stub),
    
    
    file_ss_synth = here::here(dirs$brain_extracted_synth, stub),
    file_mask_synth = here::here(dirs$brain_mask_synth, stub),
    
  
    file_ss_512 = here::here(dirs$brain_extracted_512, base_stub),
    file_mask_512 = here::here(dirs$brain_mask_512, base_stub),
    
    file_ss_brainchop_512 = here::here(dirs$brain_extracted_brainchop_512, base_stub),
    file_mask_brainchop_512 = here::here(dirs$brain_mask_brainchop_512, base_stub),
    
    file_ss_original_512 = here::here(dirs$brain_extracted_original_512, stub),
    file_mask_original_512 = here::here(dirs$brain_mask_original_512, stub),
    
    file_ss_hdctbet_512 = here::here(dirs$brain_extracted_hdctbet_512, stub),
    file_mask_hdctbet_512 = here::here(dirs$brain_mask_hdctbet_512, stub),
    
    
    file_ss_synth_512 = here::here(dirs$brain_extracted_synth_512, stub),
    file_mask_synth_512 = here::here(dirs$brain_mask_synth_512, stub),
    
    
    file_noneck_ss_512 = here::here(dirs$noneck_brain_extracted_512, base_stub),
    file_noneck_mask_512 = here::here(dirs$noneck_brain_mask_512, base_stub),
    
    file_noneck_ss_brainchop_512 = here::here(dirs$noneck_brain_extracted_brainchop_512, base_stub),
    file_noneck_mask_brainchop_512 = here::here(dirs$noneck_brain_mask_brainchop_512, base_stub),
    
    file_noneck_ss_original_512 = here::here(dirs$noneck_brain_extracted_original_512, stub),
    file_noneck_mask_original_512 = here::here(dirs$noneck_brain_mask_original_512, stub),
    
    file_noneck_ss_hdctbet_512 = here::here(dirs$noneck_brain_extracted_hdctbet_512, stub),
    file_noneck_mask_hdctbet_512 = here::here(dirs$noneck_brain_mask_hdctbet_512, stub),
    
    
    file_noneck_ss_synth_512 = here::here(dirs$noneck_brain_extracted_synth_512, stub),
    file_noneck_mask_synth_512 = here::here(dirs$noneck_brain_mask_synth_512, stub),
    
    
    file_noneck = here::here(dirs$noneck, stub),
    file_mask_neck = here::here(dirs$neck_mask, stub),
    
    file_noneck_512 = here::here(dirs$noneck_512, stub),
    file_mask_neck_512 = here::here(dirs$neck_mask_512, stub),
    
    file_noneck_256 = here::here(dirs$noneck_256, stub),
    file_mask_neck_256 = here::here(dirs$neck_mask_256, stub),
    
    png = paste0(neurobase::nii.stub(base_stub), ".png"),
    png = ifelse(is.na(base_stub), NA_character_, png),
    
    file_image_nifti = here::here(dirs$image_nifti, png),
    file_image_nifti = sub("_ct", "", file_image_nifti),
    file_image_ss = here::here(dirs$image_ss, png)
  ) %>%
  select(-stub, -base_stub, -png)

id_df = df %>%
  distinct(id_patient) %>%
  mutate(fold = as.numeric(factor(id_patient)))
df = left_join(df, id_df)
df = df %>% 
  mutate(type = "ct")

dir_header = here::here("data", "header")
dir_header_wide = here::here("data", "header_wide")
fs::dir_create(c(dir_header, dir_header_wide))
df = df %>%
  mutate(
    file_header = neurobase::nii.stub(file_nifti, bn = TRUE),
    file_header = paste0(file_header, ".rds"),
    file_header = here::here(dir_header, file_header),
    file_header_wide = sub("/header/", "/header_wide/", file_header)
  )
write_rds(df, here::here("data", "dicom_filenames.rds"))


df_study = df %>%
  select(id_patient, type, id_patient_short, num_patient_short,
         id_study, dir_study, dir_series, fold,
         starts_with("file_")) %>%
  distinct()
write_rds(df_study, here::here("data", "dicom_study_filenames.rds"))


# wide = df_study %>%
#   select(starts_with("id"), fold, dir_study, type,
#          dir_series, file_nifti, 
#          file_ss, 
#          file_image_nifti, file_image_ss) %>%
#   pivot_wider(names_from = type,
#               values_from = c(dir_series, file_nifti, 
#                               file_ss, 
#                               file_image_nifti, file_image_ss))
# wide = wide %>%
#   select(-file_ss_roi, -file_coreg_transforms_roi,
#          -file_image_nifti_roi,
#          -file_image_ss_roi)
# wide = wide %>%
#   rename(
#     file_ss = file_ss_ct,
#     file_coreg_transforms = file_coreg_transforms_ct,
#     file_image_nifti = file_image_nifti_ct,
#     file_image_ss = file_image_ss_ct,
#   )
# write_rds(wide, here::here("data", "dicom_study_filenames_wide.rds"))

