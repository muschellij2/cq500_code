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

hh = hdr_df[
  hdr_df$name == "SliceThickness",
  ]
sub = hh %>% 
  select(name, value, stub) %>% 
  distinct() 
sub %>% 
  count(stub) %>% 
  filter(n > 1)

sub %>% 
  filter(stub %in% "CQ500CT162_CT-Plain-2")

hh = hdr_df[
  hdr_df$name == "SliceThickness",
]
hh$value = as.numeric(
  gsub("\\[|\\]", "", hh$value))
hh = hh[ hh$value > 3, ]

hdr = hdr_df[ hdr_df$file %in% unique(hh$file),]
vals = hdr[ hdr$name == "GantryDetectorTilt","value"]
vals = gsub("\\[|\\]", "", vals)
vals = as.numeric(vals)
stubs = unique(hdr[ hdr$name == "GantryDetectorTilt", "stub"][ vals > 29])

# CQ500CT285_CT-5mm


vals = hdr_df[ hdr_df$name == "GantryDetectorTilt","value"]
vals = gsub("\\[|\\]", "", vals)
vals = as.numeric(vals)

unique(hdr_df[ which(vals == max(vals)), "stub"])
