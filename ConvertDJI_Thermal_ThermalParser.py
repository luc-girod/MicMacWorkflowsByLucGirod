#Copy thermal.py in image folder, then cd to it before launching scipt
# thermal.py from https://github.com/SanNianYiSi/thermal_parser
# Parameters:
do_JPG = False
do_TIFDIRECT=False
do_TIFcentiK=True
# Needed for JPG
Min_temp=-1
Max_temp=5
# Acquisition parameters:object_distance: float = 5.0,
object_distance = 25.0
relative_humidity = 90.0
emissivity = 1.0
reflected_apparent_temperature = 3.0

import numpy as np
from thermal import Thermal
from PIL import Image
import os
from matplotlib import cm

# Adjust path!!!!
thermal = Thermal(
    dirp_filename='/home/lucg_wsl/git/thermal_parser/plugins/dji_thermal_sdk_v1.3/linux/release_x64/libdirp.so',
    dirp_sub_filename='/home/lucg_wsl/git/thermal_parser/plugins/dji_thermal_sdk_v1.3/linux/release_x64/libv_dirp.so',
    iirp_filename='/home/lucg_wsl/git/thermal_parser/plugins/dji_thermal_sdk_v1.3/linux/release_x64/libv_iirp.so',
    exif_filename=None,
    dtype=np.float32,
)




# directory name
dirname = os.getcwd()

if do_TIFDIRECT:
    os.mkdir('tif')
    print('Created tif folder')

if do_TIFcentiK:
    os.mkdir('TIFcentiK')
    print('Created TIFcentiK folder')

if do_JPG:
    os.mkdir('jpg')
    print('Created jpg folder')
    colmap = cm.get_cmap('magma', 256)
    np.savetxt('cmap.csv', (colmap.colors[...,0:3]*255).astype(np.uint8), fmt='%d', delimiter=',')
    lut = np.loadtxt('cmap.csv', dtype=np.uint8, delimiter=',')

# extensions of input files
ext = ('JPG')
MeanValues=[]
# scanning the directory to get required files
for files in os.scandir(dirname):
    if files.path.endswith(ext):
        print(files)  # printing file name
        temperature = thermal.parse_dirp2(image_filename=dirname+'/'+files.name,
        object_distance = object_distance, relative_humidity = relative_humidity,
        emissivity = emissivity, reflected_apparent_temperature = reflected_apparent_temperature)
        # TIFF float export
        if do_TIFDIRECT:
            im = Image.fromarray(temperature, mode='F')
            im.save(dirname+'/tif/'+files.name+'.tif', "TIFF")
            os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' ' + dirname + '/tif/' + files.name + '.tif')
        if do_TIFcentiK:
            im = Image.fromarray(((temperature+273.15)*100).astype('int16'), mode='I;16')
            im.save(dirname+'/TIFcentiK/'+files.name+'_centiK.tif', "TIFF")
            os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' ' + dirname + '/TIFcentiK/' + files.name + '_centiK.tif')
        if do_JPG:
            # JPG export
            tempCrop=temperature-Min_temp
            tempCrop[tempCrop>(Max_temp-Min_temp)]=Max_temp-Min_temp
            tempCrop[tempCrop<0]=0
            tempCrop=np.floor(tempCrop*250/(Max_temp-Min_temp)).astype('uint8') #250/(Max_temp-Min_temp) scales the data from 0 to 250, not 255 to avoid edge effects
            result = np.zeros((*tempCrop.shape,3), dtype=np.uint8)
            np.take(lut, tempCrop, axis=0, out=result)
            Image.fromarray(result).save(dirname+'/jpg/'+files.name, "JPEG")
            os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' -exif ' + dirname + '/jpg/' + files.name)
        
        MeanValues.append(temperature.mean())

print(MeanValues)
