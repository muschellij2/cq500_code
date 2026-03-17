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
masked = FALSE
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

if (!file.exists(ofname)) {
  skull_fname = file.path(dirname(fname), 
                        "average_with_skull.nii.gz")
  skull_ofname = sub("[.]nii", "_512.nii", skull_fname)
  skull_fname2 = file.path(dirname(fname), "median_with_skull.nii.gz")
  skull_ofname2 = sub("[.]nii", "_512.nii", skull_fname2)
  
  if (masked) {
    skull_ofname = paste_front(skull_ofname, "masked_")
  }  
  skull_img = check_ants(skull_fname)
  skull_img2 = check_ants(skull_fname2)
  
  n_indices = 9
  skull_inds = inds
  skull_inds[[1]] = unique(sort(c(
    seq(min(skull_inds[[1]]) - n_indices, min(skull_inds[[1]])),
    skull_inds[[1]],
    seq(max(skull_inds[[1]]), max(skull_inds[[1]]) + n_indices)
  )))
  skull_inds[[2]] = unique(sort(c(
    seq(min(skull_inds[[2]]) - n_indices, min(skull_inds[[2]])),
    skull_inds[[2]],
    seq(max(skull_inds[[2]]), max(skull_inds[[2]]) + n_indices)
  )))  
    
  skull_red = applyEmptyImageDimensions(skull_img, inds = skull_inds)
  skull_red = oro2ants(skull_red)
  
  skull_red2 = applyEmptyImageDimensions(skull_img2, inds = skull_inds)
  skull_red2 = oro2ants(skull_red2)  
  
  skull_kdim = (final_size - dim(skull_red))/2
  
  sout = zero_pad(skull_red, kdim = skull_kdim)
  stopifnot(dim(sout) == rep(512, 3))
  write_nifti(sout, skull_ofname)
  
  sout2 = zero_pad(skull_red2, kdim = skull_kdim)
  stopifnot(dim(sout2) == rep(512, 3))
  write_nifti(sout2, skull_ofname2)
  
}

labels = TRUE
stub = ifelse(labels, "structures", "seg")
grab_value = ifelse(labels, "labels", "tissues")
func = ifelse(labels, "mode", "staple_label")
outfile =   paste0("template_creation/iteration_", 
                   iteration, "/", stub, ".nii.gz")
if (masked) {
  outfile = paste_front(outfile, "masked_")
}
out_sub = sub("[.]nii", "_sub.nii", outfile)

if (!file.exists(outfile)) {
  seg = malf(
    infile = red, 
    template.images = temps$brains,
    # typeofTransform = "Rigid",
    func = func,
    template.structs = temps[[grab_value]],
    verbose = 2
  )
  gc()
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
