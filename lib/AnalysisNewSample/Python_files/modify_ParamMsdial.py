import os
import fnmatch as fnmatch

def MsdialParam(input_param,
output_param,
MS1_type,
MS2_type,
ion, 
rt_begin, 
rt_end, 
mz_range_begin, 
mz_range_end, 
mz_tolerance_centroid_MS1, 
mz_tolerance_centroid_MS2,
maxCharge, 
number_threads, 
min_Peakwidth, 
min_PeakHeight, 
mass_slice_width, 
Adduct_list):
  paramMsdial = open(input_param, 'r')
  # if(not paramMsdial.closed):
  #   print(paramMsdial.name)
  fileContent = paramMsdial.readlines()
  fileContent[1] = fileContent[1].replace("MS1_type",MS1_type)
  fileContent[2] = fileContent[2].replace("MS2_type",MS2_type)
  fileContent[3] = fileContent[3].replace("ion", ion)
  fileContent[7] = fileContent[7].replace("rt_begin",rt_begin)
  fileContent[8] = fileContent[8].replace("rt_end",rt_end)
  fileContent[9] = fileContent[9].replace("mz_range_begin",mz_range_begin)
  fileContent[10] = fileContent[10].replace("mz_range_end",mz_range_end)
  fileContent[13] = fileContent[13].replace("mz_tolerance_centroid_MS1",mz_tolerance_centroid_MS1)
  fileContent[14] = fileContent[14].replace("mz_tolerance_centroid_MS2",mz_tolerance_centroid_MS2)
  fileContent[17] = fileContent[17].replace("maxCharge",maxCharge)
  fileContent[20] = fileContent[20].replace("number_threads",number_threads)
  fileContent[25] = fileContent[25].replace("min_Peakwidth",min_Peakwidth)
  fileContent[26] = fileContent[26].replace("min_PeakHeight",min_PeakHeight)
  fileContent[27] = fileContent[27].replace("mass_slice_width",mass_slice_width)
  # fileContent[33] = fileContent[33].replace("[M+H]+,[M+Na]+,[M+K]+", ", ".join(Adduct_list))
  fileContent[33] = fileContent[33].replace("[M+H]+", ",".join(Adduct_list))
  #fileContent[33] = fileContent[33].replace(", [",",[")
  with open(output_param, 'w') as temp_file:
    for item in fileContent:
      temp_file.write("%s" % item)
  #file = open('output_param', 'r')
  #print(file.read())
  #file.close() 
  paramMsdial.close()  

  
def findPeaksMsdial(input_files, output_files, output_export_param):
  peaksPicking = open("lib/AnalysisNewSample/Parameters/RunMsdialPeakPicking.txt", 'r')
  # if(not paramMsdial.closed):
  #   print(paramMsdial.name)
  quote ="\""
  fileContent = peaksPicking.readlines()
  # Fix: Use os.path.join for proper path handling across Windows versions
  msdial_path = os.path.join(os.getcwd(), "lib", "MSDIAL", "MSDIAL ver.4.80 Windows", "MsdialConsoleApp.exe")
  fileContent[0] = fileContent[0].replace("directory_MSDIAL.exe",quote+msdial_path+quote)
  fileContent[0] = fileContent[0].replace("inputfiles",quote+input_files+quote)
  fileContent[0] = fileContent[0].replace("outputfiles",quote+output_files+quote)
  fileContent[0] = fileContent[0].replace("param",quote+output_export_param+"/peakPicking_Parameters.txt"+quote)
  # Fix: Write with proper encoding and newline for Windows 11 compatibility
  with open("lib/AnalysisNewSample/cmd/RunMsdialPeakPicking.bat", 'w', encoding='cp1252', newline='\r\n') as temp_file:
    for item in fileContent:
      temp_file.write("%s" % item)

  peaksPicking.close()
  
  
  
  
def readDefaultParam(defaultParam_path):
   defautlParam_file = open(defaultParam_path, 'r')
   fileContent = defautlParam_file.readlines()
   
   rt_begin                  = fileContent[3].split(":")[1].replace("\n","")
   rt_end                    = fileContent[4].split(":")[1].replace("\n","")
   mz_range_begin            = fileContent[5].split(":")[1].replace("\n","")
   mz_range_end              = fileContent[6].split(":")[1].replace("\n","")
   mz_tolerance_centroid_MS1 = fileContent[9].split(":")[1].replace("\n","")
   mz_tolerance_centroid_MS2 = fileContent[10].split(":")[1].replace("\n","")
   maxCharge                 = fileContent[11].split(":")[1].replace("\n","")
   min_Peakwidth             = fileContent[12].split(":")[1].replace("\n","")
   min_PeakHeight            = fileContent[13].split(":")[1].replace("\n","")
   mass_slice_width          = fileContent[14].split(":")[1].replace("\n","")
   min_PeaksMassif           = fileContent[15].split(":")[1].replace("\n","")
   Adduct_list               = fileContent[16].split(":")[1].replace("\n","")
   ion                       = fileContent[17].split(":")[1].replace("\n","")
   bw                        = fileContent[20].split(":")[1].replace("\n","")
   mass_tolerance            = fileContent[21].split(":")[1].replace("\n","")
   
   
   defaultParam = {"rt_begin":rt_begin,
   "rt_end":rt_end,
   "mz_range_begin":mz_range_begin,
   "mz_range_end":mz_range_end,
   "mz_tolerance_centroid_MS1":mz_tolerance_centroid_MS1,
   "mz_tolerance_centroid_MS2":mz_tolerance_centroid_MS2,
   "maxCharge":maxCharge,
   "min_Peakwidth":min_Peakwidth,
   "min_PeakHeight":min_PeakHeight,
   "mass_slice_width":mass_slice_width,
   "min_PeaksMassif":min_PeaksMassif,
   "Adduct_list":Adduct_list.split(","),
   "ion":ion,
   "bw":bw,
   "mass_tolerance":mass_tolerance}
   defautlParam_file.close()
   return(defaultParam)
  
  
   
   

############### fonction pour supprimer tous les fichier "ext" d'un repertor
def removeFiles(path_to_files, ext):
  number = 0
  for file in os.listdir(path_to_files):
    if fnmatch.fnmatch(file, '*'+str(ext)):
      file_remove = os.path.abspath(path_to_files) + '/' + file
      print("files detected :\n"+os.path.basename(file_remove))
      os.remove(file_remove)
      number = number + 1
      if(number>0):
        print("deleting files... :\n"+ os.path.basename(file_remove))
  if(number==0):
    print("There are no files" + ext)



