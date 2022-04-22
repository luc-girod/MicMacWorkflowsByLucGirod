# -*- coding: utf-8 -*-
"""
Created on Thu Jan 20 14:19:15 2022

@author: lucg
"""
# importing the module
import os
from tifffile import imsave
from thermal_base import ThermalImage

# directory name
dirname = os.getcwd()
os.mkdir('tif')
# extensions
ext = ('JPG')
MeanValues=[]
# scanning the directory to get required files
for files in os.scandir(dirname):
    if files.path.endswith(ext):
        print(files)  # printing file name
        image = ThermalImage(image_path=dirname+'\\'+files.name, camera_manufacturer="dji")
        raw_sensor_np = image.raw_sensor_np#.astype(np.float16)
        
        imsave(dirname+'\\tif\\'+files.name+'.tif', raw_sensor_np)
        MeanValues.append(image.thermal_np.mean())
        print(image.thermal_np.mean())

