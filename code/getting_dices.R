library(RNifti)
library(neurobase)
setwd(here::here())

x = list.files(
  path = "template_creation",
  full.names = TRUE,
  # pattern = "^ss.nii.gz", 
  pattern = "^ss_median.nii.gz",
  recursive = TRUE)
x = x[!grepl("iteration_0", x)]
x = x[grepl("iteration", x)]
index = as.numeric(sub(".*iteration_(\\d*).*", "\\1", x))
x = x[order(index)]

df = tibble::tibble(ind = 2:length(x),
                    ind2 = ind - 1,
                    img = x[2:length(x)])
df = dplyr::arrange(df, desc(ind))
df$max_dist = df$rmse = df$dice = NA

outfile  = file.path("results", 
  paste0("dice_", unique(nii.stub(df$img, bn = TRUE)), ".rds"))

i = 1

for (i in 1:nrow(df)) {
  ind1 = df$ind[i]
  ind2 = df$ind2[i]
  i1 = readNifti(x[[ind1]])
  i2 = readNifti(x[[ind2]])
  d = (i1 - i2)
  df$max_dist[i] = max(abs(d))
  df$rmse[i] = sqrt(mean(d^2))
  rm(d); for (xx in 1:10) gc()
  dice = fast_dice(i1, i2)
  rm(i1); for (xx in 1:10) gc()
  rm(i2); for (xx in 1:10) gc()
  
  df$dice[i] = dice
  print(i)
  print(df$rmse[i])
  print(df$max_dist[i])
  print(df$dice[i])
}


readr::write_rds(df, path = outfile)

