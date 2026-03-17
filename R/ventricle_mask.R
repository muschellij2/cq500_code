library(fslr)
library(extrantsr)
setwd(here::here())

fname = "ss/CQ500CT9_CT-55mm-Plain.nii.gz"
brain_mask = sub("[.]nii", "_Mask.nii", fname)
brain_mask = readnii(brain_mask)
img = neurobase::readnii(fname)
b = mni_fname(mm = 2, brain = TRUE)
reg = registration(b, template.file = fname, 
                   typeofTransform = "SyN")
vmask = sub("_brain[.]nii.gz", "_VentricleMask.nii.gz", b)

mask = ants_apply_transforms(
  moving = vmask, fixed = fname, 
  transformlist = reg$fwdtransforms,
  interpolator = "NearestNeighbor")

n4 = mask_img(img + 1024, brain_mask)
n4 = bias_correct(n4, correction = "n4", mask = brain_mask)
n4 = mask_img(n4, brain_mask)
n4_orig = n4 - 1024

wn4 = window_img(n4_orig)
o = otropos(a = wn4, x = brain_mask)
ortho2(img, o$segmentation == 1, xyz =xyz(o$segmentation == 1))
est_vent = img < 15 & mask > 0 
