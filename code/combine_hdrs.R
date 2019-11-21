# library(tidyverse)
library(readr)
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
df = df %>% 
  left_join(reads)

ddf = df
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
df$pixdim3[is.na(df$pixdim3) & df$n == 1] = 0
stopifnot(!any(is.na(df$pixdim3)))


hdrs = vector(length = nrow(df), mode = "list")
indices = seq(nrow(df))
df$index = indices
for (i in indices) {
  idf = df[i,]
  hdr = readr::read_rds(idf$sub_hdr)
  hdrs[[i]] = hdr
  print(i)
}

hdr_df = bind_rows(hdrs, .id = "index") %>% 
  mutate(index = as.numeric(index))
hdf = hdr_df %>% 
  left_join(df %>% 
              select(id, index))
readr::write_rds(hdf, "results/headers_only.rds", compress = "xz")

hdr_df = hdr_df %>% 
  left_join(df)

readr::write_rds(hdr_df, "results/all_headers.rds", compress = "xz")
readr::write_rds(hdr_df, "results/all_headers.csv.gz")

hdr_df = hdr_df %>% 
  filter(!grepl("BONE", ConvolutionKernel),
         !grepl("CHST", ConvolutionKernel),
         !(grepl("DETAIL", ConvolutionKernel) & grepl("CQ500CT172", stub)),
         !(grepl("EC", ConvolutionKernel) & grepl("BONE", stub))
  )

bad = df %>% 
  filter(pixdim3 > 7)



