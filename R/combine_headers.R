# library(tidyverse)
# library(readr)
library(dplyr)
library(tibble)
library(tidyr)
library(dcmtk)
library(dcmsort)
library(here)
setwd(here::here())

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  mutate(hdr = file.path("hdr", 
                         paste0(stub, ".rds")))
df = df %>% 
  filter(file.exists(hdr))
iscen = 1

hdr_outfile = "results/all_header.rds"

if (!file.exists(hdr_outfile)) {
  all_hdrs = vector(mode = "list", length = nrow(df))
  names(all_hdrs) = df$stub
  
  for (iscen in seq(nrow(df))) {
    print(iscen)
    idf = df[iscen, ]
    hdr = readr::read_rds(idf$hdr)
    all_hdrs[[iscen]] = hdr
  }
  
  hdr_df = bind_rows(all_hdrs, .id = "stub")
  
  readr::write_rds(x = hdr_df, path = hdr_outfile,
                   compress = "xz")
} else {
  hdr_df = readr::read_rds(hdr_outfile)
}
# 
# h = hdr_df %>% 
#   select(file, name, value) %>% 
#   filter(!name %in% c("Item", "GenericGroupLength", 
#                       "SequenceDelimitationItem") )
# wide = h %>% 
#   spread(key = name, value = value)
# 
# demog = hdr_df %>% 
#   filter(name %in% c("PatientSex", "PatientBirthDate", 
#                      "StudyID", "StudyDate", "ReferringPhysicianName",
#                      "PatientName", "PatientID", "ContentDate",
#                      "ManufacturerModelName", "Manufacturer"))

sub_hdr = hdr_df %>%
  select(file, stub, tag, name, value) %>% 
  filter(!is.na(value)) 

# this should remove completely identical tags
sub_hdr = sub_hdr %>%
  distinct()


keep_files = sub_hdr %>%
  group_by(file) 
keep_files = keep_files %>%
  add_count(tag, name = "ind")

keep_files = keep_files %>%
  ungroup()

multi = keep_files %>%
  filter(ind > 1)
u_name = unique(multi$name)

sub_hdr = keep_files %>% 
  filter(ind == 1) %>% 
  select(-ind)

only_tags = sub_hdr %>% 
  select(tag, name)
check = only_tags %>% 
  count(tag, name) %>% 
  pull(n)
stopifnot(all(check == 1))

# spread key or tag?
# need tag if that's what we're checking above
wide = sub_hdr %>% 
  select(-name) %>% 
  spread(key = tag, value = value)
rel_tags = c(dcmsort::relevant_tags(), 
             "(0018,0010)")
rel_tags = dcmtk::dicom_tags %>% 
  filter(tag %in% rel_tags) %>% 
  select(tag, name, keyword)

sub_wide = wide %>% 
  select(one_of(c("file", "stub", rel_tags$tag)))

renamer = lapply(rel_tags$tag, sym)
names(renamer) = rel_tags$keyword
renamer = renamer[rel_tags$tag %in% colnames(sub_wide)]
sub_wide = sub_wide %>% 
  rename(!!!renamer)

