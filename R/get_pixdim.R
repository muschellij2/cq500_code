# library(tidyverse)
# library(readr)
library(dplyr)
library(fslr)
library(here)
setwd(here::here())

reads = readr::read_csv("data/reads.csv")
reads = reads %>% 
  mutate(name = gsub("-", "", name)) %>% 
  rename(id = name)

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  mutate(
    hdr = file.path("hdr", 
                    paste0(stub, ".rds")),
    sub_hdr = file.path("sub_hdr", 
                        paste0(stub, ".rds")))

ddf = df %>% 
  filter(n > 1)
stopifnot(all(file.exists(ddf$outfile)))
fe = file.exists(ddf$hdr)
stopifnot(all(fe))
fe = file.exists(ddf$sub_hdr)
stopifnot(all(fe))

df$pixdim3 = NA
i = 1
for (i in seq(nrow(df))) {
  idf = df[i,]
  if (idf$n > 1) {
    p3 = fslval(file = idf$outfile, "pixdim3", verbose = FALSE)
    df$pixdim3[i] = as.numeric(p3)
  }
  print(i)
}

bad = df %>% 
  filter(pixdim3 > 7)

