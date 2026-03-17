library(dplyr)
library(readr)
library(fs)
library(here)
library(tools)
library(tidyr)
library(lubridate)

id_df = readLines(here::here("data/mistie_3_ids.txt"))
id_df = tibble(id_patient = id_df) %>%
  tidyr::separate(id_patient, into = c("id_patient_short", "id_site"),
                  sep = "-", remove = FALSE)

#### Create DICOM Filename df
dir_dicom = here::here("data", "dicom")
dicom = list.files(
  path = dir_dicom,
  full.names = FALSE,
  recursive = TRUE
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
  mutate(id_patient_short = sub("-.*", "", id_patient),
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


check = df %>%
  distinct(id_patient_short, dir_study, dir_series) %>%
  count(id_patient_short, dir_study) %>%
  filter(n != 2)
stopifnot(all(check$id_patient_short %in% c("6313", "6504")))
#!!! Temporary - 6313 has different studies
# df = df %>%
#   filter(!basename(id_study) %in% c("6313-327_CT_20160414_053848218000"))

# Seeing if you the same study in different folders
# for example 20131229_1702 and 20131229_170233455
#!!!
check = df %>%
  distinct(id_patient, id_patient_short, dir_study, id_study) %>%
  separate(id_study, into = c("id_patient_from_study",
                              "type_remove", "date", "time_original"), sep = "_",
           remove = FALSE) %>%
  select(-id_patient_from_study, -type_remove) %>%
  mutate(
    date = ymd(date),
    id_study = sub("_(CT|ROI)_", "_", id_study),
    date_char = format(date, format = "%Y%m%d"),
    time_char = substr(time_original, 1, 4)
  )
check = check %>%
  select(id_patient, dir_study, id_study, date_char, time_char) %>%
  mutate(
    id = paste0(id_patient, "_", date_char, "_", time_char),
  )
check = check %>%
  group_by(id) %>%
  mutate(n = n_distinct(dir_study)) %>%
  filter(n>1)

stopifnot(nrow(check) == 0)
# if (nrow(check) > 0) {
#   readr::write_csv(check, here::here("data/duplicate_folders.csv"))
# ## others have issues with dupes - waiing on Paul/Nathan
# df = df %>%
# filter(!dir_study %in% check$dir_study)
# }

# if there is no extension, make sure it's one of the odd ones
no_dcm = df %>%
  filter(is.na(ext_file) | !ext_file %in% c("dcm"))
stopifnot(all(grepl("^(0001|IM-)", no_dcm$fname)))

#### Separate Series information to Check ####
df = df %>%
  separate(id_series, into = c("id_patient_from_series",
                               "type", "date", "time"), sep = "_",
           remove = FALSE)
df = df %>%
  mutate(id_patient_from_series = gsub(" ", "", id_patient_from_series))
diff_id_df = df %>%
  filter(id_patient != id_patient_from_series)
diff_id_df = diff_id_df %>%
  select(id_patient, id_patient_from_series, id_series)
stopifnot(nrow(diff_id_df) == 0)
# need to keep type from this, not the rest, just for check
df = df %>%
  select(-id_patient_from_series, -date, -time)

#### Separate Study information for naming ####
df = df %>%
  separate(id_study, into = c("id_patient_from_study",
                              "type_remove", "date", "time_original"), sep = "_",
           remove = FALSE)
df = df %>%
  mutate(id_patient_from_study = gsub(" ", "", id_patient_from_study))
diff_id_df = df %>%
  filter(id_patient != id_patient_from_study)
diff_id_df = diff_id_df %>%
  select(id_patient, id_patient_from_study, id_study)
stopifnot(nrow(diff_id_df) == 0)
df = df %>%
  select(-id_patient_from_study, -type_remove)

# Convert to proper formats
df = df %>%
  mutate(
    date = ymd(date),
    time = substr(time_original, 1, 4),
    time = paste0(substr(time, 1, 2), ":", substr(time, 3, 4),
                  ":00")
  )

df = df %>%
  mutate(
    time = hms::as_hms(time)
  )

roi_df = df %>%
  distinct(id_study, type) %>%
  group_by(id_study) %>%
  summarise(have_both = all(c("CT", "ROI") %in% type))
stopifnot(all(roi_df$have_both))

#### Naming NIfTIs ####

dirs_to_create = c("nifti", "coregistered", "template_registered",
                   "brain_extracted", "brain_mask", "coregistered_transforms")
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
    id_study = sub("_(CT|ROI)_", "_", id_study),
    date_char = format(date, format = "%Y%m%d"),
    time_char = substr(time_original, 1, 4),
  )
df = df %>%
  mutate(
    type = tolower(type),
    id = paste0(id_patient, "_", date_char, "_", time_char),
    fname = paste0(id, "_", type, ".nii.gz"),
    file_nifti = file.path(dirs$nifti, fname),
    file_coreg = file.path(dirs$coregistered, fname),
    file_reg_template = file.path(dirs$template_registered, fname)
  ) %>%
  select(-fname)


df = df %>%
  mutate(
    stub = basename(file_nifti),
    stub = ifelse(type == "roi", NA_character_, stub),
    # base_stub = sub("_ct", "", stub),
    base_stub = stub,
    file_ss = here::here(dirs$brain_extracted, base_stub),
    file_mask = here::here(dirs$brain_mask, base_stub),
    file_coreg_transforms = here::here(dirs$coregistered_transforms, base_stub),
    png = paste0(neurobase::nii.stub(base_stub), ".png"),
    png = ifelse(is.na(base_stub), NA_character_, png),
    file_image_nifti = here::here(dirs$image_nifti, png),
    file_image_nifti = sub("_ct", "", file_image_nifti),
    file_image_ss = here::here(dirs$image_ss, png)
  ) %>%
  select(-stub, -base_stub, -png)
df = df %>%
  group_by(id_patient) %>%
  mutate(
    file_ss_template = file_ss[type %in% "ct"][1]
  ) %>%
  ungroup()
# n_folds = 50
# id_df = df %>%
#   distinct(id_study) %>%
#   mutate(fold = seq(dplyr::n()),
#          fold = floor(fold / ceiling(dplyr::n()/n_folds) + 1))
id_df = df %>%
  distinct(id_patient) %>%
  mutate(fold = as.numeric(factor(id_patient)))
df = left_join(df, id_df)
write_rds(df, here::here("data", "dicom_filenames.rds"))


df_study = df %>%
  select(id_patient, id, id_patient_short, num_patient_short,
         date, time, type, id_study, dir_study, dir_series, fold,
         starts_with("file_")) %>%
  distinct()
write_rds(df_study, here::here("data", "dicom_study_filenames.rds"))

check = df_study |>
  dplyr::summarise(n = dplyr::n(), .by = c(id_patient, num_patient_short,
                                           id, date, time, dir_study, fold, type)) |>
  dplyr::filter(n > 1L)
stopifnot(nrow(check) == 0)
wide = df_study %>%
  select(starts_with("id"), date, time, type, fold, dir_study,
         dir_series, file_nifti, file_coreg,
         file_reg_template, file_ss, file_coreg_transforms,
         file_image_nifti, file_image_ss,
         file_ss_template) %>%
  pivot_wider(names_from = type,
              values_from = c(dir_series, file_nifti, file_coreg,
                              file_reg_template, file_ss, file_coreg_transforms,
                              file_image_nifti, file_image_ss))
wide = wide %>%
  select(-file_ss_roi, -file_coreg_transforms_roi,
         -file_image_nifti_roi,
         -file_image_ss_roi)
wide = wide %>%
  rename(
    file_ss = file_ss_ct,
    file_coreg_transforms = file_coreg_transforms_ct,
    file_image_nifti = file_image_nifti_ct,
    file_image_ss = file_image_ss_ct,
  )
write_rds(wide, here::here("data", "dicom_study_filenames_wide.rds"))

