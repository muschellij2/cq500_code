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
library(DelayedArray)
library(DelayedMatrixStats)
setwd(here::here())

source(file.path("code", "make_template.R"))

df = readr::read_rds("results/high_resolution_scans.rds")
df$maskfile = sub(".nii", "_Mask.nii", df$ssfile)

# take out template
iter = 27

for (iter in 1:40) {
  message(paste0("iteration: ", iter))
  out_dir = file.path("template_creation",
                      paste0("iteration_", iter))
  dir.create(out_dir, showWarnings = FALSE)
  
  df$registered_outfile = file.path(out_dir, 
                                    basename(df$ssfile))
  df$h5_outfile = sub(".nii.gz", ".h5", df$registered_outfile)  
  df$registered_mask_outfile = sub(".nii", "_Mask.nii", 
                                   df$registered_outfile)
  df$warp_outfile = file.path(out_dir, 
                              paste0(nii.stub(df$ssfile, bn = TRUE), 
                                     "_Composed.nii.gz"))
  df$warp_h5_outfile = sub(".nii.gz", ".h5", df$warp_outfile)  
  
  template_dir = file.path("template_creation", 
                           paste0("iteration_", iter - 1))
  # template_file = file.path(template_dir, 
  #                           "img.nii.gz")
  template_ss = file.path(template_dir, 
                          "ss.nii.gz")
  template_mask = file.path(template_dir, 
                            "mask.nii.gz")
  template_average_warp =  file.path(template_dir, 
                                     "avg_warp.nii.gz")
  
  if (!file.exists(template_average_warp) &
      all(file.exists(df$warp_outfile))) {
    # res = pbapply::pblapply(df$warp_outfile, antsImageRead)
    avg_warps(df$warp_outfile, 
                  outfile = template_average_warp)
    # average_warps(df$warp_outfile, 
    #               outfile = template_average_warp)
  }
  next_template_ss = file.path(out_dir, 
                               "ss.nii.gz")
  next_template_med = file.path(out_dir, 
                                "ss_median.nii.gz")
  next_template_sd = file.path(out_dir, 
                                "ss_sd.nii.gz")  
  
  template_avg = file.path(out_dir, 
                           "average.nii.gz")
  template_median = file.path(out_dir, 
                              "median.nii.gz")
  template_sd = file.path(out_dir, 
                              "sd.nii.gz")  
  next_template_mask = file.path(out_dir, 
                                 "mask.nii.gz")
  
  # if (!file.exists(next_template_ss) & 
  #     all(file.exists(df$registered_outfile)) &
  #     file.exists(template_average_warp)) {
  #   if (!file.exists(template_avg)) {
  #     template = antsAverageImages(df$registered_outfile)
  #     antsImageWrite(template, template_avg)
  #   } else {
  #     template = antsImageRead(template_avg)
  #   }
  #   res = make_template(template,
  #                       average_warp = template_average_warp)
  #   file.copy(res$outfile, next_template_ss)
  #   # file.copy(res$warp_outfile, template_average_warp)
  #   rm(template);
  # }
  
  if ( (!file.exists(next_template_med) | 
        !file.exists(next_template_sd) |  
        !file.exists(next_template_ss) ) & 
       all(file.exists(df$registered_outfile)) &
       file.exists(template_average_warp)) {
    if (!file.exists(template_median) | 
        !file.exists(template_sd) |         
        !file.exists(template_avg) ) {
      
      timg = neurobase::readnii(df$registered_outfile[1])
      # mat = bigmemory::big.matrix(0.0, nrow = prod(dim(timg)), ncol = nrow(df))
      mat = matrix(0.0, nrow = prod(dim(timg)), ncol = nrow(df))
      for (i in seq(nrow(df))) {
        x = RNifti::readNifti(df$registered_outfile[i])
        x = c(x)
        mat[,i] = x
        rm(x); gc()
        print(i)
      }
      # mat = NiftiArrayList(df$h5_outfile, verbose = TRUE)
      # reshape_matrix = function(res) {
      #   dres = dim(res)
      #   rl = pbapply::pblapply(seq(dres[3]), function(i) {
      #     xx = res[,,i]
      #     xx = lapply(seq(dres[2]), function(i) {
      #       xx[, i, drop = FALSE]
      #     })
      #     xx = do.call(DelayedArray::arbind, xx)
      #     xx
      #   })
      #   rl = do.call(DelayedArray::arbind, rl)
      # }
      # mat = pbapply::pblapply(mat, reshape_matrix)
      
      # mat = as(mat, "NiftiArray")
      # mat = as(mat, "NiftiMatrix")
      message("Getting RowMeans")
      avg_img = rowMeans(mat)
      avg_img = round(avg_img)
      avg_img = niftiarr(avg_img, img = timg)
      message("Saving Mean")
      write_nifti(avg_img, template_avg)    
      
      message("Getting RowMedians")
      med_img = matrixStats::rowMedians(mat)
      med_img = round(med_img)
      med_img = niftiarr(med_img, img = timg)
      message("Saving Median")
      write_nifti(med_img, template_median)          
      
      message("Getting RowSds")
      sd_img = matrixStats::rowSds(mat)
      sd_img = round(sd_img)      
      sd_img = niftiarr(sd_img, img = timg)
      message("Saving SD")
      write_nifti(sd_img, template_sd)
      rm(mat); for (i in 1:10) gc()

     

      
    } else {
      avg_img = readnii(template_avg)    
      med_img = readnii(template_median)
      sd_img = readnii(template_sd)
    }
    message("Making Average Template")
    
    res = make_template(avg_img,
                        average_warp = template_average_warp)
    file.copy(res$outfile, next_template_ss)
    rm(avg_img);  
    
    message("Making Median Template")
    res = make_template(med_img,
                        average_warp = template_average_warp)
    file.copy(res$outfile, next_template_med)  
    rm(med_img)
    
    message("Making SD Template")
    res = make_template(sd_img,
                        average_warp = template_average_warp)
    file.copy(res$outfile, next_template_sd)  
    rm(med_img)    
  }
  
}
