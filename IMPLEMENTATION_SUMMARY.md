# Summary: Dynamic File Input for Step 6 - Grouping & Map Generation

## Overview

Successfully implemented a dynamic file input system that allows users to upload additional peak data files (CSV/XLSX) and combine them with existing data during Step 6 (Grouping and Reference Map Generation).

## Changes Made

### 1. UI Modifications (`ui/newReferenceMap.ui/GenerateMapRef.Ui_NewRefMap.R`)

**Added:**
- Optional "Additional data upload" section with checkbox to enable/disable
- Dynamic file input fields (CSV/XLSX support)
- "Add more files" button to add multiple file inputs
- "Download CSV Template" button for user convenience
- Information box showing required columns
- Visual styling to highlight the additional data section

**Location:** Lines 46-111 in `GenerateMapRef.Ui_NewRefMap.R`

### 2. Server Logic (`server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R`)

**Added:**

#### a) Dynamic File Input Management (Lines 10-56)
- `numAdditionalFiles` reactive value to track number of file inputs
- `renderUI` for dynamic file input generation
- "Add more files" and "Remove file" button handlers

#### b) Template Download Handler (Lines 15-29)
- `downloadTemplate_NewRefMap` - allows users to download a CSV template
- Includes date in filename for tracking

#### c) File Reading and Combining (Lines 63-124)
- `readAdditionalFile()` - reads CSV or XLSX files
- `combineAdditionalData()` - reactive function that combines all uploaded files
- Error handling with notifications

#### d) Data Integration in Grouping Process (Lines 209-270)
- Validates uploaded data has required columns
- Standardizes column structure
- Fills missing optional columns with defaults
- Merges with existing peak data before grouping
- Shows success/warning notifications

### 3. New Library (`lib/NewReferenceMap/R_files/AdditionalDataMerge.lib.R`)

**Created utility functions:**

1. `validateAdditionalData()` - Validates data structure and required columns
2. `standardizeAdditionalData()` - Standardizes columns and fills defaults
3. `mergeAdditionalData()` - Merges additional data with existing data
4. `readAndCombineFiles()` - Reads and combines multiple files
5. `generateDataTemplate()` - Generates empty template data frame

**Total lines:** ~250 lines of well-documented code

### 4. Documentation

#### a) User Guide (`docs/ADDITIONAL_DATA_UPLOAD_GUIDE.md`)
Comprehensive French-language guide including:
- Feature overview and activation
- Required/optional columns explanation
- CSV/Excel examples
- Data combination process explanation
- Use cases and best practices
- Troubleshooting section

#### b) CSV Template (`docs/additional_data_template.csv`)
- Ready-to-use example with 5 sample rows
- All columns properly formatted
- Realistic sample data

#### c) Implementation Summary (this file)

## Technical Details

### Required Columns
- `M+H` (numeric) - Peak mass in Daltons
- `rt` (numeric) - Retention/CE-time in seconds
- `Area` (numeric) - Peak area
- `Height` (numeric) - Peak height/intensity
- `sample` (character) - Sample name

### Optional Columns (Auto-generated if missing)
- `M+H.min`, `M+H.max` - Mass range (defaults to M+H)
- `rtmin`, `rtmax` - Time range (defaults to rt)
- `SN` - Signal-to-noise ratio (defaults to 100)
- `iso.mass`, `iso.mass.link` - Isotopic pattern info (defaults to empty)
- `mz_PeaksIsotopics_Group`, `rt_PeaksIsotopics_Group`, `Height_PeaksIsotopics_Group` - Isotopic grouping info
- `Adduct` - Adduct type (defaults to "M+H")

### Data Flow

```
1. User uploads files (CSV/XLSX) →
2. Files are read and validated →
3. Data is standardized (columns added/reordered) →
4. Combined with existing CE-time corrected data →
5. Merged data used for grouping →
6. Reference map generated with combined data
```

### Integration Points

The additional data is integrated at **line 207-270** in `GenerateMapRef.Server_NewRefMap.R`, specifically before the grouping process begins. This ensures that:

1. Additional data goes through the same grouping algorithms
2. Features from additional data can be matched with existing features
3. The final reference map includes all combined data

## File Structure

```
MSpandas/
├── ui/newReferenceMap.ui/
│   └── GenerateMapRef.Ui_NewRefMap.R          [MODIFIED]
├── server/newReferenceMap.server/
│   └── GenerateMapRef.Server_NewRefMap.R      [MODIFIED]
├── lib/NewReferenceMap/R_files/
│   └── AdditionalDataMerge.lib.R              [NEW]
├── docs/
│   ├── ADDITIONAL_DATA_UPLOAD_GUIDE.md        [NEW]
│   └── additional_data_template.csv           [NEW]
└── IMPLEMENTATION_SUMMARY.md                  [NEW]
```

## User Experience Flow

1. Navigate to Step 6 "Generate the reference map"
2. Check "Enable additional data upload"
3. Click "Download CSV Template" (optional)
4. Click "Browse" to select first file
5. Click "Add more files" for additional files (optional)
6. Configure grouping parameters as usual
7. Click "Start grouping"
8. System validates, standardizes, and merges data
9. Success notification shows number of additional peaks merged
10. Grouping proceeds with combined data
11. Reference map includes all data

## Error Handling

The implementation includes comprehensive error handling:

- File reading errors with user-friendly notifications
- Missing column validation with clear messages
- Data type validation for numeric columns
- File format validation (CSV/XLSX only)
- Graceful fallback if template file is missing

## Benefits

1. **Flexibility**: Users can add data from external sources
2. **Reproducibility**: Template ensures consistent data format
3. **User-friendly**: Dynamic inputs allow any number of files
4. **Robust**: Comprehensive validation and error handling
5. **Documented**: Extensive user guide in French
6. **Non-breaking**: Optional feature, doesn't affect existing workflow

## Testing Recommendations

1. Test with template CSV file
2. Test with Excel files (.xlsx, .xls)
3. Test with missing optional columns
4. Test with invalid data (missing required columns)
5. Test with multiple files
6. Test the "Add more files" functionality
7. Test removal of files
8. Verify combined data appears in reference map
9. Test grouping with combined data
10. Verify download template button works

## Future Enhancements (Optional)

1. Add preview of uploaded data before merging
2. Add column mapping UI for non-standard column names
3. Add data filtering options (e.g., by sample, mass range)
4. Add import from database functionality
5. Add export of combined data before grouping
6. Add validation summary statistics

## Version Information

- **Implementation Date**: 2025-11-06
- **R Version Requirement**: >= 4.1.3 (existing requirement)
- **New Dependencies**: None (uses existing packages)
- **Language**: UI labels in French, code comments in English

## Commit Message Suggestion

```
feat: Add dynamic file input for additional data in Step 6 grouping

- Add optional file upload section in Step 6 UI
- Support CSV and XLSX formats
- Dynamic file inputs with add/remove functionality
- Comprehensive data validation and standardization
- Template download for user convenience
- Merge additional data with existing peaks before grouping
- Extensive documentation in French
- Non-breaking change, fully optional feature

Closes #[issue-number] if applicable
```

## Author

Implementation by Claude AI Assistant
Date: November 6, 2025
