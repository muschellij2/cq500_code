
create_overlay = function(img, roi) {
  pngname = tempfile(fileext = ".png")
  if (any(roi > 0)) {
    z = unique(which(roi > 0, arr.ind = TRUE)[, "dim3"])
    z = c(seq(min(z) -2, max(z) + 2, by = 1), z)
    z = sort(unique(z))
    z = z[z > 0 & z < oro.nifti::nsli(roi)]
  } else {
    z = round(oro.nifti::nsli(img)/2)
  }
  png(pngname, res = 300, height = 5, width = 5, units = "in")
  on.exit({
    try(dev.off(), silent = TRUE)
  })
  if (any(roi > 0)) {
    overlay(img, roi,
            NA.y = TRUE,
            plane = "axial",
            plot.type = "single", z = z,
            col.y = scales::alpha("red", 0.5))
  } else {
    image(img, roi,
          plane = "axial",
          plot.type = "single",
          z = z)
  }
  dev.off()
  pngname
}

create_ortho = function(img, roi, dir_study, pngname = tempfile(fileext = ".png")) {
  png(pngname, res = 300, height = 5, width = 5, units = "in")
  on.exit({
    try(dev.off(), silent = TRUE)
  })
  if (!any(roi > 0)) {
    roi = NULL
    xyz = NULL
  } else {
    xyz = xyz(roi)
  }
  ortho2(
    img,
    roi,
    xyz = xyz,
    NA.y = TRUE,
    col.y = scales::alpha("red", 0.5),
    text = dir_study
  )
  dev.off()
  pngname
}


create_double_ortho = function(img, roi, dir_study) {
  pngname = tempfile(fileext = ".png")
  png(pngname, res = 300, height = 5, width = 5, units = "in")
  on.exit({
    try(dev.off(), silent = TRUE)
  })
  double_ortho(
    img,
    roi,
    text = dir_study
  )
  dev.off()
  pngname
}
