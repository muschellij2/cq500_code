# setwd("~/Desktop/")
library(neurobase)
library(extrantsr)
setwd(here::here())

# img = template$outfile
# ss = template$ssfile
img = "nifti/CQ500CT100_CT-Plain-THIN.nii.gz"
ss = "ss/CQ500CT100_CT-Plain-THIN.nii.gz"
mask = sub(".nii", "_Mask.nii", ss)
x = ANTsRCore::antsImageRead(img)
head_mask = x >= -100 & x <= 1000
cc =  ANTsRCore::iMath(img = head_mask, 
                       operation = "GetLargestComponent")
filled = filler(cc, fill_size = 11)

head_img = mask_img(x + 1024, filled)
head_img = head_img - 1024
whead = window_img(head_img) 

res = resample_image(
  head_img, 
  c(0.5, 0.5, 0.5),
  parameter_type = "mm",
  interpolator = "nearestneighbor")
res_mask = resample_image(
  filled, 
  c(0.5, 0.5, 0.5),
  parameter_type = "mm",
  interpolator = "nearestneighbor")

res_brain = resample_image(
  ANTsRCore::antsImageRead(ss), 
  c(0.5, 0.5, 0.5),
  parameter_type = "mm",
  interpolator = "nearestneighbor")
res_brain_mask = resample_image(
  ANTsRCore::antsImageRead(mask), 
  c(0.5, 0.5, 0.5),
  parameter_type = "mm",
  interpolator = "nearestneighbor")
empty = getEmptyImageDimensions(res_mask)

res_reduced = applyEmptyImageDimensions(res, empty)
res_mask_reduced = applyEmptyImageDimensions(res_mask, empty)

res_brain_reduced = applyEmptyImageDimensions(res_brain, empty)
res_brain_mask_reduced = applyEmptyImageDimensions(res_brain_mask, empty)

out_dir = "template_creation/original_template"
write_nifti(res_reduced, file.path(out_dir, "reduced_img.nii.gz"))
write_nifti(res_mask_reduced, file.path(out_dir, "reduced_head_mask.nii.gz"))
write_nifti(res_brain_reduced, file.path(out_dir, "reduced_ss.nii.gz"))
write_nifti(res_brain_mask_reduced, file.path(out_dir, "reduced_mask.nii.gz"))

d3 = ceiling(dim(res_reduced)[3] / 8) * 8
out_dim = c(512, 512, d3)
kdim = (out_dim - dim(res_reduced))/2

zp = zero_pad(res_reduced,
              kdim = kdim, pad_value = -1024)
zp_mask = zero_pad(res_mask_reduced,
                   kdim = kdim, pad_value = 0)
zp_brain = zero_pad(res_brain_reduced, 
                    kdim = kdim, pad_value = 0)
zp_brain_mask = zero_pad(res_brain_mask_reduced, 
                         kdim = kdim, pad_value = 0)

zero_origin = function(img) {
  origin(img) = rep(0, 3)
  img
}
zp = zero_origin(zp)
zp_mask = zero_origin(zp_mask)
zp_brain = zero_origin(zp_brain)
zp_brain_mask = zero_origin(zp_brain_mask)

write_nifti(zp, file.path(out_dir, "img.nii.gz"))
write_nifti(zp_mask, file.path(out_dir, "head_mask.nii.gz"))
write_nifti(zp_brain, file.path(out_dir, "ss.nii.gz"))
write_nifti(zp_brain_mask, file.path(out_dir, "mask.nii.gz"))



d3 = 512
out_dim = c(512, 512, d3)
kdim = (out_dim - dim(res_reduced))/2

zp = zero_pad(res_reduced,
              kdim = kdim, pad_value = -1024)
zp_mask = zero_pad(res_mask_reduced,
                   kdim = kdim, pad_value = 0)
zp_brain = zero_pad(res_brain_reduced, 
                    kdim = kdim, pad_value = 0)
zp_brain_mask = zero_pad(res_brain_mask_reduced, 
                         kdim = kdim, pad_value = 0)

zp = zero_origin(zp)
zp_mask = zero_origin(zp_mask)
zp_brain = zero_origin(zp_brain)
zp_brain_mask = zero_origin(zp_brain_mask)


write_nifti(zp, file.path(out_dir, "512_img.nii.gz"))
write_nifti(zp_mask, file.path(out_dir, "512_head_mask.nii.gz"))
write_nifti(zp_brain, file.path(out_dir, "512_ss.nii.gz"))
write_nifti(zp_brain_mask, file.path(out_dir, "512_mask.nii.gz"))

            
            
