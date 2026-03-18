get_fold = function(default = 1L) {
  ifold = as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
  if (all(is.na(ifold))) {
    ifold = default
  }
  ifold
}

copy_dcm_files = function(df) {
  new_fname = new_file = NULL
  rm(list = c("new_fname", "new_file"))
  files = df$file
  stopifnot(anyDuplicated(basename(files)) == 0)
  tdir = tempfile()
  fs::dir_create(tdir)
  file_df = dplyr::tibble(
    file = files,
    new_fname = janitor::make_clean_names(tolower(basename(files)))
  ) %>%
    mutate(
      new_fname = sub("_dcm$", ".dcm", new_fname),
      new_file = file.path(tdir, new_fname)
    )
  file.copy(file_df$file, file_df$new_file)
  file_df %>%
    select(-any_of("new_file"))
  list(
    outdir = tdir,
    file_df = file_df
  )
}

py_dcmread = function(file) {
  pydicom_noconvert = reticulate::import("pydicom", convert = FALSE)
  # pd = reticulate::import("pandas")
  # pydicom = reticulate::import("pydicom")
  # out = lapply(file, function(fp) {
  #   z = pydicom$dcmread(fp = fp, stop_before_pixels = TRUE)
  #   jsonlite::fromJSON(z$to_json())
  # })
  out = lapply(file, function(fp) {
    pydicom_noconvert$dcmread(fp = fp, stop_before_pixels = TRUE)
  })
  names(out) = file
  # out_df = lapply(file, function(fp) {
  #   ds = pydicom_noconvert$dcmread(fp = fp, stop_before_pixels = TRUE)
  #   df = pd$DataFrame(ds$values())
  # })
  cn = c("AccessionNumber", "AcquisitionDate", "AcquisitionNumber",
         "AcquisitionTime", "AdditionalPatientHistory", "AdmittingDiagnosesDescription",
         "Allergies", "BitsAllocated", "BitsStored", "BodyPartExamined",
         "Columns", "ContentDate", "ContentTime", "ConvolutionKernel",
         "CTDIvol", "DataCollectionDiameter", "DateOfLastCalibration",
         "DerivationDescription", "DeviceSerialNumber", "DistanceSourceToDetector",
         "DistanceSourceToIsocenter", "DistanceSourceToPatient", "EthnicGroup",
         "Exposure", "ExposureInuAs", "ExposureModulationType", "ExposureTime",
         "FileMetaInformationGroupLength", "FileMetaInformationVersion",
         "FilterType", "FocalSpots", "FrameOfReferenceUID", "GantryDetectorTilt",
         "GeneratorPower", "HighBit", "ImageOrientationPatient", "ImagePositionPatient",
         "ImagesInAcquisition", "ImageType", "ImplementationClassUID",
         "ImplementationVersionName", "InstanceCreationDate", "InstanceCreationTime",
         "InstanceNumber", "InstitutionAddress", "InstitutionalDepartmentName",
         "InstitutionName", "Item", "ItemDelimitationItem", "KVP", "Laterality",
         "LossyImageCompression", "Manufacturer", "ManufacturerModelName",
         "MediaStorageSOPClassUID", "MediaStorageSOPInstanceUID", "MedicalAlerts",
         "Modality", "Occupation", "OperatorsName", "OtherPatientIDs",
         "PatientAddress", "PatientAge", "PatientBirthDate", "PatientComments",
         "PatientID", "PatientName", "PatientPosition", "PatientSex",
         "PatientSize", "PatientState", "PatientTelephoneNumbers", "PatientWeight",
         "PerformedProcedureStepDescription", "PerformedProcedureStepID",
         "PerformedProcedureStepStartDate", "PerformedProcedureStepStartTime",
         "PerformingPhysicianName", "PhotometricInterpretation", "PixelData",
         "PixelPaddingValue", "PixelRepresentation", "PixelSpacing", "PositionReferenceIndicator",
         "PregnancyStatus", "ProcedureCodeSequence", "ProtocolName", "ReconstructionDiameter",
         "ReferencedImageSequence", "ReferencedSOPClassUID", "ReferencedSOPInstanceUID",
         "ReferringPhysicianName", "RequestingPhysician", "RescaleIntercept",
         "RescaleSlope", "RescaleType", "RevolutionTime", "RotationDirection",
         "Rows", "SamplesPerPixel", "ScanOptions", "SequenceDelimitationItem",
         "SeriesDate", "SeriesDescription", "SeriesInstanceUID", "SeriesNumber",
         "SeriesTime", "SingleCollimationWidth", "SliceLocation", "SliceThickness",
         "SmokingStatus", "SoftwareVersions", "SOPClassUID", "SOPInstanceUID",
         "SourceApplicationEntityTitle", "SpatialResolution", "SpecialNeeds",
         "SpecificCharacterSet", "SpiralPitchFactor", "StudyDate", "StudyDescription",
         "StudyID", "StudyInstanceUID", "StudyTime", "TableFeedPerRotation",
         "TableHeight", "TableSpeed", "TimeOfLastCalibration", "TotalCollimationWidth",
         "TransferSyntaxUID", "ViewPosition", "WindowCenter", "WindowWidth",
         "XRayTubeCurrent")
  na_null = function(x) {
    if (is.null(x) || length(x) == 0) {
      return(NA)
    } else {
      x = as.character(x, nul = "")
      return(x)
    }
  }




  out_df = purrr::map_df(out, function(x) {
    xmeta = x$file_meta
    purrr::map_df(cn, function(y) {
      set = NULL
      if (y %in% names(xmeta)) {
        set = xmeta[[y]]
      }
      if (y %in% names(x)) {
        set = x[[y]]
      }
      if (!is.null(set)) {
        odf = data.frame(
          tag = na_null(set$tag),
          full_name = na_null(set$name),
          name = na_null(set$keyword)
        )
        odf$value = na_null(set$value)
      } else {
        odf = NULL
      }
      odf
    })
  }, .id = "file", .progress = TRUE)
  out_df = out_df %>%
    arrange(file, tag) %>%
    select(tag, value, name, file, everything())
  return(out_df)
}


read_header = function(x) {
  if (is.vector(x)) {
    x = data.frame(file = x)
  }
  out = copy_dcm_files(x)
  tdir = out$outdir
  file_df = out$file_df
  on.exit({
    unlink(tdir, recursive = TRUE)
  })

  header = try({
    read_dicom_header(file_df$new_file,
                      fail_on_nonzero_exit = TRUE)
  })
  if (is.null(header) || inherits(header, "try-error")) {
    header = try({
      read_dicom_header(file_df$new_file,
                        fail_on_nonzero_exit = TRUE,
                        add_opts = "+E")
    })
  }
  if (is.null(header) || inherits(header, "try-error")) {
    header = try({
      py_dcmread(file_df$new_file)
    })
  }

  if (is.null(header) || inherits(header, "try-error")) {
    msg = "Error reading header"
    message(msg)
    print(msg)
    return(NULL)
  }
  header = header %>%
    rename(new_fname = file) %>%
    mutate(new_fname = basename(new_fname))
  header = header %>%
    left_join(file_df)
  header = header %>%
    select(-any_of(c("new_file", "new_fname")))
  header

}


py_read_header = function(x) {
  if (is.vector(x)) {
    x = data.frame(file = x)
  }
  out = copy_dcm_files(x)
  tdir = out$outdir
  file_df = out$file_df
  on.exit({
    unlink(tdir, recursive = TRUE)
  })

  header =       py_dcmread(file_df$new_file)
  if (is.null(header) || inherits(header, "try-error")) {
    msg = "Error reading header"
    stop(msg)
  }

  header = header %>%
    rename(new_fname = file) %>%
    mutate(new_fname = basename(new_fname))
  header = header %>%
    left_join(file_df)
  header = header %>%
    select(-any_of(c("new_file", "new_fname")))
  header
}

remove_brackets = function(x) {
  x = sub("^\\[", "", x)
  x = sub("\\]$", "", x)
}

remove_forward_slash = function(x) {
  x = sub("^/", "", x)
  x = sub("/$", "", x)
}

remove_back_slash = function(x) {
  x = sub("^\\\\", "", x)
  x = sub("\\\\$", "", x)
}


general_recode_roi_name = function(x) {
  x = toupper(x)
  x = x %>%
    stringr::str_replace_all("-", "_") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("^\\d*[.]\\d*MM$", "OTHER") %>%
    stringr::str_replace_all("^\\d*[.]MM$", "OTHER")

  x = x %>%
    stringr::str_replace_all("(.+)\\d$", "\\1 ") %>%
    stringr::str_replace_all(stringr::fixed("("), " ") %>%
    stringr::str_replace_all(stringr::fixed(")"), " ") %>%
    stringr::str_replace_all(stringr::fixed(")"), " ") %>%
    stringr::str_replace_all("MM$", " ") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all(",", " ") %>%
    stringr::str_replace_all("\\s+", " ") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("[.]$", " ") %>%
    stringr::str_replace_all("(.+)\\d$", "\\1") %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("(.+)\\d$", "\\1 ") %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("_\\d$", " ") %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()


  x = x %>%
    stringr::str_replace_all("[.]$", " ") %>%
    stringr::str_replace_all("(.+)\\d$", "\\1") %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()


  x = x %>%
    stringr::str_replace_all("^3V(_|-| |$)", "3RD ") %>%
    stringr::str_replace_all("^3TH(_|-| |$)", "3RD ") %>%
    stringr::str_replace_all("^4V(_|-| |$)", "4TH ") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("^CTH(_|$)", "CATH\\1") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("UNKOWNN|UNKNWON|UNAMED|UNNAMD|UNNKNOWN|UNNKOWN|UNNAMED", "UNKNOWN")
  x = x %>%
    stringr::str_replace_all("SIN NOMBRE", "UNKNOWN")
  x = trimws(x)
  x = x %>%
    stringr::str_replace_all("^PHE$", "EDEMA")

  x = x %>%
    stringr::str_replace_all("_\\d$", " ") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("(.*LV)\\d$", "\\1") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("(.+)\\d$", "\\1") %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()

  x = x %>%
    stringr::str_replace_all("_$", "") %>%
    trimws()
  x
}

recode_roi_name = function(name) {
  name = general_recode_roi_name(name)
  name = stringr::str_replace_all(name, "NEW( |_)", "")
  name = stringr::str_replace_all(name, " ", "_")
  name = stringr::str_replace_all(name, "(L|R)_FRONTAL", "")
  name = stringr::str_replace_all(name, "(L|R)_FRONTO_PARIETAL", "")
  name = stringr::str_trim(name)
  name = stringr::str_replace_all(name, "^_", "")
  name = stringr::str_trim(name)
  name = dplyr::case_when(
    name %in% c("E1_LAYER", "E") ~ "EDEMA",
    name %in% c("OTHER_EVD", "CATH_EVD") ~ "CATH",
    name %in% c("SUBDURAL", "OTHER_SDH") ~ "SDH",
    name %in% c("OTHER_ICH") ~ "ICH",
    name %in% c("EVD_BLEEDING") ~ "EVD_BLEED",
    name %in% c("LL", "LLH", "LVV") ~ "LLV",
    name %in% c("ICH1_F", "ICH2_F",
                "ICH1_OTHER",
                "ICH2_OTHER", "ICH3_OTHER",
                "LEFT_PARIETAL_PERIVENTRICULAR_PARENCHYMA",
                "ICH_PARAHIPPOCAMPAL_GYRUS",
                "ICH_PARAHIPPOCA_MPAL_GYRUS") ~ "ICH",
    name %in% c("TOTAL_CYST") ~ "CYST",
    TRUE ~ name
  )
  name
}

open_it = function(...) {
  system2("open", ...)
}
