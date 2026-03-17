library(readr)
library(dplyr)
library(tidyr)
library(neurobase)
library(ichseg)
library(extrantsr)
setwd(here::here())

reads = read_csv("zip/reads.csv")
reads = reads %>% 
  gather(var, value, -name, -Category) %>% 
  separate(var, into = c("reader", "type"), sep = ":") %>% 
  spread(type, value = value) %>% 
  mutate(id = gsub("-", "", name)) 

v = vars("BleedLocation-Left", "BleedLocation-Right", 
         "CalvarialFracture", "ChronicBleed", "EDH", "Fracture", "ICH", 
         "IPH", "IVH", "MassEffect", "MidlineShift", "OtherFracture", 
         "SAH", "SDH")
anyone = function(x) {
  any(x > 0)
}
any_reads = reads %>% 
  group_by(id, Category) %>% 
  summarise_at(v, sum)


bleeds = reads %>% 
  filter(IPH > 0 | IVH > 0)
stopifnot(all(reads$IPH <= 1))
stopifnot(all(reads$IVH <= 1))
n_bleeds = reads %>% 
  group_by(name) %>% 
  summarize_at(.vars = vars(IPH, IVH), sum) %>% 
  mutate(id = gsub("-", "", name))
  
bleeds = bleeds %>% 
  select(name, Category) %>% 
  distinct()

bleeds = bleeds %>%
  select(id) %>% 
  arrange(id) %>% 
  distinct()

df = readr::read_rds("results/directory_df.rds")
df = df %>% 
  mutate(pred_file = file.path("pitch", basename(outfile)),
         out_pred_file = 
           file.path("pitch", paste0(nii.stub(outfile, bn = TRUE),
                                     "_pitch.nii.gz")),
         out_prob_file = sub("_pitch", "_prob", out_pred_file)
  )
df = df %>% 
  left_join(any_reads %>% 
              select(id, IPH, IVH)
              )
# df = left_join(bleeds, df)
# df = df[ !file.exists(df$pred_file) & file.exists(df$outfile), ]
iscen = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iscen)) {
  iscen = 216
  # "nifti/CQ500CT172_CT-Thin-PLAIN.nii.gz" - 216 is chest
}



idf = df[iscen,]

# ss = CT_Skull_Strip_smooth("nifti/CQ500CT172_CT-Thin-Plain.nii.gz",
#                            remove.neck = TRUE, remover = "double_remove_neck")

if (!all(file.exists(idf$pred_file, idf$out_prob_file))) {
  
  res = ich_segment(img = idf$outfile,
                    robust = TRUE, 
                    smooth_before_threshold = TRUE,
                    smooth.factor = 1,
                    remove.neck = TRUE,
                    recog = FALSE,
                    nvoxels = 0)
  img = readnii(idf$outfile)
  native_res = res$native_prediction
  native_pred = native_res$smoothed_probability_image > 
    res$registered_prediction$smoothed_cutoff
  
  writenii(native_pred, filename = idf$pred_file)
  
  writenii(native_res$smoothed_prediction_image, 
           filename = idf$out_pred_file)
  
  native_prob = native_res$smoothed_probability_image 
  writenii(native_prob, idf$out_prob_file)
  
}
