library(dplyr)
library(neurobase)
library(extrantsr)
library(ichseg)
library(here)
setwd(here::here())

df = readr::read_rds("results/directory_df.rds")

df = df %>%
  filter(file.exists(ssfile) & file.exists(ss400))

# df = df %>%
#   filter(!(file.exists(regfile) & file.exists(reg400)))

iscen = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iscen)) {
  iscen = 927
}

func = function(infile, outfile, template) {
  omat = paste0(nii.stub(outfile), ".mat")
  if (!all(file.exists(c(outfile, omat)))) {
    ss = registration(
      filename = infile, 
      outfile = outfile,
      template.file = template, 
      typeofTransform = "Rigid",
      interpolator = "NearestNeighbor")
    file.copy(
      ss$fwdtransforms,
      omat,
      overwrite = TRUE
    )
  } else {
    ss = outfile
  }
  return(ss)
}

idf = df[iscen, ]
template = "templates/scct_stripped_hu8.nii.gz"


infile = idf$ssfile
outfile = idf$regfile
out = func(infile, outfile, template)
  
infile = idf$ss400
outfile = idf$reg400
func(infile, outfile, template)

