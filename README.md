# MSPANDA-1.1.0
MS-PANDA is an untargeted omics data analysis tool.
It makes it possible to build a set of reference peptides or metabolites,
detected by CE/MS or LC/MS, from the analysis samples of a given biological liquid (plasma, urine, etc.).
This reference set is then used to match and normalize peptides or metabolites from a new sample.
It makes it possible to compare protein expression between different conditions,
to look for possible biomarkers associated with a pathology, a condition, a treatment
 
## The MS-PANDA tool consists of two parts:
1. New reference map: allows the development of a new peptide or metabolite reference map of a given biological liquid.
This reference map is then used to identify a set of intensity-stable particles.
2. Analysis new sample: a second part that allows to detect, match and normalize the peptides or metabolites of a new sample on the reference map.

## How to launch MSPANDA-1.1.0
### Prerequisites:
1. Download and install R and RStudio Desktop.
2. Download MSPANDA-1.1.0 app from the GitHub page.
3. Download the following applications:
	MSDIAL ver.4.80 Windows: https://zenodo.org/records/12540725,
	dotnet-sdk-6.0.301-win-x64.exe: https://dotnet.microsoft.com/en-us/download/dotnet/6.0.
4. Change Your Computer Locale to: United States (Etat-unis)

### Launch the MSPANDA application:
1. Install Microsoft dotnet-sdk-6.0.301-win-x64.exe.
2. Unzip the downloaded MSPANDA-1.1.0 application.
3. Unzip the MSDIAL ver.4.80 Windows application, then create a folder (MSDIAL) in MSPANDA-1.1.0 lib and copy in "MSDIAL ver.4.80 Windows".
4. Launch MSPANDA-1.1.0.Rproj: MSPANDA-1.1.0 MSPANDA-1.1.0.Rproj.

## Windows 11 Compatibility
This version includes comprehensive fixes for Windows 11 compatibility issues that caused crashes after migration from Windows 10.

Key improvements include:
- **Fixed path handling** for Windows 11's enhanced security model
- **Improved Python interpreter** initialization with absolute paths
- **Enhanced batch file execution** compatibility via cmd.exe
- **Fixed CE-time correction dialog** crashes with multi-layer fallback system
- **Improved PowerShell script** error handling with COM object fallback
- **Enhanced folder selection** dialogs for Windows 11 security policies

**Important**: The CE-time correction module now works reliably under Windows 11 with automatic fallback mechanisms.

For detailed information about the Windows 11 fixes, see [WINDOWS11_FIX.md](WINDOWS11_FIX.md).

