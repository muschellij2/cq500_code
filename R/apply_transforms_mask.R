library(RNifti)
library(neurobase)
library(ANTsRCore)
library(extrantsr)
setwd(here::here())
df = readr::read_rds("results/high_resolution_scans.rds")
df$maskfile = sub(".nii", "_Mask.nii", df$ssfile)

template_dir = "template_creation/iteration_37"
ss_file = file.path(template_dir, "average_with_skull.nii.gz")
ss_median_file = file.path(template_dir, "median_with_skull.nii.gz")

files = basename(df$outfile)
outfiles = file.path(template_dir,
                     sub("[.]nii", "_full.nii", basename(files)))
iid = as.numeric(Sys.getenv("SGE_TASK_ID"))

iid = ifelse(is.na(iid), 38, iid)
print(iid)
fname = "CQ500CT99_CT-PRE-CONTRAST-THIN.nii.gz"

fname = files[iid]
outfile = outfiles[iid]

if (!file.exists(outfile)) {
  
  trans = transformlist_from_outprefix(
    outprefix = file.path(template_dir, nii.stub(fname)),
    typeofTransform = "SyN")
  fwd = trans$fwdtransforms
  stopifnot(all(file.exists(fwd)))
  
  fixed = antsImageRead(file.path(template_dir, "average.nii.gz"))
  antsSetOrigin(fixed, rep(0, 3))
  
  moving = antsImageRead(file.path("nifti", fname))
  antsSetOrigin(moving, rep(0, 3))
  
  mask = (moving > -100) %>%
    filler(dilate = FALSE) %>% 
    largest_component %>%
    filler(erode = FALSE) %>% 
    filler(fill_size = 5)
  moving[mask == 0] = -1024
  
  moving = moving + 1024
  res = ants_apply_transforms(
    fixed = fixed,
    moving = moving,
    transformlist = fwd,
    interpolator = "nearestNeighbor")
  res = res - 1024
  res = round(res)
  write_nifti(res, outfile)
  # mask = (res > -100) %>%
  #   filler(dilate = FALSE) %>% 
  #   largest_component %>%
  #   filler(erode = FALSE) %>% 
  #   filler(fill_size = 5)
  # mask_res = mask_img(res, mask)
  # write_nifti(mask_res, outfile)
}


if (all(file.exists(outfiles))) {
  img = readNifti(outfiles[1]) * 0
  mat = matrix(NA_integer_, nrow = prod(dim(img)), ncol = length(outfiles))
  colnames(mat) = outfiles
  for (i in outfiles) {
    print(i)
    x = readNifti(i)
    img = img + x
    stopifnot(x[369, 60, 168] %in% c(0, -1024))
    x = as.integer(round(c(x)))
    mat[,i] = x
    rm(x)
  }
  img = img / length(outfiles)
  img = round(img)
  tfile = tempfile(fileext = ".nii.gz")
  write_nifti(img, tfile)
  mask = (check_ants(tfile) > -100) %>% 
    filler(dilate = FALSE) %>% 
    largest_component %>%
    filler(erode = FALSE)
  img = mask_img(img, mask)
  write_nifti(img, ss_file)
  
  
  med = matrixStats::rowMedians(mat)
  nim = readnii(outfiles[1])
  med_img = remake_img(vec = med, img = nim)
  med_img = mask_img(med_img, mask)
  write_nifti(med_img, ss_median_file)
  
}

