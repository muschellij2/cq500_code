library(dplyr)
library(RNifti)
library(neurobase)
library(here)
setwd(here::here())

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  mutate(hdr = file.path("hdr", paste0(stub, ".rds")))

df = df %>% 
  mutate(ssfile = sub("[.]nii", "_Mask.nii", ssfile),
         ss400 = sub("[.]nii", "_Mask.nii", ss400))
df = df %>%
  filter(file.exists(outfile) & file.exists(ssfile) & file.exists(ss400))
df$sspng = file.path("results", "ss", paste0(df$stub, ".png"))
df$ss400png = file.path("results", "ss400", paste0(df$stub, ".png"))

# df = df %>%
#   filter(!(file.exists(sspng) & file.exists(ss400png)))

uids = sort(unique(df$id))
n_ids = length(uids)
# df = run_df
iscen = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iscen)) {
  iscen = 4
}
# id = uids[iscen]
# idf = df[ df$id %in% id, ]

idf = df[ iscen, ]
pick_alpha = function() {
  myalpha = 0.25
  if (names(dev.cur())[1] == "X11") {
    myalpha = 1
  }
}

sspng = idf$sspng
ss400png = idf$ss400png

if (!file.exists(sspng) | !file.exists(ss400png)) {
  img = RNifti::readNifti(idf$outfile)
  wimg = window_img(img)
  mask = RNifti::readNifti(idf$ssfile)
  stub = sub("_CT", "", idf$stub)
  
  png(sspng, type = "cairo", height = 7, width = 7, res = 150, units = "in")
  col.y = scales::alpha("red", alpha = pick_alpha())
  ortho2(wimg, mask, text = paste0("ss\n", stub), col.y = col.y)
  dev.off()
  
  png(ss400png, type = "cairo", height = 7, width = 7, res = 150, units = "in")  
  mask = RNifti::readNifti(idf$ss400)
  col.y = scales::alpha("red", alpha = pick_alpha())
  ortho2(wimg, mask, text = paste0("ss400\n", stub), col.y = col.y)
  dev.off()
}
