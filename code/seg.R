library(malf.templates)
library(RNifti)
library(neurobase)
library(extrantsr)
setwd(here::here())
temps = malf_images(n_templates = 35)

iteration = as.numeric(
  Sys.getenv("SGE_TASK_ID")
)
if (is.na(iteration)) {
  iteration = 37
}
masked = TRUE
paste_front = function(x, ...) {
  file.path(dirname(x), paste0(..., basename(x)))
}
fname = paste0("template_creation/iteration_", 
               iteration, 
               "/average.nii.gz")

img = check_ants(fname)
if (masked) {
  mask = img >= 5
  img = img * mask
}
inds = getEmptyImageDimensions(img)
red = applyEmptyImageDimensions(img, inds = inds)
red = oro2ants(red)

final_size = rep(512, 3)
kdim = (final_size - dim(red))/2
ofname = sub("[.]nii", "_512.nii", fname)
if (masked) {
  ofname = paste_front(ofname, "masked_")
}

if (!file.exists(ofname)) {
  out = zero_pad(red, kdim = kdim)
  write_nifti(out, ofname)
}

outfile =   paste0("template_creation/iteration_", 
                   iteration, "/seg.nii.gz")
if (masked) {
  outfile = paste_front(outfile, "masked_")
}
out_sub = sub("[.]nii", "_sub.nii", outfile)

if (!file.exists(outfile)) {
  seg = malf(
    infile = red, 
    template.images = temps$brains,
    # typeofTransform = "Rigid",
    func = "staple_label",
    template.structs = temps$tissues,
    verbose = 2
  )
  xseg = seg
  
  if (is.list(seg)) {
    seg = seg[[1]]
  }
  print(seg)
  write_nifti(
    seg, 
    out_sub
  )
  
  # seg = reg$outimg
  seg_out = array(0, dim = dim(img))
  seg_out[inds[[1]], inds[[2]], inds[[3]]] = array(seg, 
                                                   dim = dim(seg))
  seg_out = copyNIfTIHeader(img = seg, arr = seg_out)
  
  write_nifti(
    seg_out, 
    outfile
  )
} else {
  seg_out = readnii(outfile)
  seg = readnii(out_sub)
}

outfile512 = sub("[.]nii", "_512.nii", outfile)
out_seg = zero_pad(seg, kdim = kdim)
write_nifti(out_seg, outfile512)
