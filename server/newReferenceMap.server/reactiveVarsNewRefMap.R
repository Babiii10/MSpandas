## reactive values

initReactiveVarsNewRefMap <- function() {
  reactiveVars <- new.env(parent = emptyenv())
  
  ## reactive values for peak detection
  reactiveVars$PeakDetection <- reactiveValues(
    directory_rawData = getwd(),
    paramMsdial_ref_path = NULL,
    Project_NameNewRefMap = NULL,
    directory_rawDataOutput_mzML_files_NewRefMapp = NULL,
    peaks_MSDIAL_mono_iso_NewRefMap = NULL,
    sample_name_NewRefMap = NULL,
    peaks_mono_iso_NewRefMap_toPlot_ConvertTime = NULL,
    Second = TRUE
    
  )
  
  ## reactive values for correction time
  reactiveVars$CorrectionTime <- reactiveValues(
    Second_Cutting = TRUE,
    samplesCuttingTable = NULL,
    sample_cutting_viewer_ConvertTime = NULL,
    
    peaks_mono_iso_sample_selectedCutting_toUse = NULL,
    
    ## reference sample option 1 (of choice)
    ref_Choose_sampleName = NULL,
    ref_Choose_samplePeaks = NULL,
    
    ## reference sample option 2  median
    Ref_Mdian_sampleName = NULL,
    Ref_Mdian_samplePeaks = NULL,
    
    ## Reference sample
    ref_sample_sampleName = NULL,
    ref_sample_samplePeaks = NULL,
    ref_sample_sample_mzMLfile = NULL,
    
    ## Sample Offset
    peaks_mono_iso_shift_plot = NULL,
    peaks_mono_iso_shift_forReset = NULL,
    SelectSampleOffset_Selected = NULL,
    
    ### correction with xcms
    rawData_mzML_path = NULL,
    pheno_Data_mzML = NULL,
    Filenames = NULL,
    Class = NULL,
    ImportClass = FALSE,
    
    dataObiwarp_Aligned = NULL,
    peakListBefore = NULL,
    peakListAligned = NULL,
    
    
    Data_Plot.before = NULL,
    Data_Plot.after = NULL,
    
    Data_Plot.after_xcms = NULL,
    Data_Plot.after_xcms_to_filter = NULL,
    
    samples_names_to_align_withKernDensity = character(0),
    
    ### Correction Kernel Density
    peakListAligned_KernelDensity = NULL,
    modelKernelDensity = NULL,
    Data_Plot.after_KernelDensity = NULL,
    kernelDensity_params_log = NULL
    
    
  )
  
  ## reactive values for correction time
  reactiveVars$Grouping <- reactiveValues(
    RefereanceMap = NULL,
    MatrixAbundance = NULL,
    
    RefereanceMap_selected = NULL,
    MatrixAbundance_selected = NULL,
    
    FeaturesListGroupingBetweenSamples = NULL,
    FeaturesList = NULL
    
  )
  
  ## reactive values for correction time
  reactiveVars$InternalStandard <- reactiveValues(
    OjectNormalizers = NULL,
    names_normalizers = NULL,
    map_ref_ToSave = NULL,
    MatrixAbundance_Before = NULL,
    MatrixAbundance_After = NULL,
    normalizers_ref = NULL,
    peaksList_run_ref = NULL,
    rt_ref = NULL,
    Output_NewRefMaps = NULL
    
    
  )
  
  
  return(reactiveVars)
}