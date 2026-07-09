## reactive values

## reactive values for peak detection new sample
RvarsPeakDetectionNewSample <- reactiveValues(
  Project_Name = character(),
  run_ref_path = character(),
  map_ref_path = character(),
  map_ref = data.frame(
    ID = character(),
    mz = numeric(0),
    rt = numeric(0),
    maxo = numeric(0)
  ),
  res_match_ref = list(),
  normalizers_ref_path = character(),
  normalizers_ref = data.frame(),
  res_MatrixNewSample = NULL,
  matrix_abondance = matrix(),
  matrix_abondance_Normalize = matrix(),
  
  iset.normalizer.selected = NULL,
  
  
  paramMsdial_ref_path = character(),
  peaksList_run_ref_path = character(),
  defaultParam_ref_path = character(),
  defaultParam = NULL,
  
  rt_min_max_run_ref_path = character(),
  rt_min_max_run_ref = data.frame(),
  rt_min_ref = numeric(),
  rt_max_ref = numeric(),
  directoryOutput_mzML_files = character(),
  peaks_MSDIAL_mono_iso_newSample = NULL,
  
  peakList_mono_iso_newSample = NULL,
  peakList_mono_iso = NULL,
  
  
  # Cutting run reactieValues
  samplesCuttingTable_newSample = NULL,
  sample_cutting_newSample = NULL,
  sample_cutting_viewer_ConvertTime_newSample = NULL,
  peaks_mono_iso_Cutt_newSample = NULL,
  Second_Cutting_newSample = TRUE,
  
  ## Correction time
  peaks_mono_iso_newSample_list = NULL,
  Data_Plot.newSample_to_filter = NULL,
  Data_Plot.newSample = NULL,
  modelKernelDensity = NULL,
  peaks_newSample_list_KernelDensityCorrection = NULL,
  Data_Plot.after_KernelDensity = NULL,
  
  
  ## Grouping new sample
  FeaturesList_newSample = NULL,
  
  ## Plot features data
  sample_name_newSample = NULL,
  ms_features_newSample_toPlot_ConvertTime = NULL,
  
  peaks_MSDIAL_mono_iso_newSampleALigned = NULL,
  raw_Data_xcms_newSample = new("OnDiskMSnExp"),
  pheno_Data_newSample = data.frame(Filename = NULL, Class = NULL),
  pheno_Data_newSample_with_ref = NULL,
  raw_Data_xcms_newSample_XCMSnExp = new("XCMSnExp"),
  align_Data_xcms_newSapmle_XCMSnExp = new("XCMSnExp"),
  center_sample_newSample = 1,
  ms_features_MSDIAL_list_newSample = list(),
  sample_name = NULL,
  res_MatrixNewSample_normalized_toSave = NULL,
  res_MatrixNewSample_normalized_toPlot = NULL,
  ms_features_MSDIAL_newSample_toPlot_ConvertTime = NULL,
  res_MatrixNewSampleViewer_ConvertTime = NULL,
  Second = TRUE,
  SecondMatch = TRUE,
  
  uploadFeaturesBool = FALSE,
  
  export_param_path = NULL,
  output_export_param_path  = NULL,
  
  sample_ToPrint = NULL,
  n_nrom = NULL,
  
  res_Matrix_toPlotZoomed = NULL,
  
  matchedTable_newSample = NULL,

  kernelDensity_params_log = NULL

)

## reactive values for match et normalization of new samples
RvarsMatchNewsample <- reactiveValues(
  res_match_ref = NULL,
  res_MatrixNewSample = NULL,
  matchedTable_newSample = NULL,
  res_MatrixNewSampleViewer_ConvertTime = NULL,
  SecondMatch = TRUE,
  res_Matrix_toPlotZoomed = NULL,
  idx_Duplicates_ref = NULL,
  
  
)

## reactive values for  normalization of new samples
RvarsNormalizeNewsample <- reactiveValues(
  matrix_abondance = NULL,
  iset.normalizer.selected = NULL,
  matrix_abondance_Normalize = NULL,
  res_MatrixNewSample_normalized_toSave = NULL,
  res_MatrixNewSample_normalized_toPlot = NULL,
  sample_ToPrint = NULL,
  n_nrom = NULL,
  
  NoSampleNormalize = FALSE
)
