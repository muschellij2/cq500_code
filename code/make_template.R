average_warps = function(warps, outfile = NULL, 
                         verbose = TRUE) {
  if (verbose) {
    message("Averaging warped images for brain")
  }
  h5_warps = sub("[.]nii.gz", ".h5", warps)
  warps[ file.exists(h5_warps)] = h5_warps[ file.exists(h5_warps)]
  n_warps = length(warps)
  avg_comp = NiftiArray::NiftiArrayList(warps, verbose = verbose)
  n_warps = length(avg_comp)
  avg_comp = Reduce(avg_comp, f = "+")
  avg_comp = as(avg_comp, "NiftiArray")
  avg_comp = avg_comp / n_warps
  avg_comp = as(avg_comp, "niftiImage")
  if (is.null(outfile)) {
    outfile = tempfile(fileext = ".nii.gz")
  }
  write_nifti(avg_comp, outfile)
  return(outfile)
}

obsolete.average_warps = function(warps, outfile = NULL, 
                         verbose = TRUE) {
  if (verbose) {
    message("Averaging warped images for brain")
  }
  avg_comp = antsAverageImages(warps, verbose = verbose)
  if (is.null(outfile)) {
    outfile = tempfile(fileext = ".nii.gz")
  }
  antsImageWrite(avg_comp, outfile)
  return(outfile)
}

avg_warps = function(warps, outfile = NULL, verbose = TRUE) {
  if (verbose) {
    message("Averaging warped images for brain")
  }
  avg_comp = RNifti::readNifti(warps[1])
  for (i in 2:length(warps)) {
    if (verbose) {
      print(i)
    }
    avg_comp = avg_comp + RNifti::readNifti(warps[i])
  }
  avg_comp = avg_comp / length(warps)
  if (is.null(outfile)) {
    outfile = tempfile(fileext = ".nii.gz")
  }  
  write_nifti(avg_comp, outfile)
  return(outfile)  
}


make_template = function(template,
                         average_warp, 
                         sharpen = TRUE, 
                         gradientStep = 0.2, 
                         verbose = TRUE,
                         interpolator = "nearestNeighbor",
                         round_values = TRUE) {
  # if (!is.null(masks)) {
  #   stopifnot(length(images) == length(masks))
  #   template_mask = antsAverageImages(masks)
  # }
  template = check_ants(template)
  average_warp = check_ants(average_warp)
  avg_comp = average_warp * (-1 * gradientStep)
  fn_temp = tempfile(fileext = ".nii.gz")
  ANTsRCore::antsImageWrite(avg_comp, fn_temp)
  if (verbose) {
    message("Applying average transformation to average image")
  }
  # if (!is.null(masks)) {
  #   template_mask = antsApplyTransforms(
  #     template_mask, template_mask, 
  #     fn_temp)
  # }
  template = ANTsRCore::antsApplyTransforms(template, template, fn_temp,
                                 interpolator = interpolator)
  if (verbose) {
    message("Smoothing brain")
  }
  if (sharpen) {
    template = template * 0.5 + 
      ANTsRCore::iMath(template, "Sharpen") * 0.5
    # if (!is.null(masks)) {
    #   template_mask = template_mask * 0.5 + 
    #     iMath(template_mask, "Sharpen") * 0.5
    # }
  }
  
  if (verbose) {
    message("Saving new template for brain")
  }
  if (round_values) {
    tarr = as.array(template)
    tarr = round(tarr)
    template = ANTsRCore::as.antsImage(tarr, 
                            reference = template)
    # template = round(template)
    
  }
  outfile = tempfile(fileext = ".nii.gz")
  ANTsRCore::antsImageWrite(template, outfile)
  mask_outfile = NULL
  # if (!is.null(masks)) {
  #   mask_outfile = tempfile(fileext = ".nii.gz")
  #   antsImageWrite(template_mask, outfile)
  # }
  L = list(outfile = outfile,
           warp_outfile = fn_temp)
  L$mask_outfile = mask_outfile
  return(L)
  
}
