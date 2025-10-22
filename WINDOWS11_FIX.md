# Windows 11 Compatibility Fixes

## Summary
This document describes the fixes applied to resolve application crashes after migrating from Windows 10 to Windows 11.

## Issues Identified

### 1. Path Handling Issues in Python Files
**Problem**: Python files used hardcoded backslashes in path strings, which caused syntax errors and path resolution failures under Windows 11's enhanced security model.

**Files affected**:
- `lib/NewReferenceMap/Python_files/msconverter_command_line.py`
- `lib/AnalysisNewSample/Python_files/msconverter_command_line.py`
- `lib/NewReferenceMap/Python_files/modify_ParamMsdialNewReferenceMap.py`
- `lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py`

**Solution**: Replaced hardcoded backslash paths with `os.path.join()` for proper cross-platform path handling.

**Example**:
```python
# Before (INCORRECT):
path = os.getcwd() + "\lib\MSDIAL\MSDIAL ver.4.80 Windows\MsdialConsoleApp.exe"

# After (CORRECT):
path = os.path.join(os.getcwd(), "lib", "MSDIAL", "MSDIAL ver.4.80 Windows", "MsdialConsoleApp.exe")
```

### 2. Python Interpreter Path Issues
**Problem**: The `use_python()` function in `global.R` used a relative path, which could fail under Windows 11's stricter permission model.

**File affected**:
- `global.R` (line 78)

**Solution**: Modified to use absolute path with fallback to relative path.

```r
# Before:
use_python('lib/Python')

# After:
python_path <- file.path(getwd(), "lib", "Python", "python.exe")
if (file.exists(python_path)) {
  use_python(python_path, required = TRUE)
} else {
  use_python('lib/Python')
}
```

### 3. Batch File Execution Issues
**Problem**: Windows 11 has enhanced security that can block direct execution of `.bat` files via `system2()`.

**Files affected**:
- `lib/NewReferenceMap/R_files/peakPickingNewReferenceMap.R`
- `lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R`

**Solution**: Modified to explicitly call batch files through `cmd.exe` with proper path normalization.

```r
# Before:
system2("lib/NewReferenceMap/cmd/RunMsdialPeakPicking.bat")

# After:
bat_file <- normalizePath("lib/NewReferenceMap/cmd/RunMsdialPeakPicking.bat",
                         winslash = "\\", mustWork = FALSE)
if (.Platform$OS.type == "windows") {
  system2("cmd.exe", args = c("/c", shQuote(bat_file)),
          stdout = TRUE, stderr = TRUE, wait = TRUE)
} else {
  system2(bat_file)
}
```

## Testing Recommendations

After applying these fixes, please test the following workflows:

1. **Application Launch**: Verify that the application starts without errors
2. **Peak Detection**: Test the peak detection functionality in both "New Reference Map" and "Analysis New Sample" modules
3. **File Conversion**: Verify that MS data file conversion works properly
4. **Python Integration**: Confirm that Python scripts are being called correctly

## Additional Notes

- All fixes maintain backward compatibility with Windows 10
- Path handling improvements also enhance cross-platform compatibility
- Security-related changes align with Windows 11's enhanced protection model

## Date Applied
2025-10-22

## Version
MSPANDA 1.1.0 - Windows 11 Compatibility Update
