import os


def convert_to_mzML(input_directory,output_directory):
  param_covert = open("lib/NewReferenceMap/parameters/convert_raw_data_to_mzML_centroid.txt", 'r')
  quote ="\""
  fileContent = param_covert.readlines()
  # Fix: Use os.path.join for proper path handling across Windows versions
  msconvert_path = os.path.join(os.getcwd(), "lib", "MSconverter", "pwiz_bin_windows", "msconvert.exe")
  fileContent[0] = fileContent[0].replace("directory_msconverter.exe",quote+msconvert_path+quote)
  fileContent[0] = fileContent[0].replace("input_directory",quote+input_directory+"/*"+quote)
  fileContent[0] = fileContent[0].replace("output_directory",quote+output_directory+quote)
  with open("lib/NewReferenceMap/cmd/convert_raw_data_to_mzML_centroid.bat", 'w') as temp_file:
    for item in fileContent:
      temp_file.write("%s" % item)

  param_covert.close()
