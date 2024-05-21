#Copy thermal.py in image folder, then cd to it before launching scipt
# thermal.py from https://github.com/SanNianYiSi/thermal_parser

import argparse
import numpy as np
from thermal import Thermal
from PIL import Image
import os
from matplotlib import cm


def _argparser():
    parser = argparse.ArgumentParser()
    parser.add_argument('--do_TIFcentiK', default=True, help='(True(def)/False) Convert to int16 TIFF files in centi Kelvin')
    parser.add_argument('--do_JPG', default=False, help='(True/False(def)) Convert to JPG images with min/max colour (requires --MinT and --MaxT)')
    parser.add_argument('--do_TIFDIRECT', default=False, help='(True/False(def)) Convert to float TIFF files')
    parser.add_argument('--MinT', default=0, help='MinT for colour scale if using JPG mode')
    parser.add_argument('--MaxT', default=20, help='MaxT for colour scale if using JPG mode')
    parser.add_argument('--object_distance', type=float, default=25.0, help='Distance to object (default 25.0, which is the max possible, and valid for >25m)')
    parser.add_argument('--relative_humidity', type=float, default=90.0, help='Relative humidity (default=90.0)')
    parser.add_argument('--emissivity', type=float, default=1.0,  help='Emissivity of target (default=1.0)')
    parser.add_argument('--reflected_apparent_temperature', type=float, default=0.0, help='Ambient temperature (default=0.0)')    
    parser.add_argument('--Path_DJIThermalSDK', default='/home/lucg_wsl/git/thermal_parser/plugins/dji_thermal_sdk_v1.3/linux/release_x64/', help='Path to DJIThermalSDK')
    return parser

def main():
    print('\n-----------------------------------------------------------------------------------------------------------------\n',
    'Script to turn all DJI H20T or M2EA thermal images in the active folder into useable files in a format of choice\n',
    'Luc Girod, 2024, using thermal.py from https://github.com/SanNianYiSi/thermal_parser',
    '\n-----------------------------------------------------------------------------------------------------------------\n')
    parser = _argparser()
    args = parser.parse_args()
    
    # Fix Acquisition parameters
    if(args.object_distance > 25.0):args.object_distance = 25.0
    MinT=args.MinT
    MaxT=args.MaxT
    
    # Adjust path!!!!
    thermal = Thermal(
        dirp_filename=args.Path_DJIThermalSDK + 'libdirp.so',
        dirp_sub_filename=args.Path_DJIThermalSDK + 'libv_dirp.so',
        iirp_filename=args.Path_DJIThermalSDK + 'libv_iirp.so',
        exif_filename=None,
        dtype=np.float32,
    )
    
    # directory name
    dirname = os.getcwd()
    
    if args.do_TIFDIRECT:
        os.mkdir('tif')
        print('Created tif folder')
    
    if args.do_TIFcentiK:
        os.mkdir('TIFcentiK')
        print('Created TIFcentiK folder')
    
    if args.do_JPG:
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
            object_distance = args.object_distance, relative_humidity = args.relative_humidity,
            emissivity = args.emissivity, reflected_apparent_temperature = args.reflected_apparent_temperature)
            # TIFF float export
            if args.do_TIFDIRECT:
                im = Image.fromarray(temperature, mode='F')
                im.save(dirname+'/tif/'+files.name+'.tif', "TIFF")
                os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' ' + dirname + '/tif/' + files.name + '.tif')
            if args.do_TIFcentiK:
                im = Image.fromarray(((temperature+273.15)*100).astype('int16'), mode='I;16')
                im.save(dirname+'/TIFcentiK/'+files.name+'_centiK.tif', "TIFF")
                os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' ' + dirname + '/TIFcentiK/' + files.name + '_centiK.tif')
            if args.do_JPG:
                # JPG export
                tempCrop=temperature-MinT
                tempCrop[tempCrop>(MaxT-MinT)]=MaxT-MinT
                tempCrop[tempCrop<0]=0
                tempCrop=np.floor(tempCrop*250/(MaxT-MinT)).astype('uint8') #250/(MaxT-MinT) scales the data from 0 to 250, not 255 to avoid edge effects
                result = np.zeros((*tempCrop.shape,3), dtype=np.uint8)
                np.take(lut, tempCrop, axis=0, out=result)
                Image.fromarray(result).save(dirname+'/jpg/'+files.name, "JPEG")
                os.system('exiftool -m -overwrite_original -tagsfromfile ' + dirname + '/'+files.name + ' -exif ' + dirname + '/jpg/' + files.name)
    
            MeanValues.append(temperature.mean())
    
    print(MeanValues)

if __name__ == "__main__":
    main()
