# library(tidyverse)
# library(readr)
pbapply::pboptions(type = "timer")
library(dplyr)
library(RNifti)
library(neurobase)
library(fslr)
library(here)
library(ANTsRCore)
library(extrantsr)
library(NiftiArray)
setwd(here::here())

source(file.path("code", "make_template.R"))

df = readr::read_rds("results/high_resolution_scans.rds")
# take out template
iter = 18
iter_thresh = 20
for (iter in 15:40) {
  print(paste("iter is: ", iter))
  
  out_dir = file.path("template_creation",
                      paste0("iteration_", iter))
  dir.create(out_dir, showWarnings = FALSE)
  
  df$registered_outfile = file.path(out_dir, 
                                    basename(df$ssfile))
  
  df$h5_outfile = file.path(out_dir, 
                            paste0(
                              nii.stub(df$ssfile, bn = TRUE), 
                              ".h5"))
  df$maskfile = sub(".nii", "_Mask.nii", df$ssfile)
  df$registered_mask_outfile = sub(".nii", "_Mask.nii", 
                                   df$registered_outfile)
  df$warp_outfile = file.path(out_dir, 
                              paste0(nii.stub(df$ssfile, 
                                              bn = TRUE), 
                                     "_Composed.nii.gz"))
  df$warp_h5_outfile = file.path(out_dir, 
                                 paste0(nii.stub(df$ssfile, 
                                                 bn = TRUE), 
                                        "_Composed.h5"))  
  
  df$n4_outfile = file.path(out_dir, 
                            paste0(nii.stub(df$ssfile, 
                                            bn = TRUE), 
                                   "_n4.nii.gz"))  
  
  template_dir = file.path("template_creation", 
                           paste0("iteration_", iter - 1))
  template_ss = file.path(template_dir, 
                          "ss.nii.gz")
  template_mask = file.path(template_dir, 
                            "mask.nii.gz")
  template_average_warp =  file.path(template_dir, 
                                     "avg_warp.nii.gz")
  
  next_template_ss = file.path(out_dir, 
                               "ss.nii.gz")
  next_template_med = file.path(out_dir, 
                                "ss_median.nii.gz")
  template_avg = file.path(out_dir, 
                           "average.nii.gz")
  template_median = file.path(out_dir, 
                              "median.nii.gz")
  next_template_mask = file.path(out_dir, 
                                 "mask.nii.gz")
  
  h5_check =  !all(file.exists(df$h5_outfile)) | 
    !all(file.exists(df$warp_h5_outfile))
  if (iter <= iter_thresh) {
    h5_check = FALSE
  }
  if (file.exists(template_ss) & 
      (!all(file.exists(df$registered_outfile)) | h5_check)
  ) {
    fixed = antsImageRead(template_ss)
    antsSetOrigin(fixed, rep(0, 3))
    
    # img = antsImageRead(template_file)
    # cc = largest_component(img > -400 & img < 1000)
    # inds = getEmptyImageDimensions(cc)
    # img = applyEmptyImageDimensions(img, inds = inds)
    
    iscen = as.numeric(
      Sys.getenv("SGE_TASK_ID")
    )
    if (is.na(iscen)) {
      iscen = 84
    }
    
    idf = df[ iscen, ]
    ssfile = idf$ssfile
    maskfile = idf$maskfile
    warp_outfile = idf$warp_outfile
    warp_h5_outfile = idf$warp_h5_outfile
    
    n4_outfile = idf$n4_outfile
    mask_outfile = idf$registered_mask_outfile
    outfile = idf$registered_outfile
    h5_outfile = idf$h5_outfile
    
    outprefix = nii.stub(outfile)
    
    moving = antsImageRead(ssfile)
    antsSetOrigin(moving, rep(0, 3))
    reg = transformlist_from_outprefix(outprefix = outprefix,
                                       typeofTransform = "SyN")
    interpolator = "NearestNeighbor"
    
    if (
      !all(file.exists(reg$fwdtransforms)) |
      !file.exists(outfile)) {
      reg = registration(
        filename = moving, 
        template.file = fixed,
        interpolator = interpolator,
        typeofTransform = "SyN",
        outprefix = outprefix,
        outfile = outfile)  
      reg$outfile = NULL;
      gc()
    } else {
      reg$interpolator = interpolator
    }
    
    if (!file.exists(h5_outfile) & iter >= iter_thresh) {
      writeNiftiArray(outfile, filepath = h5_outfile, verbose = TRUE,
                      level = 9L)
    }
    
    if (!file.exists(mask_outfile)) {
      moving_mask = antsImageRead(maskfile)
      antsSetOrigin(moving_mask, rep(0, 3))
      out_mask = antsApplyTransforms(
        fixed = fixed,
        moving = moving_mask,
        transformlist = reg$fwdtransforms,
        interpolator = "NearestNeighbor",
        verbose = TRUE)
      antsImageWrite(out_mask, mask_outfile)
      rm(moving_mask); gc()
    }
    
    
    if (!file.exists(n4_outfile)) {
      if (file.exists(idf$n4)) {
        moving_mask = antsImageRead(idf$n4)
        antsSetOrigin(moving_mask, rep(0, 3))
        out_mask = antsApplyTransforms(
          fixed = fixed,
          moving = moving_mask,
          transformlist = reg$fwdtransforms,
          interpolator = "NearestNeighbor",
          verbose = TRUE)
        antsImageWrite(out_mask, n4_outfile)
        rm(moving_mask); gc()
      }
    }
    
    
    if (!file.exists(warp_outfile)) {
      m1 = antsImageClone(moving, out_pixeltype = "double")
      f1 = antsImageClone(fixed, out_pixeltype = "double")
      antsSetOrigin(f1, rep(0, 3))
      antsSetOrigin(m1, rep(0, 3))
      
      rm(moving); gc()
      rm(fixed); gc()
      fn_temp = antsApplyTransforms(
        fixed = f1,
        moving = m1,
        transformlist = reg$fwdtransforms,
        compose = tempfile(),
        interpolator = reg$interpolator,
        verbose = TRUE)
      file.copy(fn_temp, warp_outfile, overwrite = TRUE)
    }
    
    if (!file.exists(warp_h5_outfile) & iter >= iter_thresh) {
      writeNiftiArray(warp_outfile, filepath = warp_h5_outfile, 
                      verbose = TRUE, level = 9L)
    }    
    
    
  }
}
